import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


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


class VerdictEnum(str, Enum):
    SUPERA = "SUPERA"
    NO_SUPERA = "NO_SUPERA"
    CERCANO = "CERCANO"


class VerdictRequest(BaseModel):
    municipality: str = Field(..., description="Municipio a consultar")
    zone_type: str = Field(
        ..., description="Tipo de zona: residencial, comercial, industrial"
    )
    time_period: str = Field(
        ..., description="Franja horaria: diurno, nocturno, evening"
    )
    noise_type: str = Field(..., description="Tipo: interior, exterior")
    measured_db: float = Field(..., description="Nivel de dB medido")


class VerdictResponse(BaseModel):
    limit_db: float
    measured_db: float
    difference_db: float
    verdict: VerdictEnum
    regulation_name: Optional[str]
    article: Optional[str]
    time_period_detected: str
    municipality: str
