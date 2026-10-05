from supabase import create_client, Client
from app.core.config import settings
import httpx

# Deshabilitar verificación SSL si hay problemas locales con certifi
# En producción Fly.io no debería haber problemas, pero lo dejamos robusto.
import os

supabase: Client | None = None

if settings.SUPABASE_URL and settings.SUPABASE_SERVICE_KEY:
    supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
