import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, Float, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class NoiseRegulation(Base):
    __tablename__ = "noise_regulations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    municipality: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    zone_type: Mapped[str] = mapped_column(String(100), nullable=False)
    time_period: Mapped[str] = mapped_column(String(50), nullable=False)
    noise_type: Mapped[str] = mapped_column(String(100), nullable=False)
    db_limit: Mapped[float] = mapped_column(Float, nullable=False)
    regulation_name: Mapped[Optional[str]] = mapped_column(String(500))
    article: Mapped[Optional[str]] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
