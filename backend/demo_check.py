"""Offline checks; never connect to a DB, email, payment or geocoding service."""
import os
os.environ.update(DATABASE_URL='postgresql+asyncpg://demo:demo@127.0.0.1:55432/trabajoya_demo',DB_REQUIRE_SSL='false',JWT_SECRET_KEY='portfolio-offline-check-only-000000000000',MP_ACCESS_TOKEN='',MP_PUBLIC_KEY='',MP_WEBHOOK_SECRET='',DEBUG='true',SENTRY_DSN='')
from unittest.mock import patch
import requests
import httpx
from fastapi.testclient import TestClient
from app.main import app
from app.portfolio_demo import validate_target

def block(*args,**kwargs):
    raise RuntimeError('Conexión externa bloqueada durante comprobaciones')

with patch.object(requests.sessions.Session,'request',block), patch.object(httpx.AsyncClient,'request',block):
    with TestClient(app) as client:
        response=client.get('/health')
        assert response.status_code==200,response.text
        schema=client.get('/openapi.json')
        assert schema.status_code==200
        paths=schema.json()['paths']
        assert '/api/v1/auth/login' in paths
        assert '/api/v1/servicios' in paths or '/api/v1/servicios/' in paths
        bad=client.post('/api/v1/auth/register',json={})
        assert bad.status_code==422,bad.text
validate_target(os.environ['DATABASE_URL'])
try:
    validate_target('postgresql://example.com/production')
except RuntimeError:
    pass
else:
    raise AssertionError('La demo aceptó una base externa')
print(f'PASS: importación API, salud, OpenAPI ({len(paths)} rutas), validación y protección del destino demo.')
