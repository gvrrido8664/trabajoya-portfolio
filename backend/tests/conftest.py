"""
Fixtures compartidos para tests de integración.
Usa conexiones aisladas para evitar conflictos de loops async.
"""
import uuid
import os
from sqlalchemy.engine import make_url

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings
from app.core.security import create_access_token, hash_password
from app.database import Base, get_db
from app.main import app
from app.models import RolUsuario, Usuario


@pytest.fixture(scope="session")
def test_db_url():
    url = os.environ.get('TEST_DATABASE_URL', '')
    parsed = make_url(url)
    if parsed.host not in {'127.0.0.1','localhost','db'} or parsed.database != 'trabajoya_demo':
        raise RuntimeError('Las pruebas necesitan TEST_DATABASE_URL local con base trabajoya_demo')
    return url


@pytest_asyncio.fixture(scope="function")
async def test_engine(test_db_url):
    """Engine aislado por test para evitar conflictos de loop."""
    engine = create_async_engine(test_db_url, echo=False)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def db_session(test_engine):
    """Sesión de BD con rollback automático al final del test."""
    async_session_factory = async_sessionmaker(
        test_engine, class_=AsyncSession, expire_on_commit=False
    )
    async with test_engine.connect() as conn:
        await conn.begin()
        async with async_session_factory(bind=conn) as session:
            await conn.begin_nested()

            @event.listens_for(session.sync_session, "after_transaction_end")
            def end_savepoint(session, transaction):
                if conn.closed:
                    return
                if not conn.in_nested_transaction():
                    conn.sync_connection.begin_nested()

            yield session
            await conn.rollback()


@pytest_asyncio.fixture(scope="function")
async def client(db_session):
    """Cliente HTTP con override de BD."""
    async def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture(scope="function")
async def usuario_cliente(db_session) -> Usuario:
    user = Usuario(
        email=f"tc_{uuid.uuid4().hex[:8]}@test.com",
        password_hash=await hash_password("test123"),
        nombre="Test",
        apellido="Cliente",
        rol=RolUsuario.CLIENTE,
        is_verified=True,
    )
    db_session.add(user)
    await db_session.flush()
    return user


@pytest_asyncio.fixture(scope="function")
async def usuario_proveedor(db_session) -> Usuario:
    user = Usuario(
        email=f"tp_{uuid.uuid4().hex[:8]}@test.com",
        password_hash=await hash_password("test123"),
        nombre="Test",
        apellido="Proveedor",
        rol=RolUsuario.PROVEEDOR,
        es_proveedor=True,
        is_verified=True,
        doc_estado="approved",
    )
    db_session.add(user)
    await db_session.flush()
    return user


@pytest_asyncio.fixture(scope="function")
def auth_headers(usuario_cliente):
    token = create_access_token(str(usuario_cliente.id))
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture(scope="function")
def auth_headers_proveedor(usuario_proveedor):
    token = create_access_token(str(usuario_proveedor.id))
    return {"Authorization": f"Bearer {token}"}
