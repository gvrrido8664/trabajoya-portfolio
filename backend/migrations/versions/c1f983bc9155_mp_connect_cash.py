"""mp_connect_cash

Revision ID: c1f983bc9155
Revises: b7c1d2e3f4a5
Create Date: 2026-08-06 13:20:46.098060

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
"""mp_connect_cash

Revision ID: c1f983bc9155
Revises: b7c1d2e3f4a5
Create Date: 2026-08-06 13:20:46.098060

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'c1f983bc9155'
down_revision: Union[str, Sequence[str], None] = 'b7c1d2e3f4a5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Mantener las columnas bancarias heredadas hasta completar una migración
    # explícita de datos; este cambio solo habilita MercadoPago Connect.
    op.execute("ALTER TYPE metodo_pago ADD VALUE IF NOT EXISTS 'ACORDAR_EN_PERSONA'")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_public_key VARCHAR(255)")
    op.execute("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS mp_configured BOOLEAN NOT NULL DEFAULT FALSE")


def downgrade() -> None:
    op.drop_column('usuarios', 'mp_configured')
    op.drop_column('usuarios', 'mp_public_key')
