import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class UserCreate(BaseModel):
    firebase_uid: str
    email: str
    display_name: Optional[str] = None
    address: Optional[str] = None
    floor_door: Optional[str] = None
    municipality: Optional[str] = None
    calibration_offset: float = 0.0


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    address: Optional[str] = None
    floor_door: Optional[str] = None
    municipality: Optional[str] = None
    calibration_offset: Optional[float] = None


class UserResponse(BaseModel):
    id: uuid.UUID
    firebase_uid: str
    email: str
    display_name: Optional[str]
    address: Optional[str]
    floor_door: Optional[str]
    municipality: Optional[str]
    calibration_offset: float
    is_subscriber: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
