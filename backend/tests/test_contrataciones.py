"""Tests del flujo de contratación (el core del negocio)."""
import uuid

import pytest
from httpx import AsyncClient


@pytest.fixture
async def categoria(db_session):
    from app.models import Categoria
    cat = Categoria(nombre="Test", slug=f"test-{uuid.uuid4().hex[:6]}", icono="🧪")
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


class TestContrataciones:
    """Flujo completo: solicitar → aceptar → completar → reseñar."""

    async def test_cliente_solicita_servicio(
        self, client: AsyncClient, auth_headers, servicio_activo
    ):
        res = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 30000,
            "mensaje_solicitud": "Hola, necesito este servicio",
        })
        assert res.status_code == 201
        data = res.json()
        assert data["status"] == "PENDIENTE"
        assert data["servicio_id"] == str(servicio_activo.id)

    async def test_no_puede_contratar_su_propio_servicio(
        self, client: AsyncClient, auth_headers_proveedor, servicio_activo
    ):
        # Con capacidades por rol, cualquier cuenta (incl. proveedores) tiene
        # es_cliente=True por defecto; el bloqueo real es la auto-contratación.
        res = await client.post("/api/v1/contrataciones", headers=auth_headers_proveedor, json={
            "servicio_id": str(servicio_activo.id),
        })
        assert res.status_code == 400  # No puedes contratar tu propio servicio

    async def test_proveedor_puede_contratar_servicio_ajeno(
        self, client: AsyncClient, auth_headers_proveedor, db_session, categoria
    ):
        # Efecto deliberado de la migración a capacidades: un proveedor ya
        # puede contratar servicios de otros (tiene es_cliente=True por defecto).
        from app.core.security import hash_password
        from app.models import EstadoServicio, RolUsuario, Servicio, Usuario

        otro_proveedor = Usuario(
            email=f"otro_prov_{uuid.uuid4().hex[:8]}@test.com",
            password_hash=await hash_password("test123"),
            nombre="Otro",
            apellido="Proveedor",
            rol=RolUsuario.PROVEEDOR,
            es_proveedor=True,
            is_verified=True,
            doc_estado="approved",
        )
        db_session.add(otro_proveedor)
        await db_session.flush()

        otro_servicio = Servicio(
            proveedor_id=otro_proveedor.id,
            categoria_id=categoria.id,
            titulo="Servicio de otro proveedor",
            descripcion="Descripción de prueba",
            precio_min=10000,
            precio_max=50000,
            status=EstadoServicio.ACTIVO,
            radio_cobertura_km=10,
        )
        db_session.add(otro_servicio)
        await db_session.commit()
        await db_session.refresh(otro_servicio)

        res = await client.post("/api/v1/contrataciones", headers=auth_headers_proveedor, json={
            "servicio_id": str(otro_servicio.id),
            "monto_acordado": 30000,
        })
        assert res.status_code == 201

    async def test_flujo_completo_aceptar_completar_resenar(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo, db_session
    ):
        """"Cliente solicita → proveedor acepta → ambos completan → reseña."""
        from app.models import EstadoPago, Pago

        cliente = auth_headers  # cliente
        proveedor = auth_headers_proveedor

        # 1. Cliente crea contratación
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 25000,
            "mensaje_solicitud": "Urgente por favor",
        })
        assert create.status_code == 201
        contratacion_id = create.json()["id"]

        # 2. Proveedor acepta
        aceptar = await client.patch(
            f"/api/v1/contrataciones/{contratacion_id}/aceptar",
            headers=auth_headers_proveedor,
        )
        assert aceptar.status_code == 200
        assert aceptar.json()["status"] == "ACEPTADO"

        # 3. No se puede aceptar dos veces
        aceptar2 = await client.patch(
            f"/api/v1/contrataciones/{contratacion_id}/aceptar",
            headers=auth_headers_proveedor,
        )
        assert aceptar2.status_code == 400

        # 3b. Cliente paga garantía (requerido antes de finalizar)
        from uuid import UUID as _UUID
        pago = Pago(
            contratacion_id=_UUID(contratacion_id),
            monto=25000,
            status=EstadoPago.APROBADO,
        )
        db_session.add(pago)
        await db_session.commit()

        # 4. Completar (cualquiera de los dos)
        completar = await client.post(
            f"/api/v1/contrataciones/{contratacion_id}/completar",
            headers=auth_headers,
        )
        assert completar.status_code == 200
        assert completar.json()["status"] == "COMPLETADO"

        # 5. Dejar reseña
        resena = await client.post(
            f"/api/v1/contrataciones/{contratacion_id}/resena",
            headers=auth_headers,
            json={"puntuacion": 5, "comentario": "Excelente trabajo"},
        )
        assert resena.status_code == 201
        assert resena.json()["puntuacion"] == 5

        # 6. No se puede dejar otra reseña
        resena2 = await client.post(
            f"/api/v1/contrataciones/{contratacion_id}/resena",
            headers=auth_headers,
            json={"puntuacion": 3, "comentario": "Segunda reseña"},
        )
        assert resena2.status_code == 409

    async def test_no_resenar_sin_completar(
        self, client: AsyncClient, auth_headers, servicio_activo
    ):
        # Crear contratación pendiente
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 10000,
        })
        contratacion_id = create.json()["id"]

        # Intentar reseñar sin completar
        resena = await client.post(
            f"/api/v1/contrataciones/{contratacion_id}/resena",
            headers=auth_headers,
            json={"puntuacion": 4},
        )
        assert resena.status_code == 400

    async def test_ajeno_no_puede_ver_contratacion(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo
    ):
        # Cliente crea
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 10000,
        })
        cid = create.json()["id"]

        # Otro cliente intenta acceder
        import uuid as _uuid
        otro_email = f"otro_{_uuid.uuid4().hex[:8]}@test.com"
        await client.post("/api/v1/auth/register", json={
            "email": otro_email,
            "password": "test1234",
            "nombre": "Otro",
            "apellido": "Cliente",
            "rol": "cliente",
        })
        login = await client.post("/api/v1/auth/login", json={
            "email": otro_email,
            "password": "test1234",
        })
        otro_token = login.json()["access_token"]

        res = await client.get(
            f"/api/v1/contrataciones/{cid}",
            headers={"Authorization": f"Bearer {otro_token}"},
        )
        assert res.status_code == 403

    async def test_listar_mis_contrataciones(
        self, client: AsyncClient, auth_headers, servicio_activo
    ):
        # Crear una para que la lista no esté vacía
        await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 15000,
        })

        res = await client.get("/api/v1/contrataciones", headers=auth_headers)
        assert res.status_code == 200
        data = res.json()
        assert isinstance(data, dict)
        assert "items" in data
        assert isinstance(data["items"], list)
        assert len(data["items"]) >= 1


