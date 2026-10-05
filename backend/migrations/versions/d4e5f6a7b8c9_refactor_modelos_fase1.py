"""refactor_modelos_fase1

Revision ID: d4e5f6a7b8c9
Revises: e672bf5cf4af
Create Date: 2026-06-17 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, Sequence[str], None] = 'e672bf5cf4af'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- bug_reportes (new table) ---
    op.create_table('bug_reportes',
        sa.Column('usuario_id', sa.UUID(), nullable=False, index=True),
        sa.Column('titulo', sa.String(200), nullable=False),
        sa.Column('descripcion', sa.Text(), nullable=False),
        sa.Column('area', sa.Enum('DISENO', 'FUNCION', 'LOGICA', 'OTRO', name='area_bug'), nullable=False),
        sa.Column('status', sa.Enum('ABIERTO', 'EN_PROCESO', 'RESUELTO', name='estado_bug'), nullable=False),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['usuario_id'], ['usuarios.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # --- usuario: drop columns ---
    op.drop_constraint('usuarios_referido_por_fkey', 'usuarios', type_='foreignkey')
    op.drop_index('ix_usuarios_codigo_referido', table_name='usuarios')
    op.drop_column('usuarios', 'email_verificado')
    op.drop_column('usuarios', 'ultima_conexion')
    op.drop_column('usuarios', 'referido_por')

    # --- categoria: drop parent_id ---
    op.drop_index('ix_categorias_parent_id', table_name='categorias')
    op.drop_column('categorias', 'parent_id')

    # --- servicio: fotos Text -> ARRAY(Text), add es_destacado ---
    op.execute("ALTER TABLE servicios ALTER COLUMN fotos TYPE text[] USING string_to_array(fotos, ',')::text[]")
    op.add_column('servicios', sa.Column('es_destacado', sa.Boolean(), server_default='false', nullable=False))

    # --- contratacion: recreate enum using UPPERCASE names (SQLAlchemy default) ---
    op.execute("CREATE TYPE estado_contratacion_new AS ENUM('PENDIENTE', 'ACEPTADO', 'RECHAZADO', 'COMPLETADO', 'CANCELADO', 'DISPUTA')")
    op.execute("""ALTER TABLE contrataciones ALTER COLUMN status TYPE estado_contratacion_new
USING CASE status::text
  WHEN 'en_progreso' THEN 'COMPLETADO'::estado_contratacion_new
  WHEN 'pagado_en_garantia' THEN 'PENDIENTE'::estado_contratacion_new
  ELSE upper(status::text)::estado_contratacion_new
END""")
    op.execute("DROP TYPE estado_contratacion")
    op.execute("ALTER TYPE estado_contratacion_new RENAME TO estado_contratacion")

    # --- pago: drop columns, rename preference_id, add mp_payment_id, recreate enum ---
    op.drop_column('pagos', 'cliente_id')
    op.drop_column('pagos', 'proveedor_id')
    op.drop_column('pagos', 'fee_plataforma')
    op.drop_column('pagos', 'monto_neto')
    op.drop_column('pagos', 'gateway')
    op.drop_column('pagos', 'gateway_payment_id')
    op.alter_column('pagos', 'gateway_preference_id', new_column_name='preference_id')
    op.add_column('pagos', sa.Column('mp_payment_id', sa.String(255), nullable=True))
    op.execute("CREATE TYPE estado_pago_new AS ENUM('PENDIENTE', 'APROBADO', 'RECHAZADO', 'CANCELADO')")
    op.execute("""ALTER TABLE pagos ALTER COLUMN status TYPE estado_pago_new
USING CASE status::text
  WHEN 'liberado' THEN 'APROBADO'::estado_pago_new
  WHEN 'reembolsado' THEN 'CANCELADO'::estado_pago_new
  ELSE upper(status::text)::estado_pago_new
