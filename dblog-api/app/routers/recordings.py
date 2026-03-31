import logging
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.recording import Recording
from app.models.user import User
from app.schemas.recording import RecordingResponse
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recordings", tags=["recordings"])


@router.post("/upload", response_model=RecordingResponse, status_code=status.HTTP_201_CREATED)
async def upload_recording(
    file: UploadFile = File(...),
    file_name: str = Form(...),
    timestamp: datetime = Form(...),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    avg_db: Optional[float] = Form(None),
    max_db: Optional[float] = Form(None),
    duration_seconds: Optional[int] = Form(None),
    local_id: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Sube un archivo de audio a R2 y guarda los metadatos en DB."""
    recording_id = uuid.UUID(local_id) if local_id else uuid.uuid4()
    key = f"{current_user.id}/{recording_id}/{file_name}"

    # Subir archivo a R2.
    url = storage_service.upload_file(file.file, key, content_type=file.content_type or "audio/mp4")

    # Crear registro en DB.
    recording = Recording(
        id=recording_id,
        user_id=current_user.id,
        file_path=key,
        file_name=file_name,
        timestamp=timestamp,
        latitude=latitude,
        longitude=longitude,
        avg_db=avg_db,
        max_db=max_db,
        duration_seconds=duration_seconds,
    )
    db.add(recording)
    db.commit()
    db.refresh(recording)

    logger.info("Recording subida: %s por user %s", recording.id, current_user.id)
    return recording


@router.get("/", response_model=list[RecordingResponse])
async def list_recordings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista todas las grabaciones del usuario autenticado."""
    recordings = (
        db.query(Recording)
        .filter(Recording.user_id == current_user.id)
        .order_by(Recording.timestamp.desc())
        .all()
    )
    return recordings


@router.get("/{recording_id}", response_model=RecordingResponse)
async def get_recording(
    recording_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtiene el detalle de una grabación."""
    recording = (
        db.query(Recording)
        .filter(Recording.id == recording_id, Recording.user_id == current_user.id)
        .first()
    )
    if not recording:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Grabación no encontrada")
    return recording


@router.get("/{recording_id}/download")
async def download_recording(
    recording_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Genera una URL presigned para descargar el audio."""
    recording = (
        db.query(Recording)
        .filter(Recording.id == recording_id, Recording.user_id == current_user.id)
        .first()
    )
    if not recording:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Grabación no encontrada")

    url = storage_service.download_url(recording.file_path)
    return {"download_url": url}


@router.delete("/{recording_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_recording(
    recording_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Elimina una grabación de R2 y DB."""
    recording = (
        db.query(Recording)
        .filter(Recording.id == recording_id, Recording.user_id == current_user.id)
        .first()
    )
    if not recording:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Grabación no encontrada")

    # Eliminar de R2.
    try:
        storage_service.delete_file(recording.file_path)
    except Exception as e:
        logger.warning("No se pudo eliminar archivo de R2: %s", e)

    db.delete(recording)
    db.commit()


class SyncRequest:
    """Modelo para request de sincronización."""
    pass


from pydantic import BaseModel


class SyncRequestBody(BaseModel):
    """IDs de grabaciones locales del cliente."""
    local_ids: list[str]


class SyncResponse(BaseModel):
    """Resultado de sincronización bidireccional."""
    missing_on_server: list[str]
    missing_on_client: list[RecordingResponse]


@router.post("/sync", response_model=SyncResponse)
async def sync_recordings(
    body: SyncRequestBody,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Sincronización bidireccional: compara IDs locales con los del servidor.

    Retorna:
    - missing_on_server: IDs que el cliente tiene pero el servidor no (deben subirse)
    - missing_on_client: Recordings que el servidor tiene pero el cliente no (deben descargarse)
    """
    # IDs en el servidor para este usuario.
    server_recordings = (
        db.query(Recording)
        .filter(Recording.user_id == current_user.id)
        .all()
    )
    server_ids = {str(r.id) for r in server_recordings}
    local_ids = set(body.local_ids)

    # IDs que el cliente tiene pero el servidor no.
    missing_on_server = list(local_ids - server_ids)

    # Recordings que el servidor tiene pero el cliente no.
    missing_on_client_ids = server_ids - local_ids
    missing_on_client = [r for r in server_recordings if str(r.id) in missing_on_client_ids]

    return SyncResponse(
        missing_on_server=missing_on_server,
        missing_on_client=missing_on_client,
    )
