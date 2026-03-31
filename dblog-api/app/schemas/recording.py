import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class RecordingCreate(BaseModel):
    file_path: str
    file_name: str
    timestamp: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    avg_db: Optional[float] = None
    max_db: Optional[float] = None
    duration_seconds: Optional[int] = None
    metadata_json: Optional[dict] = None


class RecordingResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    file_path: str
    file_name: str
    timestamp: datetime
    latitude: Optional[float]
    longitude: Optional[float]
    avg_db: Optional[float]
    max_db: Optional[float]
    duration_seconds: Optional[int]
    metadata_json: Optional[dict]
    created_at: datetime

    model_config = {"from_attributes": True}
