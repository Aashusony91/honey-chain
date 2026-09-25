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

from shared.schemas import AgentRequest, AgentResponse

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
    print(f"[Orchestrator] Received payload from Gateway: {payload}")
    
    # 1. Prepare data for the Fraud Engine (Agent 3)
    batch = payload.get("batch", {})
    
    # Extract coordinates from the string "lat,lon"
    gps = batch.get("gps_coordinates", "0.0,0.0").split(",")
    lat, lon = 0.0, 0.0
    if len(gps) == 2:
        try:
            lat = float(gps[0].strip())
            lon = float(gps[1].strip())
        except ValueError:
            pass

    fraud_payload = {
        "report_id": batch.get("batch_id"),
        "gps_latitude": lat,
        "gps_longitude": lon,
        "reported_yield_quintals": batch.get("harvest_weight_kg", 0) / 100.0, # rough conversion kg -> quintals
        "land_acres": 1.5, # Mock land area since it's not in the batch payload directly
        "crop_type": batch.get("flora_source", "Multiflora"),
        "baseline_mean": 0.25, # baseline yield per acre
        "baseline_std": 0.05,
    }

    req = AgentRequest(
        session_id=str(uuid.uuid4()),
        task_id=batch.get("batch_id", str(uuid.uuid4())),
        target_agent="domain_reasoning",
        payload=fraud_payload,
        metadata={"source": "orchestrator"}
    )

    # 2. Call Agent 3 (Fraud Engine)
    print(f"[Orchestrator] Calling Agent 3 at {AGENT_3_URL}...")
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(AGENT_3_URL, json=req.model_dump(), timeout=10.0)
            resp.raise_for_status()
            agent3_response = resp.json()
    except Exception as e:
        print(f"[Orchestrator] Failed to call Agent 3: {e}")
        raise HTTPException(status_code=502, detail="Failed to contact Fraud Engine")

    # 3. Parse Fraud Engine Result
    result_data = agent3_response.get("result", {})
    is_valid = result_data.get("is_valid", False)
    confidence = result_data.get("confidence_score", 0.0)
    flags = result_data.get("flagged_anomalies", [])

    status = "VERIFIED" if is_valid else "FLAGGED_FOR_REVIEW"

    print(f"[Orchestrator] Verification Complete. Status: {status}, Score: {confidence}")
    return VerificationResult(
        status=status,
        confidence=confidence,
        flags=flags
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
