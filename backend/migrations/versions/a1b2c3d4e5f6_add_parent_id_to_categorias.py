"""add_parent_id_to_categorias

Revision ID: a1b2c3d4e5f6
Revises: 9fc01dccf066
Create Date: 2026-06-22 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '14d36c2118e5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('categorias',
        sa.Column('parent_id', sa.UUID(), nullable=True, index=True))
    op.create_foreign_key(
        'categorias_parent_id_fkey', 'categorias', 'categorias',
        ['parent_id'], ['id'])


def downgrade() -> None:
    op.drop_constraint('categorias_parent_id_fkey', 'categorias', type_='foreignkey')
    op.drop_column('categorias', 'parent_id')
