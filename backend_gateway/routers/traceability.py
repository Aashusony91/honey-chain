import hashlib
import json
import math
import secrets
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import Base, engine, get_db
from ..traceability_models import BatchLink, HoneyBatch, HoneyPackage, QRScan, TraceabilityEvent
from ..traceability_schemas import (
    BatchCreateRequest,
    BatchTransformRequest,
    EventResponse,
    EventCreateRequest,
    PackageCreateRequest,
    QRScanRequest,
    TraceResponse,
)

Base.metadata.create_all(bind=engine)

router = APIRouter(prefix="/api", tags=["Traceability & QR"])


def utc_from_epoch(value: int) -> datetime:
    return datetime.fromtimestamp(value, tz=timezone.utc)


def as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def consumed_from_batch(db: Session, batch_id: str) -> float:
    child_total = db.query(BatchLink).filter(
        BatchLink.parent_batch_id == batch_id
    ).all()
    child_weight = sum(link.quantity_kg for link in child_total)

    package_total = db.query(HoneyPackage).filter(
        HoneyPackage.batch_id == batch_id
    ).all()
    package_weight = sum(pkg.net_weight_kg for pkg in package_total)

    return child_weight + package_weight


def remaining_quantity(db: Session, batch: HoneyBatch) -> float:
    return max(batch.weight_kg - consumed_from_batch(db, batch.id), 0.0)


def canonical_event(
    batch_id: str,
    package_code: str | None,
    event_type: str,
    actor_id: str | None,
    location: str | None,
    event_timestamp: datetime,
    quantity_kg: float | None,
    metadata: dict,
    previous_hash: str | None,
) -> str:
    body = {
        "batch_id": batch_id,
        "package_code": package_code,
        "event_type": event_type,
        "actor_id": actor_id,
        "location": location,
        "event_timestamp": as_utc(event_timestamp).isoformat(),
        "quantity_kg": quantity_kg,
        "metadata": metadata,
        "previous_hash": previous_hash,
    }
    return json.dumps(body, sort_keys=True, separators=(",", ":"))


def make_event_hash(**kwargs) -> str:
    return hashlib.sha256(canonical_event(**kwargs).encode("utf-8")).hexdigest()


def latest_event_hash(db: Session, batch_id: str) -> str | None:
    event = (
        db.query(TraceabilityEvent)
        .filter(TraceabilityEvent.batch_id == batch_id)
        .order_by(TraceabilityEvent.id.desc())
        .first()
    )
    return event.event_hash if event else None


def add_event(
    db: Session,
    *,
    batch_id: str,
    event_type: str,
    actor_id: str | None = None,
    location: str | None = None,
    event_timestamp: datetime | None = None,
    quantity_kg: float | None = None,
    metadata: dict | None = None,
    package_code: str | None = None,
) -> TraceabilityEvent:
    event_timestamp = event_timestamp or datetime.now(timezone.utc)
    metadata = metadata or {}
    previous_hash = latest_event_hash(db, batch_id)
    event_hash = make_event_hash(
        batch_id=batch_id,
        package_code=package_code,
        event_type=event_type,
        actor_id=actor_id,
        location=location,
        event_timestamp=event_timestamp,
        quantity_kg=quantity_kg,
        metadata=metadata,
        previous_hash=previous_hash,
    )
    event = TraceabilityEvent(
        batch_id=batch_id,
        package_code=package_code,
        event_type=event_type,
        actor_id=actor_id,
        location=location,
        event_timestamp=event_timestamp,
        quantity_kg=quantity_kg,
        metadata_json=json.dumps(metadata, sort_keys=True),
        previous_hash=previous_hash,
        event_hash=event_hash,
    )
    db.add(event)
    return event


def verify_event_chain(events: list[TraceabilityEvent]) -> tuple[bool, list[str]]:
    previous = None
    problems = []
    for event in events:
        metadata = json.loads(event.metadata_json or "{}")
        expected = make_event_hash(
            batch_id=event.batch_id,
            package_code=event.package_code,
            event_type=event.event_type,
            actor_id=event.actor_id,
            location=event.location,
            event_timestamp=event.event_timestamp,
            quantity_kg=event.quantity_kg,
            metadata=metadata,
            previous_hash=previous,
        )
        if event.previous_hash != previous:
            problems.append(f"PREVIOUS_HASH_MISMATCH:{event.id}")
        if event.event_hash != expected:
            problems.append(f"EVENT_HASH_MISMATCH:{event.id}")
        previous = event.event_hash
    return not problems, problems


