"""
Madhur-Trace Image Validation API

Member 4:
Backend API Gateway
"""

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.orm import Session

from ..database import get_db
from ..image_validation import validate_image
from ..models import ImageFingerprint


router = APIRouter(
    prefix="/api/reports",
    tags=["Image Validation"],
)


@router.post("/validate-image")
async def validate_report_image(
    image: UploadFile = File(...),
    registered_latitude: float | None = Form(None),
    registered_longitude: float | None = Form(None),
    db: Session = Depends(get_db),
):
    """
    Validate uploaded harvest image.

    Checks:
    - EXIF GPS
    - 100-meter geofence
    - EXIF timestamp
    - perceptual hash
    - duplicate image reuse
    """

    image_bytes = await image.read()

    if not image_bytes:
        return {
            "valid": False,
            "flags": ["EMPTY_IMAGE"],
        }

    result = validate_image(
        image_bytes=image_bytes,
        registered_latitude=registered_latitude,
        registered_longitude=registered_longitude,
        db=db,
    )

    if not result["duplicate"]:
        db.add(
            ImageFingerprint(
                phash=result["phash"],
            )
        )
        db.commit()

    return {
        "filename": image.filename,
        "content_type": image.content_type,
        **result,
    }
