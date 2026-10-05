"""Add bank fields and payout

Revision ID: fe08b09ec9f3
Revises: f1a2b3c4d5e6
Create Date: 2026-06-30 18:38:27.829461

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2


# revision identifiers, used by Alembic.
revision: str = 'fe08b09ec9f3'
down_revision: Union[str, Sequence[str], None] = 'f1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS bank_rut VARCHAR(20);")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS bank_name VARCHAR(64);")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(32);")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS bank_account_type VARCHAR(16);")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS bank_configured BOOLEAN NOT NULL DEFAULT FALSE;")
    op.execute("ALTER TABLE pagos ADD COLUMN IF NOT EXISTS payout_status VARCHAR(16);")
    op.execute("ALTER TABLE pagos ADD COLUMN IF NOT EXISTS fintoc_transfer_id VARCHAR(128);")


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("ALTER TABLE pagos DROP COLUMN IF EXISTS fintoc_transfer_id;")
    op.execute("ALTER TABLE pagos DROP COLUMN IF EXISTS payout_status;")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS bank_configured;")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS bank_account_type;")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS bank_account_number;")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS bank_name;")
    op.execute("ALTER TABLE usuarios DROP COLUMN IF EXISTS bank_rut;")
