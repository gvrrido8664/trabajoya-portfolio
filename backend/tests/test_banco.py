import pytest
from httpx import AsyncClient
from uuid import UUID

from app.models import Usuario, Pago, EstadoPago, Contratacion, EstadoContratacion

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


@pytest.mark.asyncio
class TestBancoEndpoints:

    async def test_get_banco_default(self, client: AsyncClient, auth_headers_proveedor):
        res = await client.get("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor)
        assert res.status_code == 200
        data = res.json()
        assert data["bank_configured"] is False
        assert data["bank_name"] is None
        assert data["account_type"] is None
        assert data["account_last4"] is None
        assert data["bank_rut"] is None

    async def test_put_banco_valido(self, client: AsyncClient, auth_headers_proveedor):
        # 12.345.678-5 es un RUT válido en Chile
        payload = {
            "rut": "12.345.678-5",
            "bank_name": "Banco Estado",
            "account_number": "9876543210",
            "account_type": "vista"
        }
        res = await client.put("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor, json=payload)
        assert res.status_code == 200
        assert res.json() == {"status": "ok"}

        # Verificar GET refleje cambios
        res_get = await client.get("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor)
        assert res_get.status_code == 200
        data = res_get.json()
        assert data["bank_configured"] is True
        assert data["bank_name"] == "Banco Estado"
        assert data["account_type"] == "vista"
        assert data["account_last4"] == "3210"
        assert data["bank_rut"] == "12.345.678-5"

    async def test_put_banco_invalid_rut(self, client: AsyncClient, auth_headers_proveedor):
        # 12.345.678-9 tiene dígito verificador incorrecto (debería ser 5)
        payload = {
            "rut": "12.345.678-9",
            "bank_name": "Banco Estado",
            "account_number": "9876543210",
            "account_type": "vista"
        }
        res = await client.put("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor, json=payload)
        assert res.status_code == 400
        assert "RUT chileno no válido" in res.json()["detail"]

    async def test_put_banco_invalid_bank_name(self, client: AsyncClient, auth_headers_proveedor):
        payload = {
            "rut": "12.345.678-5",
            "bank_name": "Banco Fantasma",
            "account_number": "9876543210",
            "account_type": "vista"
        }
        res = await client.put("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor, json=payload)
        assert res.status_code == 400
        assert "Banco no soportado" in res.json()["detail"]

    async def test_put_banco_invalid_account_type(self, client: AsyncClient, auth_headers_proveedor):
        payload = {
            "rut": "12.345.678-5",
            "bank_name": "Banco Estado",
            "account_number": "9876543210",
            "account_type": "invalid_type"
        }
        res = await client.put("/api/v1/proveedores/me/banco", headers=auth_headers_proveedor, json=payload)
        assert res.status_code == 400
        assert "Tipo de cuenta no válido" in res.json()["detail"]


@pytest.mark.asyncio
class TestPayoutGuard:

    async def test_ejecutar_payout_sin_banco_falla_temprano(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo, db_session, mocker
    ):
        from app.api.routes_contrataciones import _ejecutar_payout

        class MockAsyncSession:
            def __init__(self, session):
                self.session = session
            async def __aenter__(self):
                return self.session
            async def __aexit__(self, exc_type, exc_val, exc_tb):
                pass

        mocker.patch("app.api.routes_contrataciones.async_session", return_value=MockAsyncSession(db_session))

        # 1. Cliente crea contratación
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 25000,
        })
        assert create.status_code == 201
        contratacion_id = create.json()["id"]

        # 2. Proveedor acepta
        aceptar = await client.patch(
            f"/api/v1/contrataciones/{contratacion_id}/aceptar",
            headers=auth_headers_proveedor,
        )
        assert aceptar.status_code == 200

        # 3. Cliente paga
        pago = Pago(
            contratacion_id=UUID(contratacion_id),
            monto=25000,
            status=EstadoPago.APROBADO,
        )
        db_session.add(pago)
        await db_session.commit()

        # Aseguramos que el proveedor no tenga configurado el banco
        prov_user = await db_session.get(Usuario, servicio_activo.proveedor_id)
        prov_user.bank_configured = False
        await db_session.commit()

        # 4. Ejecutamos el payout directamente
        await _ejecutar_payout(contratacion_id)

        # 5. El pago debe quedar en FAILED
        await db_session.refresh(pago)
        assert pago.payout_status == "FAILED"
