import pytest
from httpx import AsyncClient
from app.models import Solicitud, StatusSolicitud, Categoria

@pytest.fixture
async def categoria(db_session):
    cat = Categoria(nombre="Plomería", slug="plomeria", icono="🔧")
    db_session.add(cat)
    await db_session.commit()
    await db_session.refresh(cat)
    return cat

@pytest.fixture
async def cuatro_solicitudes(db_session, usuario_cliente, categoria):
    sols = []
    for i in range(4):
        sol = Solicitud(
            cliente_id=usuario_cliente.id,
            categoria_id=categoria.id,
            titulo=f"Solicitud {i}",
            descripcion=f"Descripción de la solicitud {i}",
            status=StatusSolicitud.ABIERTA
        )
        db_session.add(sol)
        sols.append(sol)
    await db_session.commit()
    return sols

class TestPropuestasLimit:
    async def test_basico_provider_proposal_limit(
        self, client: AsyncClient, auth_headers_proveedor, cuatro_solicitudes
    ):
        # 1. Enviar 3 propuestas (deberían tener éxito)
        for i in range(3):
            sol_id = str(cuatro_solicitudes[i].id)
            res = await client.post(
                f"/api/v1/solicitudes/{sol_id}/propuestas",
                headers=auth_headers_proveedor,
                json={
                    "descripcion": f"Propuesta de prueba {i}",
                    "precio": 15000.0,
                    "tiempo_estimado": "2 días"
                }
            )
            assert res.status_code == 201

        # 2. Intentar enviar la 4a propuesta (debería lanzar 403)
        sol_id_4 = str(cuatro_solicitudes[3].id)
        res_4 = await client.post(
            f"/api/v1/solicitudes/{sol_id_4}/propuestas",
            headers=auth_headers_proveedor,
            json={
                "descripcion": "Esta propuesta debería fallar por límite del plan Básico",
                "precio": 15000.0,
                "tiempo_estimado": "2 días"
            }
        )
        assert res_4.status_code == 403
        data = res_4.json()
        assert "Límite alcanzado" in data["detail"]
        assert "plan Básico permite un máximo de 3" in data["detail"]
