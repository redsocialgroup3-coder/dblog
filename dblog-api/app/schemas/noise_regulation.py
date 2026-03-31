import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class NoiseRegulationResponse(BaseModel):
    id: uuid.UUID
    municipality: str
    zone_type: str
    time_period: str
    noise_type: str
    db_limit: float
    regulation_name: Optional[str]
    article: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
