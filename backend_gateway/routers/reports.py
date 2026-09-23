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
from ..orchestrator_client import call_orchestrator
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


def create_mock_verification(
    validation_flags: list[str],
) -> VerificationResult:
    """
    Existing gateway fallback verification.
    """

    if validation_flags:
        return VerificationResult(
            status="FLAGGED_FOR_REVIEW",
            confidence=0.50,
            flags=validation_flags,
        )

    return VerificationResult(
        status="VERIFIED",
        confidence=0.92,
        flags=[],
    )


@router.post(
    "/submit",
    response_model=ReportSubmissionResponse,
)
def submit_report(
    payload: FarmerReportPayload,
    db: Session = Depends(get_db),
):
    """
    Receive a HoneyBatchPayload.

    Flow:
    1. Gateway validation.
    2. Try Member 1 orchestrator.
    3. Fall back to gateway mock if unavailable.
    4. Generate SHA-256.
    5. Persist report.
    """

    validation_flags = validate_batch(
        payload.batch
    )

    verification = None

    if not validation_flags:
        verification = call_orchestrator(
            payload
        )

    if verification is None:
        verification = create_mock_verification(
            validation_flags
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


@router.get("/{report_id}/status")
def get_report_status(
    report_id: int,
    db: Session = Depends(get_db),
):
    """
    Return the current verification status.
    """

    report = (
        db.query(Report)
        .filter(Report.id == report_id)
        .first()
    )

    if report is None:
        return {
            "found": False,
            "report_id": report_id,
        }

    return {
        "found": True,
        "report_id": report.id,
        "status": report.verification_status or "PENDING",
        "confidence": report.verification_confidence,
        "report_hash": report.report_hash,
        "created_at": report.created_at,
    }