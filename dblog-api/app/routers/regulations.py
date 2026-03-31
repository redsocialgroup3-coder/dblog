from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.noise_regulation import NoiseRegulationResponse
from app.services.regulation_service import (
    get_municipalities,
    get_regulations,
    lookup_limit,
)

router = APIRouter(prefix="/regulations", tags=["regulations"])


@router.get("/", response_model=list[NoiseRegulationResponse])
def list_regulations(
    municipality: Optional[str] = Query(None),
    zone_type: Optional[str] = Query(None),
    time_period: Optional[str] = Query(None),
    noise_type: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """Lista todas las regulaciones con filtros opcionales."""
    return get_regulations(
        db,
        municipality=municipality,
        zone_type=zone_type,
        time_period=time_period,
        noise_type=noise_type,
    )


@router.get("/lookup", response_model=NoiseRegulationResponse)
def lookup_regulation(
    municipality: str = Query(..., description="Municipio a consultar"),
    zone_type: str = Query(..., description="Tipo de zona: residencial, comercial, industrial"),
    time_period: str = Query(..., description="Franja horaria: diurno, nocturno, evening"),
    noise_type: str = Query(..., description="Tipo: interior, exterior"),
    db: Session = Depends(get_db),
):
    """Consulta el límite de dB aplicable. Si no existe ordenanza municipal, retorna el fallback de Ley 37/2003."""
    result = lookup_limit(db, municipality, zone_type, time_period, noise_type)
    if result is None:
        raise HTTPException(
            status_code=404,
            detail=f"No se encontró regulación para {municipality} con los parámetros indicados",
        )
    return result


@router.get("/municipalities", response_model=list[str])
def list_municipalities(db: Session = Depends(get_db)):
    """Lista todos los municipios disponibles en la base de datos."""
    return get_municipalities(db)