@router.post("/batches")
def create_batch(payload: BatchCreateRequest, db: Session = Depends(get_db)):
    batch_id = payload.batch_id or f"HC-BATCH-{secrets.token_hex(5).upper()}"
    if db.query(HoneyBatch).filter(HoneyBatch.id == batch_id).first():
        raise HTTPException(409, "Batch already exists.")

    if payload.parent_batch_id:
        parent = db.get(HoneyBatch, payload.parent_batch_id)
        if not parent:
            raise HTTPException(404, "Parent batch not found.")
        if payload.weight_kg > remaining_quantity(db, parent):
            raise HTTPException(400, "Child batch weight exceeds the parent's remaining quantity.")

    batch = HoneyBatch(
        id=batch_id,
        farmer_id=payload.farmer_id,
        hive_id=payload.hive_id,
        parent_batch_id=payload.parent_batch_id,
        weight_kg=payload.weight_kg,
        flora_source=payload.flora_source,
        gps_location=payload.gps_location,
        harvest_timestamp=utc_from_epoch(payload.harvest_timestamp),
        current_stage="HARVESTED",
    )
    db.add(batch)
    add_event(
        db,
        batch_id=batch_id,
        event_type="HARVESTED",
        actor_id=payload.farmer_id,
        location=payload.gps_location,
        event_timestamp=batch.harvest_timestamp,
        quantity_kg=payload.weight_kg,
        metadata={"flora_source": payload.flora_source, "hive_id": payload.hive_id},
    )
    db.commit()

    # ── Blockchain anchor (non-blocking) ──────────────────────────
    # Anchors the harvest to the smart contract after saving to DB.
    # API returns 200 even if blockchain is unreachable.
    blockchain_tx_hash = None
    try:
        from ..blockchain_helper import register_harvest_on_chain
        blockchain_tx_hash = register_harvest_on_chain(
            weight_kg=payload.weight_kg,
            ipfs_hash=batch_id,           # batch_id used as on-chain reference
        )
        if blockchain_tx_hash:
            print(f"[blockchain] ✅ Anchored {batch_id} → tx: {blockchain_tx_hash}")
    except Exception as e:
        print(f"[blockchain] ⚠️ Skipped (non-critical): {e}")
    # ─────────────────────────────────────────────────────────────

    return {
        "batch_id": batch_id,
        "stage": batch.current_stage,
        "message": "Batch created.",
        "blockchain_tx_hash": blockchain_tx_hash,   # returned to frontend
    }


@router.post("/batches/{batch_id}/events")
def add_batch_event(batch_id: str, payload: EventCreateRequest, db: Session = Depends(get_db)):
    if payload.batch_id != batch_id:
        raise HTTPException(400, "batch_id in path and body must match.")
    batch = db.get(HoneyBatch, batch_id)
    if not batch:
        raise HTTPException(404, "Batch not found.")

    event_time = utc_from_epoch(payload.event_timestamp)
    if event_time < as_utc(batch.harvest_timestamp):
        raise HTTPException(400, "Event cannot occur before harvest.")

    event = add_event(
        db,
        batch_id=batch_id,
        event_type=payload.event_type.upper(),
        actor_id=payload.actor_id,
        location=payload.location,
        event_timestamp=event_time,
        quantity_kg=payload.quantity_kg,
        metadata=payload.metadata,
        package_code=payload.package_code,
    )
    batch.current_stage = payload.event_type.upper()
    db.commit()
    db.refresh(event)
    return {"event_id": event.id, "event_hash": event.event_hash, "stage": batch.current_stage}


