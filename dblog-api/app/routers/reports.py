import io
import logging
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.recording import Recording
from app.models.report import Report
from app.models.user import User
from app.schemas.report import ReportListItem, ReportRequest, ReportResponse
from app.services.pdf_service import compute_audio_hash, generate_report
from app.services.regulation_service import lookup_limit
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/reports", tags=["reports"])


def _fetch_recordings(
    db: Session, user_id: uuid.UUID, recording_ids: list[uuid.UUID]
) -> list[Recording]:
    """Obtiene las grabaciones del usuario validando que existan y le pertenezcan."""
    recordings = (
        db.query(Recording)
        .filter(Recording.id.in_(recording_ids), Recording.user_id == user_id)
        .order_by(Recording.timestamp)
        .all()
    )
    if len(recordings) != len(recording_ids):
        found_ids = {r.id for r in recordings}
        missing = [str(rid) for rid in recording_ids if rid not in found_ids]
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Grabaciones no encontradas: {', '.join(missing)}",
        )
    return recordings


def _download_first_audio(recordings: list[Recording]) -> tuple[bytes, str]:
    """Descarga el primer audio de R2 y calcula su hash SHA-256.

    Retorna (audio_bytes, hash_hex).
    """
    first = recordings[0]
    # Generar URL presigned y descargar
    import httpx

    url = storage_service.download_url(first.file_path, expires_in=300)
    response = httpx.get(url, timeout=60)
    response.raise_for_status()
    audio_bytes = response.content
    audio_hash = compute_audio_hash(audio_bytes)
    return audio_bytes, audio_hash


@router.post("/generate", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def generate_report_endpoint(
    request: ReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Genera un informe PDF completo, lo sube a R2 y guarda en DB."""
    recordings = _fetch_recordings(db, current_user.id, request.recording_ids)

    # Buscar regulación aplicable
    regulation = lookup_limit(
        db,
        municipality=request.municipality,
        zone_type=request.zone_type,
        time_period=request.time_period,
        noise_type=request.noise_type,
    )

    # Descargar audio y calcular hash
    try:
        _, audio_hash = _download_first_audio(recordings)
    except Exception as e:
        logger.warning("No se pudo descargar audio para hash: %s", e)
        audio_hash = None

    # Generar PDF
    pdf_bytes = generate_report(
        recordings=recordings,
        address=request.address,
        floor_door=request.floor_door,
        municipality=request.municipality,
        zone_type=request.zone_type,
        regulation=regulation,
        reporter_name=request.reporter_name,
        audio_hash=audio_hash,
        is_preview=False,
    )

    # Subir PDF a R2
    report_id = uuid.uuid4()
    key = f"{current_user.id}/reports/{report_id}.pdf"
    pdf_file = io.BytesIO(pdf_bytes)
    storage_service.upload_file(pdf_file, key, content_type="application/pdf")

    # Guardar en DB
    report = Report(
        id=report_id,
        user_id=current_user.id,
        recording_ids=[str(rid) for rid in request.recording_ids],
        address=request.address,
        floor_door=request.floor_door,
        zone_type=request.zone_type,
        reporter_name=request.reporter_name,
        file_path=key,
        audio_hash=audio_hash,
        is_preview=False,
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    download_url = storage_service.download_url(key)

    logger.info("Report generado: %s por user %s", report.id, current_user.id)
    return ReportResponse(
        report_id=report.id,
        download_url=download_url,
        created_at=report.created_at,
    )


@router.post("/preview", status_code=status.HTTP_200_OK)
async def preview_report(
    request: ReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Genera un PDF de preview con marca de agua. No se guarda en DB ni R2."""
    from fastapi.responses import Response

    recordings = _fetch_recordings(db, current_user.id, request.recording_ids)

    # Buscar regulación aplicable
    regulation = lookup_limit(
        db,
        municipality=request.municipality,
        zone_type=request.zone_type,
        time_period=request.time_period,
        noise_type=request.noise_type,
    )

    # Generar PDF con marca de agua
    pdf_bytes = generate_report(
        recordings=recordings,
        address=request.address,
        floor_door=request.floor_door,
        municipality=request.municipality,
        zone_type=request.zone_type,
        regulation=regulation,
        reporter_name=request.reporter_name,
        audio_hash=None,
        is_preview=True,
    )

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": "inline; filename=preview_report.pdf"},
    )


@router.get("/", response_model=list[ReportListItem])
async def list_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista todos los informes del usuario autenticado."""
    reports = (
        db.query(Report)
        .filter(Report.user_id == current_user.id, Report.is_preview == False)  # noqa: E712
        .order_by(Report.created_at.desc())
        .all()
    )
    return reports


@router.get("/{report_id}/download")
async def download_report(
    report_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Genera una URL presigned para descargar un informe PDF."""
    report = (
        db.query(Report)
        .filter(Report.id == report_id, Report.user_id == current_user.id)
        .first()
    )
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Informe no encontrado",
        )

    url = storage_service.download_url(report.file_path)
    return {"download_url": url}
