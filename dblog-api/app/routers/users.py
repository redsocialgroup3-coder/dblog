import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.recording import Recording
from app.models.report import Report
from app.models.user import User
from app.schemas.user import UserProfileResponse, UserProfileUpdate
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me/profile", response_model=UserProfileResponse)
async def get_profile(current_user: User = Depends(get_current_user)):
    """Retorna el perfil del usuario autenticado."""
    return current_user


@router.put("/me/profile", response_model=UserProfileResponse)
async def update_profile(
    body: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Actualiza los campos del perfil del usuario autenticado."""
    update_data = body.model_dump(exclude_unset=True)

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se proporcionaron campos para actualizar",
        )

    for field, value in update_data.items():
        setattr(current_user, field, value)

    db.commit()
    db.refresh(current_user)
    logger.info("Perfil actualizado: %s", current_user.firebase_uid)
    return current_user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Elimina la cuenta del usuario y TODOS sus datos asociados (RGPD art. 17).

    - Elimina grabaciones de R2
    - Elimina informes PDF de R2
    - Elimina registros de DB (recordings, reports, user)
    """
    logger.info("Eliminando cuenta y datos: %s", current_user.firebase_uid)

    # 1. Eliminar archivos de grabaciones de R2.
    recordings = (
        db.query(Recording)
        .filter(Recording.user_id == current_user.id)
        .all()
    )
    for recording in recordings:
        try:
            storage_service.delete_file(recording.file_path)
        except Exception as e:
            logger.warning("No se pudo eliminar recording de R2 (%s): %s", recording.file_path, e)

    # 2. Eliminar archivos de informes de R2.
    reports = (
        db.query(Report)
        .filter(Report.user_id == current_user.id)
        .all()
    )
    for report in reports:
        try:
            storage_service.delete_file(report.file_path)
        except Exception as e:
            logger.warning("No se pudo eliminar report de R2 (%s): %s", report.file_path, e)

    # 3. Eliminar registros de DB (cascade eliminará recordings y reports).
    db.delete(current_user)
    db.commit()
    logger.info("Cuenta eliminada completamente: %s", current_user.firebase_uid)


@router.get("/me/export")
async def export_user_data(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Exporta todos los datos del usuario en JSON (RGPD art. 20 - derecho de portabilidad).

    Incluye perfil, grabaciones (metadatos) e informes (metadatos).
    """
    # Grabaciones.
    recordings = (
        db.query(Recording)
        .filter(Recording.user_id == current_user.id)
        .order_by(Recording.timestamp.desc())
        .all()
    )

    # Informes.
    reports = (
        db.query(Report)
        .filter(Report.user_id == current_user.id)
        .all()
    )

    return {
        "profile": {
            "id": str(current_user.id),
            "email": current_user.email,
            "display_name": current_user.display_name,
            "address": current_user.address,
            "floor_door": current_user.floor_door,
            "municipality": current_user.municipality,
            "calibration_offset": current_user.calibration_offset,
            "db_threshold": current_user.db_threshold,
            "is_subscriber": current_user.is_subscriber,
            "created_at": current_user.created_at.isoformat(),
            "updated_at": current_user.updated_at.isoformat(),
        },
        "recordings": [
            {
                "id": str(r.id),
                "file_name": r.file_name,
                "timestamp": r.timestamp.isoformat(),
                "latitude": r.latitude,
                "longitude": r.longitude,
                "avg_db": r.avg_db,
                "max_db": r.max_db,
                "duration_seconds": r.duration_seconds,
                "metadata_json": r.metadata_json,
                "created_at": r.created_at.isoformat(),
            }
            for r in recordings
        ],
        "reports": [
            {
                "id": str(r.id),
                "recording_ids": r.recording_ids,
                "address": r.address,
                "floor_door": r.floor_door,
                "zone_type": r.zone_type,
                "reporter_name": r.reporter_name,
                "audio_hash": r.audio_hash,
                "created_at": r.created_at.isoformat(),
            }
            for r in reports
        ],
        "export_date": __import__("datetime").datetime.now().isoformat(),
        "format_version": "1.0",
    }
