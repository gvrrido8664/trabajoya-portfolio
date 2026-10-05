"""add metodo_pago and webpay fields to pagos

Revision ID: 9aac9784f64e
Revises: d77c7427c0a4
Create Date: 2026-06-24 19:03:46.403497

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2


# revision identifiers, used by Alembic.
revision: str = '9aac9784f64e'
down_revision: Union[str, Sequence[str], None] = 'd77c7427c0a4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE pagos ADD COLUMN IF NOT EXISTS metodo_pago VARCHAR(20) NOT NULL DEFAULT 'MERCADOPAGO'")
    op.execute("ALTER TABLE pagos ADD COLUMN IF NOT EXISTS webpay_token VARCHAR(255)")
    op.execute("ALTER TABLE pagos ADD COLUMN IF NOT EXISTS webpay_tbk_id VARCHAR(255)")


def downgrade() -> None:
    op.execute("ALTER TABLE pagos DROP COLUMN IF EXISTS webpay_tbk_id")
    op.execute("ALTER TABLE pagos DROP COLUMN IF EXISTS webpay_token")
    op.execute("ALTER TABLE pagos DROP COLUMN IF EXISTS metodo_pago")