@router.post("/batches/{batch_id}/transform")
def transform_batch(batch_id: str, payload: BatchTransformRequest, db: Session = Depends(get_db)):
    parent = db.get(HoneyBatch, batch_id)
    if not parent:
        raise HTTPException(404, "Parent batch not found.")
    available = remaining_quantity(db, parent)
    if payload.weight_kg > available:
        raise HTTPException(
            400,
            f"Transformation quantity exceeds remaining parent quantity ({available:.3f} kg)."
        )

    child_id = payload.child_batch_id or f"HC-BATCH-{secrets.token_hex(5).upper()}"
    if db.get(HoneyBatch, child_id):
        raise HTTPException(409, "Child batch already exists.")

    child = HoneyBatch(
        id=child_id,
        farmer_id=payload.farmer_id,
        hive_id=payload.hive_id,
        parent_batch_id=batch_id,
        weight_kg=payload.weight_kg,
        flora_source=payload.flora_source,
        gps_location=payload.gps_location,
        harvest_timestamp=parent.harvest_timestamp,
        current_stage="PROCESSING",
    )
    db.add(child)
    db.add(BatchLink(
        parent_batch_id=batch_id,
        child_batch_id=child_id,
        quantity_kg=payload.weight_kg,
        relationship_type=payload.relationship_type.upper(),
    ))
    event_time = utc_from_epoch(payload.event_timestamp)
    add_event(
        db,
        batch_id=batch_id,
        event_type=payload.relationship_type.upper(),
        actor_id=payload.actor_id,
        location=payload.gps_location,
        event_timestamp=event_time,
        quantity_kg=payload.weight_kg,
        metadata={"child_batch_id": child_id},
    )
    add_event(
        db,
        batch_id=child_id,
        event_type="RECEIVED_FROM_PARENT",
        actor_id=payload.actor_id,
        location=payload.gps_location,
        event_timestamp=event_time,
        quantity_kg=payload.weight_kg,
        metadata={"parent_batch_id": batch_id},
    )
    db.commit()
    return {"parent_batch_id": batch_id, "child_batch_id": child_id, "quantity_kg": payload.weight_kg}


@router.post("/batches/merge")
def merge_batches(
    payload: dict,
    db: Session = Depends(get_db),
):
    parent_batch_ids = payload.get("parent_batch_ids", [])
    child_batch_id = payload.get("child_batch_id")
    weight_kg = payload.get("weight_kg")
    actor_id = payload.get("actor_id")
    event_timestamp = payload.get("event_timestamp")

    if not isinstance(parent_batch_ids, list) or len(parent_batch_ids) < 2:
        raise HTTPException(400, "parent_batch_ids must contain at least two batches.")
    if not isinstance(weight_kg, (int, float)) or weight_kg <= 0:
        raise HTTPException(400, "weight_kg must be greater than zero.")

    parents = []
    total_available = 0.0
    for parent_id in parent_batch_ids:
        parent = db.get(HoneyBatch, parent_id)
        if not parent:
            raise HTTPException(404, f"Parent batch not found: {parent_id}")
        parents.append(parent)
        total_available += remaining_quantity(db, parent)

    if weight_kg > total_available:
        raise HTTPException(
            400,
            f"Merge quantity exceeds total available parent quantity ({total_available:.3f} kg)."
        )

    child_id = child_batch_id or f"HC-BATCH-{secrets.token_hex(5).upper()}"
    if db.get(HoneyBatch, child_id):
        raise HTTPException(409, "Child batch already exists.")

    event_time = (
        utc_from_epoch(int(event_timestamp))
        if event_timestamp is not None
        else datetime.now(timezone.utc)
    )

    # Allocate the requested child quantity across parents in order.
    remaining = float(weight_kg)
    allocations = []
    for parent in parents:
        take = min(remaining, remaining_quantity(db, parent))
        if take > 0:
            allocations.append((parent, take))
            remaining -= take
        if remaining <= 1e-9:
            break

    if remaining > 1e-9:
        raise HTTPException(400, "Unable to allocate merge quantity from parents.")

    child = HoneyBatch(
        id=child_id,
        farmer_id=parents[0].farmer_id,
        hive_id=None,
        parent_batch_id=parents[0].id,
        weight_kg=float(weight_kg),
        flora_source="AGGREGATED",
        gps_location=None,
        harvest_timestamp=min(as_utc(p.harvest_timestamp) for p in parents),
        current_stage="PROCESSING",
    )
    db.add(child)

    for parent, quantity in allocations:
        db.add(BatchLink(
            parent_batch_id=parent.id,
            child_batch_id=child_id,
            quantity_kg=quantity,
            relationship_type="MERGE",
        ))
        add_event(
            db,
            batch_id=parent.id,
            event_type="MERGE",
            actor_id=actor_id,
            event_timestamp=event_time,
            quantity_kg=quantity,
            metadata={"child_batch_id": child_id, "relationship": "MERGE"},
        )

    add_event(
        db,
        batch_id=child_id,
        event_type="AGGREGATED",
        actor_id=actor_id,
        event_timestamp=event_time,
        quantity_kg=float(weight_kg),
        metadata={
            "parent_batch_ids": [p.id for p in parents],
            "allocations": {p.id: q for p, q in allocations},
        },
    )

    db.commit()
    return {
        "child_batch_id": child_id,
        "parent_batch_ids": parent_batch_ids,
        "quantity_kg": weight_kg,
        "relationship": "MERGE",
    }


