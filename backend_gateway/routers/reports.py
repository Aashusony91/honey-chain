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
from ..validation import validate_batch


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

    Gateway validation is performed before the current mock
    verification flow.

    Later this mock verification will be replaced by the live
    Member 1 orchestrator response.
    """

    # Run Member 4 gateway-owned validation.
    validation_flags = validate_batch(payload.batch)

    # Temporary mock verification.
    # This will later be replaced by the live orchestrator response.
    if validation_flags:
        verification = VerificationResult(
            status="FLAGGED_FOR_REVIEW",
            confidence=0.50,
            flags=validation_flags,
        )
    else:
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