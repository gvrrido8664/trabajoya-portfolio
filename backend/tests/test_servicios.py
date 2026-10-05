"""Tests de servicios y búsqueda geoespacial."""
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


class TestServicios:
    """Suite de tests para endpoints de servicios."""

    async def test_crear_servicio(self, client: AsyncClient, auth_headers_proveedor, categoria):
        res = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Servicio de prueba",
            "descripcion": "Descripción del servicio de prueba",
            "precio_min": 10000,
            "precio_max": 50000,
            "radio_cobertura_km": 10,
        })
        assert res.status_code == 201
        data = res.json()
        assert data["titulo"] == "Servicio de prueba"
        assert data["status"] == "ACTIVO"

    async def test_crear_servicio_sin_auth(self, client: AsyncClient, categoria):
        res = await client.post("/api/v1/servicios", json={
            "categoria_id": str(categoria.id),
            "titulo": "Sin auth",
            "descripcion": "No debería crearse",
        })
        assert res.status_code == 401

    async def test_crear_servicio_como_cliente(self, client: AsyncClient, auth_headers, categoria):
        res = await client.post("/api/v1/servicios", headers=auth_headers, json={
            "categoria_id": str(categoria.id),
            "titulo": "Cliente no puede",
            "descripcion": "No debería crearse",
        })
        assert res.status_code == 403

    async def test_listar_servicios(self, client: AsyncClient):
        res = await client.get("/api/v1/servicios")
        assert res.status_code == 200
        assert isinstance(res.json(), list)

    async def test_listar_servicios_por_categoria(self, client: AsyncClient, categoria):
        res = await client.get(f"/api/v1/servicios?categoria_id={categoria.id}")
        assert res.status_code == 200

    async def test_buscar_geoespacial(self, client: AsyncClient):
        """Busca servicios cerca del centro de Santiago."""
        res = await client.get("/api/v1/servicios/buscar", params={
            "lat": -33.4489,
            "lng": -70.6693,
            "radio_km": 50,
            "limit": 5,
        })
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, list)
        assert len(data) <= 5

    async def test_get_servicio_no_existe(self, client: AsyncClient):
        res = await client.get(f"/api/v1/servicios/{uuid.uuid4()}")
        assert res.status_code == 404

    async def test_pausar_servicio(self, client: AsyncClient, auth_headers_proveedor, categoria):
        # Crear servicio
        create = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Para pausar",
            "descripcion": "Test pausa",
        })
        assert create.status_code == 201
        serv_id = create.json()["id"]

        # Pausar
        patch = await client.patch(f"/api/v1/servicios/{serv_id}/pausar", headers=auth_headers_proveedor)
        assert patch.status_code == 200
        assert patch.json()["status"] == "PAUSADO"

        # Re-activar
        patch2 = await client.patch(f"/api/v1/servicios/{serv_id}/pausar", headers=auth_headers_proveedor)
        assert patch2.status_code == 200
        assert patch2.json()["status"] == "ACTIVO"

    async def test_pausar_servicio_ajeno(self, client: AsyncClient, auth_headers, auth_headers_proveedor, categoria):
        """Un proveedor no puede pausar el servicio de otro."""
        # Proveedor 1 crea
        create = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Solo mío",
            "descripcion": "Nadie más lo toca",
        })
        serv_id = create.json()["id"]

        # Cliente intenta pausar (no proveedor)
        patch = await client.patch(f"/api/v1/servicios/{serv_id}/pausar", headers=auth_headers)
        assert patch.status_code == 403

    async def test_eliminar_servicio(self, client: AsyncClient, auth_headers_proveedor, categoria):
        create = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "A eliminar",
            "descripcion": "Soft delete test",
        })
        serv_id = create.json()["id"]
        delete = await client.delete(f"/api/v1/servicios/{serv_id}", headers=auth_headers_proveedor)
        assert delete.status_code == 204

        # Verificar que no aparece en listado público
        get_res = await client.get(f"/api/v1/servicios/{serv_id}")
        assert get_res.status_code == 404

    async def test_precio_negativo_rechazado(self, client: AsyncClient, auth_headers_proveedor, categoria):
        res = await client.post("/api/v1/servicios", headers=auth_headers_proveedor, json={
            "categoria_id": str(categoria.id),
            "titulo": "Precio malo",
            "descripcion": "Test",
            "precio_min": -5000,
        })
        assert res.status_code == 422
