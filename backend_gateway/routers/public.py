"""
Madhur-Trace Public Verification API

Member 4:
Backend API Gateway
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Report
from ..schemas import PublicVerificationProof, VerificationResult


router = APIRouter(
    prefix="/api/public",
    tags=["Public Verification"],
)


@router.get(
    "/verify/{report_hash}",
    response_model=PublicVerificationProof,
)
def verify_report(
    report_hash: str,
    db: Session = Depends(get_db),
):
    """
    Publicly verify a report using its SHA-256 report hash.
    """

    report = (
        db.query(Report)
        .filter(Report.report_hash == report_hash)
        .first()
    )

    if report is None:
        return PublicVerificationProof(
            verified=False,
            report_hash=report_hash,
            verification=None,
        )

    verification = VerificationResult(
        status=report.verification_status or "UNKNOWN",
        confidence=report.verification_confidence or 0.0,
        flags=[],
    )

    return PublicVerificationProof(
        verified=True,
        report_hash=report_hash,
        verification=verification,
    )