# Backend TrabajoYa
FastAPI, SQLAlchemy, PostgreSQL/PostGIS, JWT y WebSockets. Configuración, demo sintética, límites de pagos y estado de comprobaciones: [README principal](../README.md).

Entradas: `app/main.py`, modelos `app/models`, rutas `app/api`, migraciones `migrations`. `compose.demo.yml` incorpora PostgreSQL/PostGIS local; el antiguo `docker-compose.yml` no contenía esa base. La demo genera el esquema desde los modelos actuales en una base nueva; no valida la cadena histórica de migraciones Alembic.

DB_REQUIRE_SSL conserva true por defecto; únicamente el entorno local de Compose lo desactiva. Los scripts auxiliares con acceso a bases reales se retiraron de la copia de portafolio. No ejecutes los seeds legacy sobre una base de producción.
