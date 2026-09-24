from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class BatchCreateRequest(BaseModel):
    batch_id: Optional[str] = None
    farmer_id: str = Field(min_length=1, max_length=100)
    hive_id: Optional[str] = None
    parent_batch_id: Optional[str] = None
    weight_kg: float = Field(gt=0)
    flora_source: Optional[str] = None
    gps_location: Optional[str] = None
    harvest_timestamp: int = Field(gt=0)


class EventCreateRequest(BaseModel):
    batch_id: str
    event_type: str = Field(min_length=2, max_length=60)
    actor_id: Optional[str] = None
    location: Optional[str] = None
    event_timestamp: int = Field(gt=0)
    quantity_kg: Optional[float] = Field(default=None, ge=0)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    package_code: Optional[str] = None


class BatchTransformRequest(BaseModel):
    child_batch_id: Optional[str] = None
    farmer_id: str = Field(min_length=1, max_length=100)
    hive_id: Optional[str] = None
    weight_kg: float = Field(gt=0)
    flora_source: Optional[str] = None
    gps_location: Optional[str] = None
    relationship_type: str = Field(default="SPLIT", min_length=3, max_length=30)
    actor_id: Optional[str] = None
    event_timestamp: int = Field(gt=0)


class PackageCreateRequest(BaseModel):
    batch_id: str
    package_code: Optional[str] = None
    product_name: str = Field(min_length=1, max_length=200)
    net_weight_kg: float = Field(gt=0)


class QRScanRequest(BaseModel):
    latitude: Optional[float] = Field(default=None, ge=-90, le=90)
    longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    device_id: Optional[str] = Field(default=None, max_length=120)


class EventResponse(BaseModel):
    id: int
    event_type: str
    actor_id: Optional[str]
    location: Optional[str]
    event_timestamp: str
    quantity_kg: Optional[float]
    metadata: Dict[str, Any]
    previous_hash: Optional[str]
    event_hash: str


class TraceResponse(BaseModel):
    verified: bool
    package_code: str
    product_name: str
    package_status: str
    batch_id: str
    batch: Dict[str, Any]
    journey: List[EventResponse]
    lineage: List[Dict[str, Any]]
    scans: List[Dict[str, Any]]
    integrity: Dict[str, Any]
