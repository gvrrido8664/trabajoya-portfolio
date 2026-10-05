import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.database import get_db
from app.models import Usuario

security_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security_scheme),
    db: AsyncSession = Depends(get_db),
) -> Usuario:
    token = credentials.credentials
    try:
        payload = decode_access_token(token)
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido")
        user_uuid = uuid.UUID(user_id)
    except (JWTError, ValueError):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido o expirado")

    result = await db.execute(select(Usuario).where(Usuario.id == user_uuid))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no encontrado o inactivo")
    return user


async def require_email_verificado(
    current_user: Usuario = Depends(get_current_user),
) -> Usuario:
    """Exige email verificado para acciones sensibles (bloqueo suave: leer/navegar
    sigue libre; solo se bloquean acciones que crean datos o transaccionan)."""
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes verificar tu email para realizar esta acción",
        )
    return current_user


async def get_current_provider(
    current_user: Usuario = Depends(get_current_user),
) -> Usuario:
    # Autoriza por capacidad, no por rol: una cuenta puede ser cliente y proveedor.
    if not (current_user.es_proveedor or current_user.rol.value == "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Activa el modo proveedor para realizar esta acción",
        )
    return current_user


async def get_current_admin(
    current_user: Usuario = Depends(get_current_user),
) -> Usuario:
    if current_user.rol.value != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Se requiere rol de administrador")
    # El MFA es obligatorio para admin (ver /auth/totp/disable, que ya lo
    # rechaza para este rol) -- pero nada exigía haberlo configurado antes
    # de usar el panel: sin esto, un admin sin 2FA activado podía usar
    # cualquier endpoint de administración con solo email+password (SEC-11).
    if not current_user.totp_enabled:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes configurar la verificación en dos pasos antes de continuar",
        )
    return current_user

async def require_premium(
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
) -> Usuario:
    from sqlalchemy import select
    from app.models import Suscripcion, EstadoSuscripcion

    result = await db.execute(
        select(Suscripcion)
        .where(Suscripcion.usuario_id == current_user.id, Suscripcion.status == EstadoSuscripcion.ACTIVA)
        .limit(1)
    )
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requiere una suscripción Premium activa",
        )
    return current_user
