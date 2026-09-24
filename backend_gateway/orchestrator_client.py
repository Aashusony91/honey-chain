"""
Madhur-Trace Orchestrator Client

Member 4:
Backend API Gateway

Calls Member 1's orchestrator when available.
Falls back to the existing gateway mock when the
orchestrator service is unavailable.
"""

import json
from urllib.error import URLError
from urllib.request import Request, urlopen

from .config import (
    ORCHESTRATOR_FALLBACK_ENABLED,
    ORCHESTRATOR_TIMEOUT_SECONDS,
    ORCHESTRATOR_URL,
)
from .schemas import FarmerReportPayload, VerificationResult


def call_orchestrator(
    payload: FarmerReportPayload,
) -> VerificationResult | None:
    """
    Send the farmer report to Member 1's orchestrator.

    Returns:
        VerificationResult when the orchestrator responds successfully.
        None when the orchestrator is unavailable and fallback is enabled.
    """

    body = json.dumps(
        payload.model_dump(mode="json")
    ).encode("utf-8")

    request = Request(
        ORCHESTRATOR_URL,
        data=body,
        headers={
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urlopen(
            request,
            timeout=ORCHESTRATOR_TIMEOUT_SECONDS,
        ) as response:
            response_data = json.loads(
                response.read().decode("utf-8")
            )

        return VerificationResult.model_validate(
            response_data
        )

    except (
        URLError,
        TimeoutError,
        ValueError,
        json.JSONDecodeError,
    ):
        if ORCHESTRATOR_FALLBACK_ENABLED:
            return None

        raise