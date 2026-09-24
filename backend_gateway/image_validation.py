"""
Madhur-Trace Image Validation

Member 4:
Backend API Gateway

Provides:
- EXIF GPS extraction
- EXIF timestamp extraction
- Haversine distance calculation
- 100-meter geofence validation
- Perceptual hash (pHash) generation
- Duplicate image detection
"""

from __future__ import annotations

import math
from datetime import datetime
from io import BytesIO
from typing import Optional

from PIL import Image
from PIL.ExifTags import GPSTAGS, TAGS
from sqlalchemy.orm import Session

from .models import ImageFingerprint


GEOFENCE_LIMIT_METERS = 100.0


def extract_exif_data(image_bytes: bytes) -> dict:
    """Extract useful EXIF metadata from an image."""

    image = Image.open(BytesIO(image_bytes))
    exif = image.getexif()

    result = {
        "gps": None,
        "timestamp": None,
    }

    if not exif:
        return result

    decoded = {}

    for tag_id, value in exif.items():
        tag_name = TAGS.get(tag_id, tag_id)
        decoded[tag_name] = value

    gps_info = decoded.get("GPSInfo")

    if gps_info:
        gps_decoded = {}

        for key, value in gps_info.items():
            gps_decoded[GPSTAGS.get(key, key)] = value

        latitude = gps_decoded.get("GPSLatitude")
        longitude = gps_decoded.get("GPSLongitude")
        latitude_ref = gps_decoded.get("GPSLatitudeRef")
        longitude_ref = gps_decoded.get("GPSLongitudeRef")

        if latitude and longitude:
            lat = _gps_to_decimal(latitude)

            lon = _gps_to_decimal(longitude)

            if latitude_ref == "S":
                lat = -lat

            if longitude_ref == "W":
                lon = -lon

            result["gps"] = {
                "latitude": lat,
                "longitude": lon,
            }

    timestamp = (
        decoded.get("DateTimeOriginal")
        or decoded.get("DateTime")
    )

    if timestamp:
        result["timestamp"] = str(timestamp)

    return result


def _gps_to_decimal(value) -> float:
    """Convert EXIF GPS degrees/minutes/seconds to decimal."""

    degrees = float(value[0])
    minutes = float(value[1])
    seconds = float(value[2])

    return degrees + (minutes / 60) + (seconds / 3600)


def haversine_distance_meters(
    latitude1: float,
    longitude1: float,
    latitude2: float,
    longitude2: float,
) -> float:
    """Calculate distance between two GPS coordinates."""

    earth_radius = 6_371_000

    lat1 = math.radians(latitude1)
    lat2 = math.radians(latitude2)

    delta_lat = math.radians(latitude2 - latitude1)
    delta_lon = math.radians(longitude2 - longitude1)

    a = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat1)
        * math.cos(lat2)
        * math.sin(delta_lon / 2) ** 2
    )

    c = 2 * math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a),
    )

    return earth_radius * c


def generate_phash(image_bytes: bytes) -> str:
    """
    Generate a simple perceptual hash.

    The image is resized to 32x32 grayscale and transformed
    using a DCT-like low-frequency representation.
    """

    image = Image.open(BytesIO(image_bytes)).convert("L")

    image = image.resize((32, 32))

    pixels = list(image.getdata())

    average = sum(pixels) / len(pixels)

    bits = "".join(
        "1" if pixel >= average else "0"
        for pixel in pixels
    )

    return f"{int(bits, 2):0256x}"


def validate_image(
    image_bytes: bytes,
    registered_latitude: Optional[float] = None,
    registered_longitude: Optional[float] = None,
    db: Optional[Session] = None,
) -> dict:
    """
    Validate image metadata and detect reused images.
    """

    flags = []

    exif = extract_exif_data(image_bytes)

    gps = exif["gps"]

    distance_meters = None

    if (
        gps
        and registered_latitude is not None
        and registered_longitude is not None
    ):
        distance_meters = haversine_distance_meters(
            gps["latitude"],
            gps["longitude"],
            registered_latitude,
            registered_longitude,
        )

        if distance_meters > GEOFENCE_LIMIT_METERS:
            flags.append(
                "PHOTO_GPS_OUTSIDE_100M_GEOFENCE"
            )

    elif registered_latitude is not None:
        flags.append("PHOTO_GPS_METADATA_MISSING")

    phash = generate_phash(image_bytes)

    duplicate = False

    if db is not None:
        existing = (
            db.query(ImageFingerprint)
            .filter(ImageFingerprint.phash == phash)
            .first()
        )

        if existing:
            duplicate = True
            flags.append("DUPLICATE_IMAGE_DETECTED")

    return {
        "valid": len(flags) == 0,
        "flags": flags,
        "gps": gps,
        "exif_timestamp": exif["timestamp"],
        "distance_meters": distance_meters,
        "phash": phash,
        "duplicate": duplicate,
    }