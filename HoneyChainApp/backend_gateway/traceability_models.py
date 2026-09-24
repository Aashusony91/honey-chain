from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Text
from .database import Base


def utcnow():
    return datetime.now(timezone.utc)


class HoneyBatch(Base):
    __tablename__ = "traceability_batches"

    id = Column(String(80), primary_key=True)
    farmer_id = Column(String(100), nullable=False, index=True)
    hive_id = Column(String(100), nullable=True)
    parent_batch_id = Column(String(80), nullable=True, index=True)
    weight_kg = Column(Float, nullable=False)
    flora_source = Column(String(200), nullable=True)
    gps_location = Column(String(100), nullable=True)
    harvest_timestamp = Column(DateTime, nullable=False)
    current_stage = Column(String(50), nullable=False, default="HARVESTED")
    created_at = Column(DateTime, nullable=False, default=utcnow)


class TraceabilityEvent(Base):
    __tablename__ = "traceability_events"

    id = Column(Integer, primary_key=True, index=True)
    batch_id = Column(String(80), ForeignKey("traceability_batches.id"), nullable=False, index=True)
    package_code = Column(String(120), nullable=True, index=True)
    event_type = Column(String(60), nullable=False, index=True)
    actor_id = Column(String(120), nullable=True)
    location = Column(String(200), nullable=True)
    event_timestamp = Column(DateTime, nullable=False)
    quantity_kg = Column(Float, nullable=True)
    metadata_json = Column(Text, nullable=False, default="{}")
    previous_hash = Column(String(64), nullable=True)
    event_hash = Column(String(64), nullable=False, unique=True, index=True)


class BatchLink(Base):
    __tablename__ = "traceability_batch_links"

    id = Column(Integer, primary_key=True, index=True)
    parent_batch_id = Column(String(80), ForeignKey("traceability_batches.id"), nullable=False, index=True)
    child_batch_id = Column(String(80), ForeignKey("traceability_batches.id"), nullable=False, index=True)
    quantity_kg = Column(Float, nullable=False)
    relationship_type = Column(String(30), nullable=False, default="SPLIT")


class HoneyPackage(Base):
    __tablename__ = "traceability_packages"

    id = Column(Integer, primary_key=True, index=True)
    package_code = Column(String(120), nullable=False, unique=True, index=True)
    batch_id = Column(String(80), ForeignKey("traceability_batches.id"), nullable=False, index=True)
    product_name = Column(String(200), nullable=False)
    net_weight_kg = Column(Float, nullable=False)
    status = Column(String(40), nullable=False, default="ACTIVE")
    created_at = Column(DateTime, nullable=False, default=utcnow)


class QRScan(Base):
    __tablename__ = "traceability_qr_scans"

    id = Column(Integer, primary_key=True, index=True)
    package_code = Column(String(120), ForeignKey("traceability_packages.package_code"), nullable=False, index=True)
    scanned_at = Column(DateTime, nullable=False, default=utcnow)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    device_id = Column(String(120), nullable=True)
    anomaly_flag = Column(String(80), nullable=True)
    anomaly_reason = Column(String(500), nullable=True)
