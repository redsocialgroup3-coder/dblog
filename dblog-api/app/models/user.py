from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import Boolean, Float, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin

if TYPE_CHECKING:
    from app.models.recording import Recording


class User(TimestampMixin, Base):
    __tablename__ = "users"

    firebase_uid: Mapped[str] = mapped_column(
        String(128), unique=True, nullable=False, index=True
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    display_name: Mapped[Optional[str]] = mapped_column(String(255))
    address: Mapped[Optional[str]] = mapped_column(String(500))
    floor_door: Mapped[Optional[str]] = mapped_column(String(50))
    municipality: Mapped[Optional[str]] = mapped_column(String(255))
    calibration_offset: Mapped[float] = mapped_column(Float, default=0.0)
    is_subscriber: Mapped[bool] = mapped_column(Boolean, default=False)

    recordings: Mapped[List["Recording"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
