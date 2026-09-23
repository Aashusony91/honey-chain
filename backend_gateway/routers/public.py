"""
Madhur-Trace Public Verification API

Member 4:
Backend API Gateway
"""

import hashlib
import json

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Report
from ..schemas import PublicVerificationProof, VerificationResult

router = APIRouter(
    prefix="/api/public",
    tags=["Public Verification"],
)


def recompute_report_hash(report: Report) -> str:
    """
    Recompute the SHA-256 hash from the data stored for the report.

    This allows the public verification endpoint to check that the
    stored report content still matches the originally generated hash.
    """

    batch_data = json.loads(report.report_payload)

    hash_data = {
        "batch": batch_data,
        "verification_status": report.verification_status,
        "verification_confidence": report.verification_confidence,
    }

    canonical_data = json.dumps(
        hash_data,
        sort_keys=True,
        separators=(",", ":"),
    )

    return hashlib.sha256(
        canonical_data.encode("utf-8")
    ).hexdigest()


@router.get(
    "/verify/{report_hash}",
    response_model=PublicVerificationProof,
)
def verify_report(
    report_hash: str,
    db: Session = Depends(get_db),
):
    """
    Publicly verify a report hash.

    The endpoint:
    1. Finds the report by its stored hash.
    2. Recomputes the SHA-256 hash from stored data.
    3. Compares the recomputed hash with the requested hash.
    4. Returns whether the report integrity is verified.
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

    recomputed_hash = recompute_report_hash(report)

    if recomputed_hash != report_hash:
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