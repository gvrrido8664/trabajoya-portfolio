"""Tests de autenticación."""
import pytest
from httpx import AsyncClient


class TestAuth:
    """Suite de tests para endpoints de auth."""

    async def test_register_cliente(self, client: AsyncClient):
        res = await client.post("/api/v1/auth/register", json={
            "email": f"newuser_{pytest.importorskip('uuid').uuid4().hex[:8]}@test.com",
            "password": "secure123",
            "nombre": "Nuevo",
            "apellido": "Usuario",
            "rol": "cliente",
        })
        assert res.status_code == 201
        data = res.json()
        assert data["access_token"] is not None
        assert data["token_type"] == "bearer"
        assert data["user"]["email"] is not None
        assert data["user"]["rol"] == "cliente"
        assert "password_hash" not in data["user"]

    async def test_register_proveedor(self, client: AsyncClient):
        import uuid as _uuid
        res = await client.post("/api/v1/auth/register", json={
            "email": f"prov_{_uuid.uuid4().hex[:8]}@test.com",
            "password": "secure123",
            "nombre": "Pro",
            "apellido": "Veedor",
            "rol": "proveedor",
        })
        assert res.status_code == 201
        assert res.json()["user"]["rol"] == "proveedor"

    async def test_register_duplicado(self, client: AsyncClient, usuario_cliente):
        res = await client.post("/api/v1/auth/register", json={
            "email": usuario_cliente.email,
            "password": "secure123",
            "nombre": "Dupe",
            "apellido": "User",
            "rol": "cliente",
        })
        assert res.status_code == 409

    async def test_register_rol_invalido(self, client: AsyncClient):
        res = await client.post("/api/v1/auth/register", json={
            "email": "badrol@test.com",
            "password": "secure123",
            "nombre": "Mal",
            "apellido": "Rol",
            "rol": "hacker",
        })
        assert res.status_code == 400

    async def test_login_exitoso(self, client: AsyncClient, usuario_cliente):
        res = await client.post("/api/v1/auth/login", json={
            "email": usuario_cliente.email,
            "password": "test123",
        })
        assert res.status_code == 200
        data = res.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"

    async def test_login_credenciales_invalidas(self, client: AsyncClient):
        res = await client.post("/api/v1/auth/login", json={
            "email": "noexiste@test.com",
            "password": "wrong",
        })
        assert res.status_code == 400

    async def test_me_autenticado(self, client: AsyncClient, auth_headers, usuario_cliente):
        res = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert res.status_code == 200
        assert res.json()["email"] == usuario_cliente.email
        assert res.json()["nombre"] == usuario_cliente.nombre

    async def test_me_sin_token(self, client: AsyncClient):
        res = await client.get("/api/v1/auth/me")
        assert res.status_code == 401

    async def test_me_token_invalido(self, client: AsyncClient):
        res = await client.get("/api/v1/auth/me", headers={"Authorization": "Bearer token-falso"})
        assert res.status_code == 401

    async def test_forgot_password(self, client: AsyncClient):
        res = await client.post("/api/v1/auth/forgot-password", json={"email": "test@test.com"})
        assert res.status_code == 200
        assert "message" in res.json()
