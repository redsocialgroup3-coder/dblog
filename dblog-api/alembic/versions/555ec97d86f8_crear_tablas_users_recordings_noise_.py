"""crear tablas users recordings noise_regulations

Revision ID: 555ec97d86f8
Revises:
Create Date: 2026-03-31

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "555ec97d86f8"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("firebase_uid", sa.String(length=128), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=True),
        sa.Column("floor_door", sa.String(length=50), nullable=True),
        sa.Column("municipality", sa.String(length=255), nullable=True),
        sa.Column("calibration_offset", sa.Float(), nullable=True),
        sa.Column("is_subscriber", sa.Boolean(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
        sa.UniqueConstraint("firebase_uid"),
    )
    op.create_index(op.f("ix_users_firebase_uid"), "users", ["firebase_uid"])

    op.create_table(
        "recordings",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("file_path", sa.String(length=500), nullable=False),
        sa.Column("file_name", sa.String(length=255), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("avg_db", sa.Float(), nullable=True),
        sa.Column("max_db", sa.Float(), nullable=True),
        sa.Column("duration_seconds", sa.Integer(), nullable=True),
        sa.Column("metadata_json", postgresql.JSON(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "noise_regulations",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("municipality", sa.String(length=255), nullable=False),
        sa.Column("zone_type", sa.String(length=100), nullable=False),
        sa.Column("time_period", sa.String(length=50), nullable=False),
        sa.Column("noise_type", sa.String(length=100), nullable=False),
        sa.Column("db_limit", sa.Float(), nullable=False),
        sa.Column("regulation_name", sa.String(length=500), nullable=True),
        sa.Column("article", sa.String(length=100), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_noise_regulations_municipality"),
        "noise_regulations",
        ["municipality"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_noise_regulations_municipality"), table_name="noise_regulations"
    )
    op.drop_table("noise_regulations")
    op.drop_table("recordings")
    op.drop_index(op.f("ix_users_firebase_uid"), table_name="users")
    op.drop_table("users")
