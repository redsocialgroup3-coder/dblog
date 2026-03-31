import base64
import hashlib
import io
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional

import matplotlib
import matplotlib.pyplot as plt
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML

from app.models.noise_regulation import NoiseRegulation
from app.models.recording import Recording

matplotlib.use("Agg")

logger = logging.getLogger(__name__)

TEMPLATES_DIR = Path(__file__).resolve().parent.parent / "templates"


def _format_duration(seconds: Optional[int]) -> str:
    """Formatea duración en segundos a mm:ss."""
    if seconds is None:
        return "N/A"
    minutes, secs = divmod(seconds, 60)
    return f"{minutes:02d}:{secs:02d}"


def _format_timestamp(ts: datetime) -> str:
    """Formatea timestamp a formato legible."""
    return ts.strftime("%d/%m/%Y %H:%M:%S")


def _format_db(value: Optional[float]) -> str:
    """Formatea valor de dB."""
    if value is None:
        return "N/A"
    return f"{value:.1f}"


def compute_audio_hash(audio_bytes: bytes) -> str:
    """Calcula el hash SHA-256 de los bytes de audio."""
    return hashlib.sha256(audio_bytes).hexdigest()


def generate_chart(recordings: list[Recording]) -> Optional[str]:
    """Genera una gráfica de dB vs tiempo y retorna la imagen como base64 PNG.

    Retorna None si no hay datos suficientes.
    """
    valid = [r for r in recordings if r.avg_db is not None and r.timestamp is not None]
    if not valid:
        return None

    valid.sort(key=lambda r: r.timestamp)

    timestamps = [r.timestamp for r in valid]
    avg_dbs = [r.avg_db for r in valid]
    max_dbs = [r.max_db for r in valid if r.max_db is not None]

    fig, ax = plt.subplots(figsize=(7, 3), dpi=150)

    ax.plot(timestamps, avg_dbs, marker="o", color="#2b6cb0", linewidth=2,
            markersize=5, label="dB Promedio", zorder=3)

    if len(max_dbs) == len(valid):
        max_db_values = [r.max_db for r in valid]
        ax.plot(timestamps, max_db_values, marker="^", color="#c53030",
                linewidth=1.5, markersize=4, label="dB Máximo", linestyle="--", zorder=3)

    ax.set_xlabel("Fecha / Hora", fontsize=9, color="#4a5568")
    ax.set_ylabel("Nivel de ruido (dB)", fontsize=9, color="#4a5568")
    ax.set_title("Evolución del nivel de ruido", fontsize=11, color="#1a365d", fontweight="bold")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)
    ax.tick_params(axis="both", labelsize=8)

    fig.autofmt_xdate(rotation=30)
    fig.tight_layout()

    buf = io.BytesIO()
    fig.savefig(buf, format="png", bbox_inches="tight")
    plt.close(fig)
    buf.seek(0)

    return base64.b64encode(buf.read()).decode("utf-8")


def _get_verdict_info(
    avg_db: float, regulation: Optional[NoiseRegulation]
) -> tuple[str, str, float]:
    """Retorna (verdict_text, verdict_class, difference_db)."""
    if regulation is None:
        return ("SIN DATOS NORMATIVOS", "", 0.0)

    diff = round(avg_db - regulation.db_limit, 1)

    if avg_db > regulation.db_limit:
        return ("SUPERA EL LÍMITE", "supera", diff)
    elif avg_db >= regulation.db_limit - 5.0:
        return ("CERCANO AL LÍMITE", "cercano", diff)
    else:
        return ("NO SUPERA EL LÍMITE", "no-supera", diff)


def generate_report(
    recordings: list[Recording],
    address: str,
    floor_door: Optional[str],
    municipality: str,
    zone_type: str,
    regulation: Optional[NoiseRegulation],
    reporter_name: Optional[str] = None,
    audio_hash: Optional[str] = None,
    is_preview: bool = False,
) -> bytes:
    """Genera un informe PDF completo y retorna los bytes del PDF."""
    env = Environment(loader=FileSystemLoader(str(TEMPLATES_DIR)))
    template = env.get_template("report.html")

    # Preparar datos de mediciones para el template
    recording_data = []
    total_avg = 0.0
    count_avg = 0
    for r in recordings:
        recording_data.append({
            "timestamp": _format_timestamp(r.timestamp),
            "duration": _format_duration(r.duration_seconds),
            "avg_db": _format_db(r.avg_db),
            "max_db": _format_db(r.max_db),
        })
        if r.avg_db is not None:
            total_avg += r.avg_db
            count_avg += 1

    measured_db = round(total_avg / count_avg, 1) if count_avg > 0 else 0.0

    # Generar gráfica
    chart_image = generate_chart(recordings)

    # Calcular veredicto
    verdict_text, verdict_class, difference_db = _get_verdict_info(measured_db, regulation)

    # Preparar datos de regulación para el template
    reg_data = None
    if regulation:
        reg_data = {
            "regulation_name": regulation.regulation_name,
            "article": regulation.article,
            "db_limit": regulation.db_limit,
            "time_period": regulation.time_period,
        }

    context = {
        "address": address,
        "floor_door": floor_door,
        "municipality": municipality,
        "zone_type": zone_type,
        "reporter_name": reporter_name,
        "recordings": recording_data,
        "chart_image": chart_image,
        "regulation": reg_data,
        "verdict_text": verdict_text,
        "verdict_class": verdict_class,
        "measured_db": measured_db,
        "difference_db": difference_db,
        "audio_hash": audio_hash,
        "is_preview": is_preview,
        "generation_date": datetime.now().strftime("%d/%m/%Y a las %H:%M:%S"),
        "app_version": "0.1.0",
    }

    html_content = template.render(**context)
    pdf_bytes = HTML(string=html_content).write_pdf()

    logger.info(
        "PDF generado: %d recordings, preview=%s, %d bytes",
        len(recordings), is_preview, len(pdf_bytes),
    )

    return pdf_bytes
