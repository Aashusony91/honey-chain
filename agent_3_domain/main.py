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
        super().__init__()
        self.agent_type = AgentType.IOT_FRAUD_ENGINE

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
        """
        Verify that harvest photo GPS matches registered land coordinates within threshold.
        Uses the Haversine formula to compute great-circle distance.
        """
        if photo_lat == 0.0 and photo_lon == 0.0:
            # Fallback if EXIF GPS wasn't extractable
            return True, 0.0, None

        r = 6371000.0  # Earth's radius in meters
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
        """
        Detect statistical anomalies in reported harvest yield against regional baseline.
        Flags report if |Z-Score| > 3.0 (three standard deviations).
        """
        if land_acres <= 0.0:
            return False, 0.0, 0.0, "Invalid land area: Acres must be greater than 0"

        yield_density = reported_yield / land_acres
        effective_std = baseline_std if baseline_std > 1e-4 else 1.0
        z_score = (yield_density - baseline_mean) / effective_std

        if abs(z_score) > 3.0:
            anomaly = (
                f"Statistical yield anomaly: Reported density is {yield_density:.2f} quintals/acre "
                f"(District baseline: {baseline_mean:.2f} +/- {effective_std:.2f}, Z-Score: {z_score:+.2f})"
            )
            return False, yield_density, z_score, anomaly

        return True, yield_density, z_score, None

    def verify_crop_image(
        self,
        image_url: Optional[str],
        declared_crop: str,
    ) -> Tuple[bool, str, float, Optional[str]]:
        """
        Placeholder for computer-vision crop identification model.
        In production: Calls TensorFlow/PyTorch model endpoint or Vision API.
        """
        if not image_url:
            return True, declared_crop, 1.0, None

        declared_crop_clean = declared_crop.strip().lower()
        return True, declared_crop_clean, 0.94, None

    async def process(self, request: AgentRequest) -> AgentResponse:
        p: Dict[str, Any] = (
            request.payload.model_dump()
            if hasattr(request.payload, "model_dump")
            else dict(request.payload)
        )
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

        # 2. Yield Z-Score Check (honey baseline: ~0.25 quintals/acre = 25 kg)
        reported_yield = p.get("reported_yield_quintals")
        if reported_yield is None or reported_yield == 0.0:
            reported_yield = p.get("harvest_weight_kg", 0.0) / 100.0

        yield_ok, _, _, yield_err = self.calculate_yield_zscore(
            reported_yield,
            p.get("land_acres", 1.0),
            p.get("baseline_mean", 0.25),
            p.get("baseline_std", 0.08),
        )
        if not yield_ok and yield_err:
            anomalies.append(yield_err)
            confidence_score -= 0.40

        # 3. Vision Check (if image_url is provided)
        if p.get("image_url"):
            img_ok, _, _, img_err = self.verify_crop_image(
                p.get("image_url"),
                p.get("crop_type", "honey"),
            )
            if not img_ok and img_err:
                anomalies.append(img_err)
                confidence_score -= 0.25

        confidence_score = max(0.0, min(1.0, round(confidence_score, 2)))
        is_valid = len(anomalies) == 0 and confidence_score >= 0.80

        verification = VerificationResult(
            report_id=str(p.get("report_id", request.task_id)),
            is_valid=is_valid,
            confidence_score=confidence_score,
            flagged_anomalies=anomalies,
            suggested_action="APPROVE" if is_valid else "FLAG_FOR_INSPECTION",
        )

        return AgentResponse(
            session_id=request.session_id,
            task_id=request.task_id,
            sender=self.agent_type,
            status="success" if is_valid else "flagged_for_review",
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
