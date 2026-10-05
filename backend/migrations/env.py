import asyncio
import os
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

from app.database import Base
from app.models import *  # noqa: F401, F403 - ensure all models are loaded
from app.core.config import settings

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = settings.DATABASE_URL
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def include_name(name, type_, parent_names):
    """Excluye tablas internas de PostGIS/tiger del versionado."""
    if type_ == "table":
        return name not in (
            "spatial_ref_sys", "topology", "layer",
            "geocode_settings", "geocode_settings_default",
            "loader_lookuptables", "loader_platform", "loader_variables",
            "pagc_rules", "pagc_gaz", "pagc_lex",
            "zip_lookup", "zip_lookup_all", "zip_lookup_base",
            "zip_state", "zip_state_loc",
            "county", "county_lookup", "countysub_lookup",
            "state", "state_lookup",
            "place", "place_lookup",
            "cousub", "tract", "tabblock", "tabblock20",
            "bg", "zcta5",
            "addr", "addrfeat",
            "edges", "faces", "featnames",
            "direction_lookup", "secondary_unit_lookup", "street_type_lookup",
        )
    return True


def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        include_name=include_name,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    connectable = create_async_engine(settings.DATABASE_URL, poolclass=pool.NullPool)
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
