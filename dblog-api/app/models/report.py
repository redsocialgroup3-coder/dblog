import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    recording_ids: Mapped[list] = mapped_column(JSON, nullable=False)
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    floor_door: Mapped[Optional[str]] = mapped_column(String(100))
    zone_type: Mapped[str] = mapped_column(String(100), nullable=False)
    reporter_name: Mapped[Optional[str]] = mapped_column(String(255))
    file_path: Mapped[str] = mapped_column(String(500), nullable=False)
    audio_hash: Mapped[Optional[str]] = mapped_column(String(64))
    is_preview: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
