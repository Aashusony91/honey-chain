"""
Madhur-Trace Gateway Validation

Member 4:
Backend API Gateway

Gateway-owned validation helpers for:
- GPS coordinate validation
- Harvest timestamp validation
- Basic hive telemetry sanity checks

This module does not modify shared.schemas.py.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Tuple

from shared.schemas import HoneyBatchPayload


# Maximum acceptable clock skew for a harvest timestamp.
# Five minutes allows for small device/server clock differences.
MAX_FUTURE_SKEW_SECONDS = 5 * 60


def parse_gps_coordinates(
    gps_coordinates: str,
) -> Tuple[float, float]:
    """
    Parse a 'latitude,longitude' string.

    Returns:
        (latitude, longitude)

    Raises:
        ValueError: if the format or coordinate ranges are invalid.
    """

    try:
        latitude_text, longitude_text = gps_coordinates.split(",", 1)

        latitude = float(latitude_text.strip())
        longitude = float(longitude_text.strip())

    except (ValueError, AttributeError):
        raise ValueError(
            "GPS coordinates must use the format 'latitude,longitude'."
        )

    if not -90 <= latitude <= 90:
        raise ValueError(
            f"Latitude {latitude} is outside the valid range [-90, 90]."
        )

    if not -180 <= longitude <= 180:
        raise ValueError(
            f"Longitude {longitude} is outside the valid range [-180, 180]."
        )

    return latitude, longitude


def validate_gps_coordinates(
    gps_coordinates: str,
) -> List[str]:
    """
    Validate the GPS coordinate string.

    Returns:
        A list of validation flags.

    An empty list means the coordinates passed validation.
    """

    flags: List[str] = []

    try:
        parse_gps_coordinates(gps_coordinates)
    except ValueError as exc:
        flags.append(f"INVALID_GPS: {exc}")

    return flags


def validate_harvest_timestamp(
    harvest_timestamp: int,
) -> List[str]:
    """
    Validate the harvest timestamp.

    The timestamp must:
    - be a positive Unix timestamp
    - not be unreasonably far in the future

    Returns:
        A list of validation flags.
    """

    flags: List[str] = []

    if harvest_timestamp <= 0:
        flags.append("INVALID_HARVEST_TIMESTAMP")
        return flags

    now = datetime.now(timezone.utc).timestamp()

    if harvest_timestamp > now + MAX_FUTURE_SKEW_SECONDS:
        flags.append("HARVEST_TIMESTAMP_IN_FUTURE")

    return flags


def validate_telemetry(
    payload: HoneyBatchPayload,
) -> List[str]:
    """
    Perform basic sanity checks on optional hive telemetry.

    These checks are deliberately conservative. They flag obviously
    invalid values rather than attempting to determine honey quality.
    """

    flags: List[str] = []

    telemetry = payload.telemetry

    if telemetry is None:
        return flags

    if telemetry.internal_temp_c < -50 or telemetry.internal_temp_c > 80:
        flags.append("TELEMETRY_TEMPERATURE_OUT_OF_RANGE")

    if (
        telemetry.internal_humidity_pct < 0
        or telemetry.internal_humidity_pct > 100
    ):
        flags.append("TELEMETRY_HUMIDITY_OUT_OF_RANGE")

    if telemetry.hive_weight_kg < 0:
        flags.append("TELEMETRY_NEGATIVE_HIVE_WEIGHT")

    if telemetry.registered_hive_count < 0:
        flags.append("TELEMETRY_INVALID_HIVE_COUNT")

    return flags


def validate_batch(
    payload: HoneyBatchPayload,
) -> List[str]:
    """
    Run all gateway-owned validation checks for a honey batch.

    Returns:
        Combined list of validation flags.

    An empty list means no gateway validation anomaly was detected.
    """

    flags: List[str] = []

    flags.extend(
        validate_gps_coordinates(
            payload.gps_coordinates
        )
    )

    flags.extend(
        validate_harvest_timestamp(
            payload.harvest_timestamp
        )
    )

    flags.extend(
        validate_telemetry(
            payload
        )
    )

    # Hackathon Demo: Biological Yield Anomaly Trap (The Math Trap)
    # A single beehive can physically only produce a maximum of ~30-35kg of honey per season.
    if payload.telemetry and payload.telemetry.registered_hive_count > 0:
        yield_per_hive = payload.harvest_weight_kg / payload.telemetry.registered_hive_count
        if yield_per_hive > 35.0:
            flags.append(f"STATISTICAL_YIELD_ANOMALY: Impossible biological yield ({yield_per_hive:.1f} kg/hive). Max limit is 35 kg/hive.")

    return flags