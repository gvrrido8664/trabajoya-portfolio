-- ============================================================
-- Migración manual Supabase: capacidades por rol (2026-07-13)
-- Equivalente a la revisión Alembic b7c1d2e3f4a5_capacidades_por_rol.
-- Idempotente: se puede ejecutar más de una vez sin daño.
-- Aditiva: el backend desplegado que ignora estas columnas sigue funcionando.
-- ============================================================

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS es_cliente BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS es_proveedor BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS proveedor_activado_at TIMESTAMPTZ NULL;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS avg_rating_proveedor DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS avg_rating_cliente DOUBLE PRECISION NOT NULL DEFAULT 0;

-- Backfill capacidades: proveedores existentes quedan grandfathered.
-- Nota: el enum rol_usuario guarda las etiquetas en MAYÚSCULAS (CLIENTE/PROVEEDOR/ADMIN),
-- no el .value en minúsculas que usa el ORM de Python.
UPDATE usuarios SET es_proveedor = TRUE WHERE rol = 'PROVEEDOR' AND NOT es_proveedor;

-- Backfill ratings por rol (contexto derivado por join con contrataciones).
UPDATE usuarios u SET avg_rating_proveedor = s.avg
FROM (SELECT r.calificado_id, ROUND(AVG(r.puntuacion)::numeric, 2) AS avg
      FROM resenas r JOIN contrataciones c ON c.id = r.contratacion_id
      WHERE r.calificado_id = c.proveedor_id GROUP BY r.calificado_id) s
WHERE u.id = s.calificado_id;

UPDATE usuarios u SET avg_rating_cliente = s.avg
FROM (SELECT r.calificado_id, ROUND(AVG(r.puntuacion)::numeric, 2) AS avg
      FROM resenas r JOIN contrataciones c ON c.id = r.contratacion_id
      WHERE r.calificado_id = c.cliente_id GROUP BY r.calificado_id) s
WHERE u.id = s.calificado_id;

-- ============================================================
-- Verificación (deben devolver 0 filas / 0):
-- ============================================================
-- Todo proveedor legacy tiene la capacidad:
SELECT count(*) AS proveedores_sin_capacidad
FROM usuarios WHERE rol = 'PROVEEDOR' AND NOT es_proveedor;

-- Paridad de backfill de rating proveedor (desviaciones):
SELECT count(*) AS desviaciones_rating_proveedor
FROM usuarios u
JOIN (SELECT r.calificado_id, ROUND(AVG(r.puntuacion)::numeric, 2) AS avg
      FROM resenas r JOIN contrataciones c ON c.id = r.contratacion_id
      WHERE r.calificado_id = c.proveedor_id GROUP BY r.calificado_id) s
  ON u.id = s.calificado_id
WHERE u.avg_rating_proveedor <> s.avg;
