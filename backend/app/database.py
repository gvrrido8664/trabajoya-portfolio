from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=20,
    max_overflow=10,
    # /health no toca la BD, así que las conexiones del pool se quedan ociosas y
    # Supabase las cierra; sin estos dos parámetros SQLAlchemy entregaba una
    # conexión muerta y el primer request tras inactividad daba 500 (y recién el
    # siguiente se recuperaba). pool_pre_ping verifica la conexión antes de usarla
    # (reemplaza la muerta de forma transparente) y pool_recycle la renueva antes
    # de que el servidor la cierre por timeout.
    pool_pre_ping=True,
    pool_recycle=300,
    connect_args={"ssl": "require"} if settings.DB_REQUIRE_SSL else {},
)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()
