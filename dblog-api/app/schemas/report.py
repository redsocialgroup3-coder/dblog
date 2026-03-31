import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ReportRequest(BaseModel):
    recording_ids: list[uuid.UUID] = Field(
        ..., description="Lista de IDs de grabaciones a incluir en el informe"
    )
    address: str = Field(..., description="Dirección completa del inmueble")
    floor_door: Optional[str] = Field(None, description="Piso y puerta")
    municipality: str = Field(..., description="Municipio")
    zone_type: str = Field(
        ..., description="Tipo de zona: residencial, comercial, industrial"
    )
    time_period: str = Field(
        ..., description="Franja horaria: diurno, nocturno, evening"
    )
    noise_type: str = Field(
        ..., description="Tipo de ruido: interior, exterior"
    )
    reporter_name: Optional[str] = Field(
        None, description="Nombre del denunciante (opcional)"
    )


class ReportResponse(BaseModel):
    report_id: uuid.UUID
    download_url: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportListItem(BaseModel):
    id: uuid.UUID
    address: str
    zone_type: str
    is_preview: bool
    audio_hash: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
