"""allow_mutual_reviews

Revision ID: fe723ffe8d3b
Revises: fe08b09ec9f3
Create Date: 2026-07-01 01:47:28.228390

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
import geoalchemy2


# revision identifiers, used by Alembic.
revision: str = 'fe723ffe8d3b'
down_revision: Union[str, Sequence[str], None] = 'fe08b09ec9f3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Drop old unique constraint on contratacion_id
    op.drop_constraint('resenas_contratacion_id_key', 'resenas', type_='unique')
    # Add new composite unique constraint
    op.create_unique_constraint('uix_resena_contratacion_calificador', 'resenas', ['contratacion_id', 'calificador_id'])


def downgrade() -> None:
    """Downgrade schema."""
    # Revert to old unique constraint
    op.drop_constraint('uix_resena_contratacion_calificador', 'resenas', type_='unique')
    op.create_unique_constraint('resenas_contratacion_id_key', 'resenas', ['contratacion_id'])
