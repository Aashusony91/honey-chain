"""
Madhur-Trace Backend Configuration

Member 4:
Backend API Gateway
"""

import os


ORCHESTRATOR_URL = os.getenv(
    "ORCHESTRATOR_URL",
    "http://127.0.0.1:8001/orchestrate",
)

ORCHESTRATOR_TIMEOUT_SECONDS = float(
    os.getenv(
        "ORCHESTRATOR_TIMEOUT_SECONDS",
        "5",
    )
)

ORCHESTRATOR_FALLBACK_ENABLED = (
    os.getenv(
        "ORCHESTRATOR_FALLBACK_ENABLED",
        "true",
    ).lower()
    == "true"
)