@router.post("/packages")
def create_package(payload: PackageCreateRequest, db: Session = Depends(get_db)):
    batch = db.get(HoneyBatch, payload.batch_id)
    if not batch:
        raise HTTPException(404, "Batch not found.")
    available = remaining_quantity(db, batch)
    if payload.net_weight_kg > available:
        raise HTTPException(
            400,
            f"Package weight exceeds remaining batch quantity ({available:.3f} kg)."
        )

    code = payload.package_code or f"HC-PKG-{secrets.token_hex(6).upper()}"
    if db.query(HoneyPackage).filter(HoneyPackage.package_code == code).first():
        raise HTTPException(409, "Package code already exists.")

    package = HoneyPackage(
        package_code=code,
        batch_id=payload.batch_id,
        product_name=payload.product_name,
        net_weight_kg=payload.net_weight_kg,
        status="ACTIVE",
    )
    db.add(package)
    add_event(
        db,
        batch_id=batch.id,
        package_code=code,
        event_type="PACKAGED",
        actor_id="PACKAGING",
        location=None,
        event_timestamp=datetime.now(timezone.utc),
        quantity_kg=payload.net_weight_kg,
        metadata={"product_name": payload.product_name, "package_code": code},
    )
    batch.current_stage = "BOTTLED"
    db.commit()
    return {
        "package_code": code,
        "batch_id": batch.id,
        "qr_payload": f"/api/public/trace/{code}",
        "message": "Package created. Encode qr_payload into the bottle QR."
    }


@router.get("/public/trace/{package_code}", response_model=TraceResponse)
def public_trace(package_code: str, db: Session = Depends(get_db)):
    package = db.query(HoneyPackage).filter(HoneyPackage.package_code == package_code).first()
    if not package:
        raise HTTPException(404, "Package QR not found.")

    # Walk backwards through parent links so the consumer sees the full lineage.
    lineage = []
    seen = set()
    frontier = [package.batch_id]
    while frontier:
        current = frontier.pop(0)
        if current in seen:
            continue
        seen.add(current)
        batch = db.get(HoneyBatch, current)
        if not batch:
            continue
        lineage.append({
            "batch_id": batch.id,
            "parent_batch_id": batch.parent_batch_id,
            "farmer_id": batch.farmer_id,
            "weight_kg": batch.weight_kg,
            "flora_source": batch.flora_source,
            "gps_location": batch.gps_location,
            "harvest_timestamp": as_utc(batch.harvest_timestamp).isoformat(),
            "stage": batch.current_stage,
        })
        links = db.query(BatchLink).filter(
            BatchLink.child_batch_id == current
        ).all()
        frontier.extend(link.parent_batch_id for link in links)

    lineage_ids = [item["batch_id"] for item in lineage]
    events = (
        db.query(TraceabilityEvent)
        .filter(TraceabilityEvent.batch_id.in_(lineage_ids))
        .order_by(TraceabilityEvent.event_timestamp.asc(), TraceabilityEvent.id.asc())
        .all()
    )

    # Each batch has its own hash chain. Verify every chain independently.
    chain_ok = True
    problems = []
    for lineage_batch_id in lineage_ids:
        batch_events = [e for e in events if e.batch_id == lineage_batch_id]
        ok, batch_problems = verify_event_chain(batch_events)
        chain_ok = chain_ok and ok
        problems.extend(batch_problems)

    scans = (
        db.query(QRScan)
        .filter(QRScan.package_code == package_code)
        .order_by(QRScan.scanned_at.asc())
        .all()
    )

    return TraceResponse(
        verified=chain_ok and not problems,
        package_code=package.package_code,
        product_name=package.product_name,
        package_status=package.status,
        batch_id=package.batch_id,
        batch=lineage[0],
        journey=[
            EventResponse(
                id=e.id,
                event_type=e.event_type,
                actor_id=e.actor_id,
                location=e.location,
                event_timestamp=e.event_timestamp.isoformat(),
                quantity_kg=e.quantity_kg,
                metadata=json.loads(e.metadata_json or "{}"),
                previous_hash=e.previous_hash,
                event_hash=e.event_hash,
            )
            for e in events
        ],
        lineage=lineage,
        scans=[
            {
                "scanned_at": s.scanned_at.isoformat(),
                "latitude": s.latitude,
                "longitude": s.longitude,
                "anomaly_flag": s.anomaly_flag,
                "anomaly_reason": s.anomaly_reason,
            }
            for s in scans
        ],
        integrity={
            "hash_chain_verified": chain_ok,
            "problems": problems,
            "blockchain_status": "HASH_LINKED_AUDIT_LAYER; FABRIC_ANCHORING_NOT_CONNECTED",
        },
    )


