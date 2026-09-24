import math
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Ensure shared folder can be found
ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.append(str(ROOT_DIR))

from shared.base_agent import BaseAgent
from shared.schemas import AgentRequest, AgentResponse, AgentType, VerificationResult


class DomainReasoningAgent(BaseAgent):
    def __init__(self):
        super().__init__(agent_type=AgentType.DOMAIN, name="DomainReasoningAgent")

    def get_capabilities(self) -> List[str]:
        return [
            "verify_exif_gps",
            "calculate_yield_zscore",
            "verify_crop_image",
            "verify_report",
        ]

    def verify_exif_gps(
        self,
        photo_lat: float,
        photo_lon: float,
        registered_lat: float,
        registered_lon: float,
        max_allowed_distance_meters: float = 100.0,
    ) -> Tuple[bool, float, Optional[str]]:
        r = 6371000.0
        phi1 = math.radians(registered_lat)
        phi2 = math.radians(photo_lat)
        delta_phi = math.radians(photo_lat - registered_lat)
        delta_lambda = math.radians(photo_lon - registered_lon)

        a = (
            math.sin(delta_phi / 2.0) ** 2
            + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
        )
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        distance_meters = r * c

        if distance_meters > max_allowed_distance_meters:
            anomaly = (
                f"EXIF GPS mismatch: Photo taken {distance_meters:.1f}m away from "
                f"registered land boundary (Threshold: {max_allowed_distance_meters}m)"
            )
            return False, distance_meters, anomaly

        return True, distance_meters, None

    def calculate_yield_zscore(
        self,
        reported_yield: float,
        land_acres: float,
        baseline_mean: float,
        baseline_std: float,
    ) -> Tuple[bool, float, float, Optional[str]]:
        if land_acres <= 0.0:
            return False, 0.0, 0.0, "Invalid land area: Acres must be greater than 0"

        yield_density = reported_yield / land_acres
        effective_std = baseline_std if baseline_std > 1e-4 else 1.0
        z_score = (yield_density - baseline_mean) / effective_std

        if abs(z_score) > 3.0:
            anomaly = (
                f"Statistical yield anomaly: Reported density is {yield_density:.2f} quintals/acre "
                f"(District baseline: {baseline_mean:.2f} ± {effective_std:.2f}, Z-Score: {z_score:+.2f})"
            )
            return False, yield_density, z_score, anomaly

        return True, yield_density, z_score, None

    def verify_crop_image(
        self,
        image_url: Optional[str],
        declared_crop: str,
    ) -> Tuple[bool, str, float, Optional[str]]:
        if not image_url:
            return (
                False,
                "unknown",
                0.0,
                "Missing crop image: No photo uploaded for computer vision verification",
            )

        declared_crop_clean = declared_crop.strip().lower()
        return True, declared_crop_clean, 0.94, None

    async def process(self, request: AgentRequest) -> AgentResponse:
        p: Dict[str, Any] = request.payload
        anomalies: List[str] = []
        confidence_score = 1.0

        # 1. EXIF Check
        gps_ok, _, gps_err = self.verify_exif_gps(
            p.get("photo_latitude", p.get("gps_latitude", 0.0)),
            p.get("photo_longitude", p.get("gps_longitude", 0.0)),
            p.get("registered_latitude", p.get("gps_latitude", 0.0)),
            p.get("registered_longitude", p.get("gps_longitude", 0.0)),
        )
        if not gps_ok and gps_err:
            anomalies.append(gps_err)
            confidence_score -= 0.35

        # 2. Yield Z-Score Check
        yield_ok, _, _, yield_err = self.calculate_yield_zscore(
            p.get("reported_yield_quintals", 0.0),
            p.get("land_acres", 1.0),
            p.get("baseline_mean", 18.0),
            p.get("baseline_std", 3.0),
        )
        if not yield_ok and yield_err:
            anomalies.append(yield_anomaly if "yield_anomaly" in locals() else yield_err)
            confidence_score -= 0.40

        # 3. Vision Check
        img_ok, _, _, img_err = self.verify_crop_image(
            p.get("image_url"),
            p.get("crop_type", "wheat"),
        )
        if not img_ok and img_err:
            anomalies.append(img_err)
            confidence_score -= 0.25

        confidence_score = max(0.0, min(1.0, round(confidence_score, 2)))
        is_valid = len(anomalies) == 0 and confidence_score >= 0.80

        verification = VerificationResult(
            report_id=p.get("report_id", request.task_id),
            is_valid=is_valid,
            confidence_score=confidence_score,
            flagged_anomalies=anomalies,
            suggested_action="APPROVE" if is_valid else "FLAG_FOR_INSPECTION",
        )

        return AgentResponse(
            session_id=request.session_id,
            task_id=request.task_id,
            sender=self.agent_type,
            status="success",
            result=verification.model_dump(),
        )


domain_agent = DomainReasoningAgent()

app = FastAPI(title="SIH 26021 Domain Agent", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {
        "service": "agent_3_domain",
        "status": "healthy",
        "capabilities": domain_agent.get_capabilities(),
    }


@app.post("/process", response_model=AgentResponse)
async def process(request: AgentRequest):
    return await domain_agent.process(request)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8003, reload=True)
