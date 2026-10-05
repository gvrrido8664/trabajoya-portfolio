import logging
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import RedirectResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import httpx

from app.core.config import settings
from app.core.security import create_marketplace_oauth_state, decode_typed_token, encrypt_secret
from app.database import get_db
from app.models.usuario import Usuario
from app.api.dependencies import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/mercadopago", tags=["MercadoPago"])

@router.get("/auth-url")
async def get_auth_url(current_user: Usuario = Depends(get_current_user)):
    """
    Retorna la URL de autorización de MercadoPago Connect.
    El frontend debería redirigir al usuario a esta URL.
    """
    if not settings.MP_CLIENT_ID or not settings.MP_ACCESS_TOKEN:
        raise HTTPException(status_code=503, detail="MercadoPago Connect no está configurado")
    redirect_uri = f"{settings.BACKEND_URL}/api/v1/mercadopago/callback"
    state = create_marketplace_oauth_state(str(current_user.id))
    url = f"https://auth.mercadopago.com/authorization?client_id={settings.MP_CLIENT_ID}&response_type=code&platform_id=mp&state={state}&redirect_uri={redirect_uri}"
    return {"url": url}

@router.get("/callback")
async def mercadopago_callback(
    code: str = Query(...),
    state: str = Query(...),
    db: AsyncSession = Depends(get_db)
):
    """
    Recibe el callback de MercadoPago tras el OAuth de un proveedor.
    `state` debe ser el ID del usuario.
    """
    try:
        user_id = uuid.UUID(decode_typed_token(state, "mp_connect")["sub"])
    except Exception:
        raise HTTPException(status_code=400, detail="State inválido")

    result = await db.execute(select(Usuario).where(Usuario.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    redirect_uri = f"{settings.BACKEND_URL}/api/v1/mercadopago/callback"

    payload = {
        "client_secret": settings.MP_ACCESS_TOKEN,
        "client_id": settings.MP_CLIENT_ID,
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri
    }

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "https://api.mercadopago.com/oauth/token",
            data=payload,
            headers={
                "accept": "application/json",
                "content-type": "application/x-www-form-urlencoded"
            }
        )

    if resp.status_code >= 400:
        logger.error("mp_oauth_error", extra={"status": resp.status_code, "body": resp.text})
        return RedirectResponse(url=f"{settings.FRONTEND_URL}/perfil?mp_error=1")

    data = resp.json()

    access_token = data.get("access_token")
    if not access_token:
        logger.error("mp_oauth_missing_access_token", extra={"user_id": str(user_id)})
        return RedirectResponse(url=f"{settings.FRONTEND_URL}/perfil?mp_error=1")
    user.mp_access_token = encrypt_secret(access_token)
    refresh_token = data.get("refresh_token")
    user.mp_refresh_token = encrypt_secret(refresh_token) if refresh_token else None
    user.mp_public_key = data.get("public_key")
    user.mp_user_id = str(data.get("user_id"))
    user.mp_configured = True

    await db.commit()
    logger.info("mp_connect_success", extra={"user_id": str(user_id)})

    return RedirectResponse(url=f"{settings.FRONTEND_URL}/perfil?mp_success=1")