END""")
    op.execute("DROP TYPE estado_pago")
    op.execute("ALTER TYPE estado_pago_new RENAME TO estado_pago")

    # --- plan: drop slug, precio_anual, features; add descripcion, beneficios ---
    op.drop_constraint('planes_slug_key', 'planes', type_='unique')
    op.drop_column('planes', 'slug')
    op.drop_column('planes', 'precio_anual')
    op.drop_column('planes', 'features')
    op.add_column('planes', sa.Column('descripcion', sa.Text(), nullable=True))
    op.add_column('planes', sa.Column('beneficios', postgresql.ARRAY(sa.String()), nullable=True))

    # --- suscripcion: rename proveedor_id -> usuario_id, fecha_fin -> fecha_vencimiento, drop gateway, recreate enum ---
    op.drop_constraint('suscripciones_proveedor_id_fkey', 'suscripciones', type_='foreignkey')
    op.drop_index('ix_suscripciones_proveedor_id', table_name='suscripciones')
    op.alter_column('suscripciones', 'proveedor_id', new_column_name='usuario_id')
    op.create_index('ix_suscripciones_usuario_id', 'suscripciones', ['usuario_id'])
    op.create_foreign_key('suscripciones_usuario_id_fkey', 'suscripciones', 'usuarios', ['usuario_id'], ['id'])
    op.alter_column('suscripciones', 'fecha_fin', new_column_name='fecha_vencimiento')
    op.drop_column('suscripciones', 'gateway_subscription_id')
    op.drop_column('suscripciones', 'gateway_payment_id')
    op.execute("CREATE TYPE estado_suscripcion_new AS ENUM('ACTIVA', 'CANCELADA', 'VENCIDA')")
    op.execute("""ALTER TABLE suscripciones ALTER COLUMN status TYPE estado_suscripcion_new
USING CASE status::text
  WHEN 'expirada' THEN 'VENCIDA'::estado_suscripcion_new
  WHEN 'pendiente' THEN 'ACTIVA'::estado_suscripcion_new
  ELSE upper(status::text)::estado_suscripcion_new
END""")
    op.execute("DROP TYPE estado_suscripcion")
    op.execute("ALTER TYPE estado_suscripcion_new RENAME TO estado_suscripcion")

    # --- disputa: rename abridor_id -> abierta_por_id, drop evidencias, add action_tomada, resolved_at, recreate enum ---
    op.drop_constraint('disputas_abridor_id_fkey', 'disputas', type_='foreignkey')
    op.alter_column('disputas', 'abridor_id', new_column_name='abierta_por_id')
    op.create_foreign_key('disputas_abierta_por_id_fkey', 'disputas', 'usuarios', ['abierta_por_id'], ['id'])
    op.drop_column('disputas', 'evidencias')
    op.add_column('disputas', sa.Column('action_tomada', sa.String(50), nullable=True))
    op.add_column('disputas', sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True))
    op.execute("CREATE TYPE estado_disputa_new AS ENUM('ABIERTA', 'RESUELTA')")
    op.execute("""ALTER TABLE disputas ALTER COLUMN status TYPE estado_disputa_new
USING CASE status::text
  WHEN 'en_revision' THEN 'ABIERTA'::estado_disputa_new
  ELSE upper(status::text)::estado_disputa_new
