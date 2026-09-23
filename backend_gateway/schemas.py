"""
Madhur-Trace Backend Gateway API Schemas

Member 4:
Backend API Gateway

These schemas are gateway-specific request/response models.
The canonical supply-chain data contract remains in shared.schemas.
"""

from typing import Any, Dict, Optional

from pydantic import BaseModel, Field

from shared.schemas import HoneyBatchPayload


class FarmerReportPayload(BaseModel):
    """
    Request received by the backend gateway from the frontend.

    The actual supply-chain batch data is represented using the
    immutable shared HoneyBatchPayload contract.
    """

    batch: HoneyBatchPayload

    additional_data: Optional[Dict[str, Any]] = None


class VerificationResult(BaseModel):
    """
    Verification result produced by the gateway/orchestrator flow.
    """

    status: str
    confidence: float = Field(..., ge=0, le=1)
    flags: list[str] = Field(default_factory=list)


class ReportSubmissionResponse(BaseModel):
    """
    Response returned after a farmer report is submitted.
    """

    report_id: int
    report_hash: Optional[str] = None
    verification: VerificationResult


class PublicVerificationProof(BaseModel):
    """
    Public proof returned when a report hash is verified.
    """

    verified: bool
    report_hash: str
    verification: Optional[VerificationResult] = None