class TestDisputas:
    """Tests del sistema de disputas."""

    async def test_abrir_disputa_como_cliente(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo
    ):
        # Crear y aceptar contratación
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 20000,
        })
        cid = create.json()["id"]
        await client.patch(f"/api/v1/contrataciones/{cid}/aceptar", headers=auth_headers_proveedor)

        # Abrir disputa
        res = await client.post(
            f"/api/v1/disputas/contratacion/{cid}",
            headers=auth_headers,
            json={"motivo": "El trabajo no cumple lo acordado", "evidencias": ["Fotos adjuntas"]},
        )
        assert res.status_code == 201
        assert res.json()["status"] == "ABIERTA"

    async def test_no_duplicar_disputa(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo
    ):
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 20000,
        })
        cid = create.json()["id"]
        await client.patch(f"/api/v1/contrataciones/{cid}/aceptar", headers=auth_headers_proveedor)

        await client.post(
            f"/api/v1/disputas/contratacion/{cid}",
            headers=auth_headers,
            json={"motivo": "Problema"},
        )
        res2 = await client.post(
            f"/api/v1/disputas/contratacion/{cid}",
            headers=auth_headers,
            json={"motivo": "Otro problema"},
        )
        assert res2.status_code == 409

    async def test_ajeno_no_puede_abrir_disputa(
        self, client: AsyncClient, auth_headers, auth_headers_proveedor, servicio_activo
    ):
        create = await client.post("/api/v1/contrataciones", headers=auth_headers, json={
            "servicio_id": str(servicio_activo.id),
            "monto_acordado": 20000,
        })
        cid = create.json()["id"]
        await client.patch(f"/api/v1/contrataciones/{cid}/aceptar", headers=auth_headers_proveedor)

        # Un tercero intenta abrir disputa
        import uuid as _uuid
        otro_email = f"tercero_{_uuid.uuid4().hex[:8]}@test.com"
        await client.post("/api/v1/auth/register", json={
            "email": otro_email, "password": "test1234",
            "nombre": "Tercero", "apellido": "User", "rol": "cliente",
        })
        login = await client.post("/api/v1/auth/login", json={
            "email": otro_email, "password": "test1234",
        })
        otro_token = login.json()["access_token"]

        res = await client.post(
            f"/api/v1/disputas/contratacion/{cid}",
            headers={"Authorization": f"Bearer {otro_token}"},
            json={"motivo": "No debería poder"},
        )
        assert res.status_code == 403
