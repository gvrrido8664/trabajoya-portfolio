"""capacidades_por_rol

Identidad única con capacidades: es_cliente/es_proveedor + ratings por rol.
Aditiva y reversible. El campo legacy `rol` se conserva poblado (rol primario).

Revision ID: b7c1d2e3f4a5
Revises: fe723ffe8d3b
Create Date: 2026-07-13

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7c1d2e3f4a5'
down_revision: Union[str, Sequence[str], None] = 'fe723ffe8d3b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('usuarios', sa.Column('es_cliente', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('usuarios', sa.Column('es_proveedor', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('usuarios', sa.Column('proveedor_activado_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('usuarios', sa.Column('avg_rating_proveedor', sa.Float(), nullable=False, server_default='0'))
    op.add_column('usuarios', sa.Column('avg_rating_cliente', sa.Float(), nullable=False, server_default='0'))

    # Backfill capacidades: proveedores existentes quedan grandfathered
    # (tener rol proveedor nunca exigió doc aprobado; publicar servicios sí lo sigue exigiendo).
    # Nota: el enum rol_usuario guarda las etiquetas en MAYÚSCULAS (CLIENTE/PROVEEDOR/ADMIN).
    op.execute("UPDATE usuarios SET es_proveedor = TRUE WHERE rol = 'PROVEEDOR'")

    # Backfill ratings por rol, derivando el contexto por join con contrataciones.
    op.execute(
        """
        UPDATE usuarios u SET avg_rating_proveedor = s.avg
        FROM (SELECT r.calificado_id, ROUND(AVG(r.puntuacion)::numeric, 2) AS avg
              FROM resenas r JOIN contrataciones c ON c.id = r.contratacion_id
              WHERE r.calificado_id = c.proveedor_id GROUP BY r.calificado_id) s
        WHERE u.id = s.calificado_id
        """
    )
    op.execute(
        """
        UPDATE usuarios u SET avg_rating_cliente = s.avg
        FROM (SELECT r.calificado_id, ROUND(AVG(r.puntuacion)::numeric, 2) AS avg
              FROM resenas r JOIN contrataciones c ON c.id = r.contratacion_id
              WHERE r.calificado_id = c.cliente_id GROUP BY r.calificado_id) s
        WHERE u.id = s.calificado_id
        """
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('usuarios', 'avg_rating_cliente')
    op.drop_column('usuarios', 'avg_rating_proveedor')
    op.drop_column('usuarios', 'proveedor_activado_at')
    op.drop_column('usuarios', 'es_proveedor')
    op.drop_column('usuarios', 'es_cliente')
