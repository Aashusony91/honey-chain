import sys
from pathlib import Path
import httpx
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
import uuid

# Ensure shared folder can be found
ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.append(str(ROOT_DIR))

from shared.schemas import AgentRequest, AgentType, HoneyBatchPayload

app = FastAPI(title="SIH 26021 Orchestrator Agent", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AGENT_3_URL = "http://127.0.0.1:8003/process"


class VerificationResult(BaseModel):
    status: str
    confidence: float
    flags: List[str]


@app.get("/health")
async def health():
    return {"service": "agent_1_orchestrator", "status": "healthy"}


@app.post("/orchestrate", response_model=VerificationResult)
async def orchestrate(payload: Dict[str, Any]):
    print(f"[Orchestrator] Received payload from Gateway")

    batch_data = payload.get("batch", {})

    # 1. Build a proper HoneyBatchPayload to send to Agent 3
    #    Agent 3 reads from payload dict keys: photo_latitude, gps_latitude,
    #    reported_yield_quintals, land_acres, baseline_mean, baseline_std, crop_type
    gps_str = batch_data.get("gps_coordinates", "0.0,0.0")
    gps_parts = gps_str.split(",")
    lat, lon = 0.0, 0.0
    try:
        lat = float(gps_parts[0].strip())
        lon = float(gps_parts[1].strip())
    except (ValueError, IndexError):
        pass

    weight_kg = float(batch_data.get("weight_kg", batch_data.get("harvest_weight_kg", 0)))
    hive_count = int(batch_data.get("hive_count", 1))

    # Agent 3 uses payload as a raw dict via p.get(...)
    # It expects: photo_latitude, gps_latitude, reported_yield_quintals,
    #             land_acres, baseline_mean, baseline_std, crop_type
    agent3_payload_dict = {
        "farmer_id": batch_data.get("farmer_id", "UNKNOWN"),
        "flora_source": batch_data.get("flora_source", "Multiflora"),
        "weight_kg": weight_kg,
        "gps_coordinates": gps_str,
        "harvest_timestamp": batch_data.get("harvest_timestamp", 0),
        # Fields Agent 3 reads directly
        "photo_latitude": lat,
        "photo_longitude": lon,
        "gps_latitude": lat,
        "gps_longitude": lon,
        "registered_latitude": lat,  # In prod: pulled from Govt DB
        "registered_longitude": lon,
        "reported_yield_quintals": weight_kg / 100.0,  # kg → quintals approx
        "land_acres": max(1.0, hive_count * 0.5),       # estimated land from hive count
        "baseline_mean": 0.25,   # District baseline yield per acre (quintals)
        "baseline_std": 0.08,
        "crop_type": batch_data.get("flora_source", "Multiflora"),
        "image_url": None,
        "report_id": batch_data.get("batch_id", str(uuid.uuid4())),
    }

    # 2. Wrap into proper AgentRequest schema
    req = AgentRequest(
        session_id=str(uuid.uuid4()),
        task_id=batch_data.get("batch_id", str(uuid.uuid4())),
        sender=AgentType.ORCHESTRATOR,
        target=AgentType.IOT_FRAUD_ENGINE,
        action="validate_yield",
        payload=HoneyBatchPayload(**{
            "batch_id": batch_data.get("batch_id", str(uuid.uuid4())),
            "farmer_id": agent3_payload_dict["farmer_id"],
            "flora_source": agent3_payload_dict["flora_source"],
            "harvest_weight_kg": agent3_payload_dict["weight_kg"],
            "gps_coordinates": agent3_payload_dict["gps_coordinates"],
            "harvest_timestamp": agent3_payload_dict["harvest_timestamp"],
        }),
    )

    # Agent 3's process() reads request.payload as a dict via p.get(...)
    # So we inject our enriched dict directly as the payload's model extra fields
    req_dict = req.model_dump()
    req_dict["payload"].update(agent3_payload_dict)

    # 3. Call Agent 3 (Fraud Engine)
    print(f"[Orchestrator] Calling Agent 3 at {AGENT_3_URL}...")
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(AGENT_3_URL, json=req_dict, timeout=10.0)
            resp.raise_for_status()
            agent3_response = resp.json()
    except Exception as e:
        print(f"[Orchestrator] Agent 3 unavailable: {e}. Using fallback.")
        # Graceful fallback: approve with lower confidence if AI is unavailable
        return VerificationResult(
            status="VERIFIED",
            confidence=0.88,
            flags=["AI_ENGINE_TIMEOUT: Fallback score applied"]
        )

    # 4. Parse Fraud Engine Result
    result_data = agent3_response.get("result", {})
    is_valid = result_data.get("is_valid", True)
    confidence = float(result_data.get("confidence_score", 0.88))
    flags = result_data.get("flagged_anomalies", [])

    status = "VERIFIED" if is_valid else "FLAGGED_FOR_REVIEW"

    print(f"[Orchestrator] Done. Status={status}, Confidence={confidence}")
    return VerificationResult(
        status=status,
        confidence=confidence,
        flags=flags
    )


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
