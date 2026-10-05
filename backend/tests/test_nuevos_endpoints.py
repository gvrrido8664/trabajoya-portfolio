"""Tests para endpoints nuevos: destacar, oportunidades, top proveedores, bugs."""
import uuid

import pytest
from httpx import AsyncClient


@pytest.fixture
async def categoria(db_session):
    from app.models import Categoria
    cat = Categoria(nombre="Test Cat", slug="test-cat", icono="🧪")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)
    return cat


@pytest.fixture
async def servicio_activo(db_session, usuario_proveedor, categoria):
    from app.models import EstadoServicio, Servicio
    serv = Servicio(
        proveedor_id=usuario_proveedor.id,
        categoria_id=categoria.id,
        titulo="Servicio test contratación",
        descripcion="Descripción de prueba",
        precio_min=10000,
        precio_max=50000,
        status=EstadoServicio.ACTIVO,
        radio_cobertura_km=10,
    )
    db_session.add(serv)
    await db_session.commit()
    await db_session.refresh(serv)
    return serv


class TestServiciosDestacar:

    async def test_destacar_servicio(self, client: AsyncClient, auth_headers_proveedor, categoria):
        # Crear servicio
        create = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Destacar test",
            "descripcion": "Test",
        })
        serv_id = create.json()["id"]
        assert create.json()["es_destacado"] is False

        # Destacar
        res = await client.post(f"/api/v1/servicios/{serv_id}/destacar", headers=auth_headers_proveedor)
        assert res.status_code == 200
        assert res.json()["es_destacado"] is True

        # Quitar destacado
        res2 = await client.post(f"/api/v1/servicios/{serv_id}/destacar", headers=auth_headers_proveedor)
        assert res2.status_code == 200
        assert res2.json()["es_destacado"] is False

    async def test_destacar_servicio_ajeno(self, client: AsyncClient, auth_headers_proveedor, categoria):
        create = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Ajeno",
            "descripcion": "No debe poder destacarlo otro",
        })
        serv_id = create.json()["id"]

        # Otro proveedor intenta destacar (re-registramos)
        import uuid as _uuid
        otro_email = f"otroprov_{_uuid.uuid4().hex[:8]}@test.com"
        await client.post("/api/v1/auth/register", json={
            "email": otro_email, "password": "test1234",
            "nombre": "Otro", "apellido": "Prov", "rol": "proveedor",
        })
        login = await client.post("/api/v1/auth/login", json={
            "email": otro_email, "password": "test1234",
        })
        otro_token = login.json()["access_token"]

        res = await client.post(
            f"/api/v1/servicios/{serv_id}/destacar",
            headers={"Authorization": f"Bearer {otro_token}"},
        )
        assert res.status_code == 403


class TestOportunidades:

    async def test_listar_oportunidades(self, client: AsyncClient, auth_headers, auth_headers_proveedor, categoria):
        # Crear solicitud abierta
        await client.post("/api/v1/solicitudes", headers=auth_headers, json={
            "categoria_id": str(categoria.id),
            "titulo": "Necesito Gasfiter",
            "descripcion": "Se rompio una cañeria",
            "presupuesto_max": 30000,
            "ubicacion_texto": "Santiago, Chile",
        })

        res = await client.get("/api/v1/oportunidades")
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["presupuesto_max"] == 30000


class TestTopProveedores:

    async def test_top_proveedores(self, client: AsyncClient, usuario_proveedor):
        res = await client.get("/api/v1/proveedores/top")
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, list)


class TestBugs:

    async def test_reportar_bug(self, client: AsyncClient, auth_headers):
        res = await client.post("/api/v1/bugs", headers=auth_headers, json={
            "titulo": "Error en login",
            "descripcion": "No funciona el login",
            "area": "FUNCION",
        })
        assert res.status_code == 201
        data = res.json()
        assert data["titulo"] == "Error en login"
        assert data["status"] == "ABIERTO"

    async def test_listar_mis_bugs(self, client: AsyncClient, auth_headers):
        await client.post("/api/v1/bugs", headers=auth_headers, json={
            "titulo": "Bug 1", "descripcion": "Test", "area": "DISENO",
        })

        res = await client.get("/api/v1/bugs/mis-reportes", headers=auth_headers)
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, list)
        assert len(data) >= 1

    async def test_bug_sin_auth(self, client: AsyncClient):
        res = await client.post("/api/v1/bugs", json={
            "titulo": "Sin auth", "descripcion": "No debe crearse", "area": "otro",
        })
        assert res.status_code == 401