@router.post("/packages/{package_code}/scan")
def record_qr_scan(package_code: str, payload: QRScanRequest, db: Session = Depends(get_db)):
    package = db.query(HoneyPackage).filter(HoneyPackage.package_code == package_code).first()
    if not package:
        raise HTTPException(404, "Package QR not found.")

    previous = (
        db.query(QRScan)
        .filter(QRScan.package_code == package_code)
        .order_by(QRScan.scanned_at.desc())
        .first()
    )

    anomaly_flag = None
    anomaly_reason = None

    # A scan-location change is not itself proof of counterfeiting.
    # Flag only an implausibly fast geographic jump when both scans have coordinates.
    if previous and payload.latitude is not None and payload.longitude is not None:
        if previous.latitude is not None and previous.longitude is not None:
            distance_m = haversine(
                previous.latitude, previous.longitude,
                payload.latitude, payload.longitude
            )
            elapsed_hours = max(
                (datetime.now(timezone.utc) - as_utc(previous.scanned_at)).total_seconds() / 3600,
                0.001,
            )
            speed_kmh = (distance_m / 1000) / elapsed_hours
            if speed_kmh > 900:
                anomaly_flag = "SUSPICIOUS_SCAN_MOVEMENT"
                anomaly_reason = (
                    f"Approximate scan movement implies {speed_kmh:.1f} km/h; "
                    "review supply-chain/location evidence."
                )

    scan = QRScan(
        package_code=package_code,
        latitude=payload.latitude,
        longitude=payload.longitude,
        device_id=payload.device_id,
        anomaly_flag=anomaly_flag,
        anomaly_reason=anomaly_reason,
    )
    db.add(scan)
    db.commit()
    db.refresh(scan)

    return {
        "scan_id": scan.id,
        "package_code": package_code,
        "anomaly": bool(anomaly_flag),
        "anomaly_flag": anomaly_flag,
        "anomaly_reason": anomaly_reason,
        "trace_url": f"/api/public/trace/{package_code}",
    }


@router.get("/packages/{package_code}/scan-history")
def scan_history(package_code: str, db: Session = Depends(get_db)):
    package = db.query(HoneyPackage).filter(HoneyPackage.package_code == package_code).first()
    if not package:
        raise HTTPException(404, "Package QR not found.")

    scans = (
        db.query(QRScan)
        .filter(QRScan.package_code == package_code)
        .order_by(QRScan.scanned_at.asc())
        .all()
    )
    return {
        "package_code": package_code,
        "scan_count": len(scans),
        "scans": [
            {
                "scanned_at": s.scanned_at.isoformat(),
                "latitude": s.latitude,
                "longitude": s.longitude,
                "anomaly_flag": s.anomaly_flag,
                "anomaly_reason": s.anomaly_reason,
            }
            for s in scans
        ],
    }


def haversine(lat1, lon1, lat2, lon2) -> float:
    radius = 6_371_000.0
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * radius * math.asin(math.sqrt(a))


