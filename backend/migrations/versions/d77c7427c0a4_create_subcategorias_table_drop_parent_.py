"""create subcategorias table, drop parent_id from categorias

Revision ID: d77c7427c0a4
Revises: a1b2c3d4e5f6
Create Date: 2026-06-22 12:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "d77c7427c0a4"
down_revision: str | None = "a1b2c3d4e5f6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "subcategorias",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("nombre", sa.String(100), nullable=False),
        sa.Column("slug", sa.String(100), nullable=False, index=True, unique=True),
        sa.Column("icono", sa.String(50), nullable=True),
        sa.Column("descripcion", sa.Text(), nullable=True),
        sa.Column("categoria_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("categorias.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    op.execute("""
        INSERT INTO subcategorias (id, nombre, slug, icono, descripcion, categoria_id, created_at, updated_at)
        SELECT id, nombre, slug, icono, descripcion, parent_id, created_at, updated_at
        FROM categorias
        WHERE parent_id IS NOT NULL
    """)

    op.execute("DELETE FROM categorias WHERE parent_id IS NOT NULL")

    op.drop_column("categorias", "parent_id")

    op.add_column("servicios",
        sa.Column("subcategoria_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("subcategorias.id"), nullable=True, index=True)
    )


def downgrade() -> None:
    op.add_column("categorias",
        sa.Column("parent_id", postgresql.UUID(as_uuid=True),
                  sa.ForeignKey("categorias.id"), nullable=True, index=True)
    )

    op.execute("""
        UPDATE categorias c
        SET parent_id = s.categoria_id
        FROM subcategorias s
        WHERE s.id = c.id
    """)

    op.execute("""
        INSERT INTO categorias (id, nombre, slug, icono, descripcion, parent_id, created_at, updated_at)
        SELECT id, nombre, slug, icono, descripcion, categoria_id, created_at, updated_at
        FROM subcategorias
        WHERE id NOT IN (SELECT id FROM categorias)
    """)

    op.drop_column("servicios", "subcategoria_id")

    op.drop_table("subcategorias")
