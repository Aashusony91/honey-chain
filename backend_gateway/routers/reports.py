"""
Madhur-Trace Report API

Member 4:
Backend API Gateway
"""

import hashlib
import json

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Report
from ..schemas import (
    FarmerReportPayload,
    ReportSubmissionResponse,
    VerificationResult,
)


router = APIRouter(
    prefix="/api/reports",
    tags=["Reports"],
)


def generate_report_hash(
    payload: FarmerReportPayload,
    verification: VerificationResult,
) -> str:
    """
    Generate a SHA-256 hash for the submitted report.

    The canonical HoneyBatchPayload is included in the hash input
    together with the verification result.
    """

    hash_data = {
        "batch": payload.batch.model_dump(mode="json"),
        "verification_status": verification.status,
        "verification_confidence": verification.confidence,
    }

    canonical_data = json.dumps(
        hash_data,
        sort_keys=True,
        separators=(",", ":"),
    )

    return hashlib.sha256(
        canonical_data.encode("utf-8")
    ).hexdigest()


@router.post(
    "/submit",
    response_model=ReportSubmissionResponse,
)
def submit_report(
    payload: FarmerReportPayload,
    db: Session = Depends(get_db),
):
    """
    Receive a HoneyBatchPayload from the frontend.

    For the initial Member 4 implementation, the orchestrator
    response is mocked.

    Later this will forward the batch to Member 1's
    orchestrator on port 8001.
    """

    # Temporary mock verification.
    # This will later be replaced by the live orchestrator response.
    verification = VerificationResult(
        status="VERIFIED",
        confidence=0.92,
        flags=[],
    )

    report_hash = generate_report_hash(
        payload,
        verification,
    )

    report = Report(
        farmer_id=payload.batch.farmer_id,
        report_payload=payload.batch.model_dump_json(),
        verification_status=verification.status,
        verification_confidence=verification.confidence,
        report_hash=report_hash,
    )

    db.add(report)
    db.commit()
    db.refresh(report)

    return ReportSubmissionResponse(
        report_id=report.id,
        report_hash=report.report_hash,
        verification=verification,
    )