END""")
    op.execute("DROP TYPE estado_disputa")
    op.execute("ALTER TYPE estado_disputa_new RENAME TO estado_disputa")


def downgrade() -> None:
    # --- bug_reportes: revert ---
    op.drop_table('bug_reportes')

    # --- usuario: revert ---
    op.add_column('usuarios', sa.Column('referido_por', sa.UUID(), nullable=True))
    op.add_column('usuarios', sa.Column('ultima_conexion', sa.DateTime(timezone=True), nullable=True))
    op.add_column('usuarios', sa.Column('email_verificado', sa.Boolean(), nullable=False))
    op.create_index('ix_usuarios_codigo_referido', 'usuarios', ['codigo_referido'])
    op.create_foreign_key('usuarios_referido_por_fkey', 'usuarios', 'usuarios', ['referido_por'], ['id'])

    # --- categoria: revert ---
    op.add_column('categorias', sa.Column('parent_id', sa.UUID(), nullable=True))
    op.create_index('ix_categorias_parent_id', 'categorias', ['parent_id'])

    # --- servicio: revert ---
    op.drop_column('servicios', 'es_destacado')
    op.execute("ALTER TABLE servicios ALTER COLUMN fotos TYPE text USING fotos::text")

    # --- contratacion: revert enum to original ---
    op.execute("CREATE TYPE estado_contratacion_old AS ENUM('PENDIENTE', 'ACEPTADO', 'RECHAZADO', 'EN_PROGRESO', 'COMPLETADO', 'CANCELADO', 'PAGADO_EN_GARANTIA')")
    op.execute("ALTER TABLE contrataciones ALTER COLUMN status TYPE estado_contratacion_old USING upper(status::text)::estado_contratacion_old")
    op.execute("DROP TYPE estado_contratacion")
    op.execute("ALTER TYPE estado_contratacion_old RENAME TO estado_contratacion")

    # --- pago: revert ---
    op.drop_column('pagos', 'mp_payment_id')
    op.alter_column('pagos', 'preference_id', new_column_name='gateway_preference_id')
    op.add_column('pagos', sa.Column('gateway_payment_id', sa.String(255), nullable=True))
    op.add_column('pagos', sa.Column('gateway', sa.String(50), nullable=False))
    op.add_column('pagos', sa.Column('monto_neto', sa.Float(), nullable=False))
    op.add_column('pagos', sa.Column('fee_plataforma', sa.Float(), nullable=False))
    op.add_column('pagos', sa.Column('proveedor_id', sa.UUID(), nullable=False))
    op.add_column('pagos', sa.Column('cliente_id', sa.UUID(), nullable=False))
    op.execute("CREATE TYPE estado_pago_old AS ENUM('PENDIENTE', 'APROBADO', 'RECHAZADO', 'LIBERADO', 'REEMBOLSADO')")
    op.execute("ALTER TABLE pagos ALTER COLUMN status TYPE estado_pago_old USING upper(status::text)::estado_pago_old")
    op.execute("DROP TYPE estado_pago")
    op.execute("ALTER TYPE estado_pago_old RENAME TO estado_pago")

    # --- plan: revert ---
    op.drop_column('planes', 'beneficios')
    op.drop_column('planes', 'descripcion')
    op.add_column('planes', sa.Column('features', sa.String(1000), nullable=False))
    op.add_column('planes', sa.Column('precio_anual', sa.Float(), nullable=False))
    op.add_column('planes', sa.Column('slug', sa.String(100), nullable=False))
    op.create_unique_constraint('planes_slug_key', 'planes', ['slug'])

    # --- suscripcion: revert ---
    op.add_column('suscripciones', sa.Column('gateway_payment_id', sa.String(255), nullable=True))
    op.add_column('suscripciones', sa.Column('gateway_subscription_id', sa.String(255), nullable=True))
    op.alter_column('suscripciones', 'fecha_vencimiento', new_column_name='fecha_fin')
    op.drop_constraint('suscripciones_usuario_id_fkey', 'suscripciones', type_='foreignkey')
    op.drop_index('ix_suscripciones_usuario_id', table_name='suscripciones')
    op.alter_column('suscripciones', 'usuario_id', new_column_name='proveedor_id')
    op.create_index('ix_suscripciones_proveedor_id', 'suscripciones', ['proveedor_id'])
    op.create_foreign_key('suscripciones_proveedor_id_fkey', 'suscripciones', 'usuarios', ['proveedor_id'], ['id'])
    op.execute("CREATE TYPE estado_suscripcion_old AS ENUM('ACTIVA', 'CANCELADA', 'EXPIRADA', 'PENDIENTE')")
    op.execute("ALTER TABLE suscripciones ALTER COLUMN status TYPE estado_suscripcion_old USING upper(status::text)::estado_suscripcion_old")
    op.execute("DROP TYPE estado_suscripcion")
    op.execute("ALTER TYPE estado_suscripcion_old RENAME TO estado_suscripcion")

    # --- disputa: revert ---
    op.execute("CREATE TYPE estado_disputa_old AS ENUM('ABIERTA', 'EN_REVISION', 'RESUELTA')")
    op.execute("ALTER TABLE disputas ALTER COLUMN status TYPE estado_disputa_old USING upper(status::text)::estado_disputa_old")
    op.execute("DROP TYPE estado_disputa")
    op.execute("ALTER TYPE estado_disputa_old RENAME TO estado_disputa")
    op.drop_column('disputas', 'resolved_at')
    op.drop_column('disputas', 'action_tomada')
    op.add_column('disputas', sa.Column('evidencias', sa.Text(), nullable=True))
    op.drop_constraint('disputas_abierta_por_id_fkey', 'disputas', type_='foreignkey')
    op.alter_column('disputas', 'abierta_por_id', new_column_name='abridor_id')
    op.create_foreign_key('disputas_abridor_id_fkey', 'disputas', 'usuarios', ['abridor_id'], ['id'])
