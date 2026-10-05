"""add mp connect fields to usuarios

Revision ID: f1a2b3c4d5e6
Revises: 94cdf695182f
Create Date: 2026-06-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'f1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = '94cdf695182f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_user_id VARCHAR(64)")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_access_token TEXT")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_refresh_token TEXT")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_connected BOOLEAN NOT NULL DEFAULT FALSE")


def downgrade() -> None:
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS mp_connected")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS mp_refresh_token")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS mp_access_token")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS mp_user_id")
