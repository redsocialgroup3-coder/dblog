"""crear tabla reports

Revision ID: a1b2c3d4e5f6
Revises: 555ec97d86f8
Create Date: 2026-03-31

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "555ec97d86f8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("recording_ids", postgresql.JSON(), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("floor_door", sa.String(length=100), nullable=True),
        sa.Column("zone_type", sa.String(length=100), nullable=False),
        sa.Column("reporter_name", sa.String(length=255), nullable=True),
        sa.Column("file_path", sa.String(length=500), nullable=False),
        sa.Column("audio_hash", sa.String(length=64), nullable=True),
        sa.Column("is_preview", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("reports")
