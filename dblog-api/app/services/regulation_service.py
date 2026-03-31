from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.noise_regulation import NoiseRegulation

FALLBACK_MUNICIPALITY = "España (Ley 37/2003)"


def get_regulations(
    db: Session,
    municipality: Optional[str] = None,
    zone_type: Optional[str] = None,
    time_period: Optional[str] = None,
    noise_type: Optional[str] = None,
) -> list[NoiseRegulation]:
    stmt = select(NoiseRegulation)

    if municipality:
        stmt = stmt.where(NoiseRegulation.municipality == municipality)
    if zone_type:
        stmt = stmt.where(NoiseRegulation.zone_type == zone_type)
    if time_period:
        stmt = stmt.where(NoiseRegulation.time_period == time_period)
    if noise_type:
        stmt = stmt.where(NoiseRegulation.noise_type == noise_type)

    stmt = stmt.order_by(NoiseRegulation.municipality, NoiseRegulation.zone_type)
    return list(db.execute(stmt).scalars().all())


def lookup_limit(
    db: Session,
    municipality: str,
    zone_type: str,
    time_period: str,
    noise_type: str,
) -> Optional[NoiseRegulation]:
    """Busca el límite aplicable. Si no hay ordenanza municipal, retorna el fallback de Ley 37/2003."""
    stmt = (
        select(NoiseRegulation)
        .where(NoiseRegulation.municipality == municipality)
        .where(NoiseRegulation.zone_type == zone_type)
        .where(NoiseRegulation.time_period == time_period)
        .where(NoiseRegulation.noise_type == noise_type)
    )
    result = db.execute(stmt).scalar_one_or_none()

    if result is None and municipality != FALLBACK_MUNICIPALITY:
        stmt = (
            select(NoiseRegulation)
            .where(NoiseRegulation.municipality == FALLBACK_MUNICIPALITY)
            .where(NoiseRegulation.zone_type == zone_type)
            .where(NoiseRegulation.time_period == time_period)
            .where(NoiseRegulation.noise_type == noise_type)
        )
        result = db.execute(stmt).scalar_one_or_none()

    return result


def get_municipalities(db: Session) -> list[str]:
    stmt = (
        select(NoiseRegulation.municipality)
        .distinct()
        .order_by(NoiseRegulation.municipality)
    )
    return list(db.execute(stmt).scalars().all())
