"""
Madhur-Trace Database Models

Member 4:
Backend API Gateway
"""

from datetime import datetime

from sqlalchemy import Column, DateTime, Float, Integer, String, Text

from .database import Base


class Report(Base):
    """
    Stores a farmer report submitted to the Madhur-Trace backend.
    """

    __tablename__ = "reports"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    farmer_id = Column(
        String(100),
        nullable=False,
        index=True,
    )

    report_payload = Column(
        Text,
        nullable=False,
    )

    verification_status = Column(
        String(50),
        nullable=True,
    )

    verification_confidence = Column(
        Float,
        nullable=True,
    )

    report_hash = Column(
        String(64),
        unique=True,
        index=True,
        nullable=True,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )