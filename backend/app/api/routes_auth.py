from urllib.parse import urlencode

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from fastapi.responses import RedirectResponse
from jose import JWTError
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
import secrets
import string
import httpx

from app.api.dependencies import get_current_user
from app.core.config import settings
from app.core.limiter import limiter
from app.core.security import (
    _password_fingerprint,
    create_access_token,
    create_email_verification_token,
    create_exchange_code_token,
    create_oauth_state_token,
    create_password_reset_token,
    decode_access_token,
    decode_typed_token,
    decrypt_totp_secret,
    encrypt_totp_secret,
    generate_backup_codes,
    generate_totp_secret,
    hash_password,
    totp_provisioning_uri,
    verify_and_consume_backup_code,
    verify_password,
    verify_totp,
)
from app.database import get_db
from app.models import Usuario
from app.schemas import LoginRequest, RegistroRequest, RegistroResponse, Token, UsuarioResponse
from app.services.email_service import email_service

router = APIRouter(prefix="/auth", tags=["auth"])


def _generar_codigo_referido() -> str:
    """Genera un código único de referido de 8 caracteres."""
    return "".join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(8))


@router.post("/register", response_model=RegistroResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/hour")
async def register(
    request: Request,
    data: RegistroRequest,
    ref: str | None = Query(None, description="Código de referido"),
    db: AsyncSession = Depends(get_db),
):
    exists = await db.execute(select(Usuario).where(Usuario.email == data.email))
    if exists.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="El email ya está registrado")

    if data.rol not in ("cliente", "proveedor"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol inválido. Debe ser 'cliente' o 'proveedor'",
        )

    # Generar código de referido único
    codigo = _generar_codigo_referido()
    while (await db.execute(select(Usuario).where(Usuario.codigo_referido == codigo))).scalar_one_or_none():
        codigo = _generar_codigo_referido()

    # Sistema de referidos
    referido_por_id = None
    if ref:
        result_ref = await db.execute(select(Usuario).where(Usuario.codigo_referido == ref))
        referente = result_ref.scalar_one_or_none()
        if referente:
            referente.referidos_count = (referente.referidos_count or 0) + 1
            referido_por_id = referente.id

    user = Usuario(
        email=data.email,
        password_hash=await hash_password(data.password),
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        rol=data.rol,
        es_proveedor=(data.rol == "proveedor"),
        codigo_referido=codigo,
        referido_por=referido_por_id,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    # Generar access_token
    access_token = create_access_token(str(user.id))

    # Enviar email de verificación
    email_token = create_email_verification_token(user.email)
    await email_service.enviar_verificacion(user.email, email_token, user.nombre)

    return RegistroResponse(access_token=access_token, token_type="bearer", user=user)


@router.post("/login", response_model=Token)
@limiter.limit("5/minute")
async def login(request: Request, data: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Usuario).where(Usuario.email == data.email))
    user = result.scalar_one_or_none()
    if not user or not await verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email o contraseña incorrectos")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cuenta desactivada")

    # Segundo factor (MFA) si la cuenta lo tiene activo
    if user.totp_enabled:
        code = (data.totp_code or "").strip()
        if not code:
            # Credenciales válidas pero falta el 2FA: 200 con flag (no 401), para
            # que el frontend pida el código sin ruido de error en la consola.
            return Token(access_token="", mfa_required=True)
        ok = bool(user.totp_secret) and verify_totp(decrypt_totp_secret(user.totp_secret), code)
        if not ok:
            # Permitir backup code como alternativa
            consumed, nuevo = verify_and_consume_backup_code(user.backup_codes, code)
            if not consumed:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de verificación inválido")
            user.backup_codes = nuevo
            await db.commit()

    token = create_access_token(str(user.id))
    return Token(access_token=token)


@router.get("/me", response_model=UsuarioResponse)
async def me(current_user: Usuario = Depends(get_current_user)):
    return current_user


class UpdateProfileRequest(BaseModel):
    nombre: str | None = None
    apellido: str | None = None
    telefono: str | None = None


@router.patch("/me", response_model=UsuarioResponse)
async def update_me(
    data: UpdateProfileRequest,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.nombre is not None:
        current_user.nombre = data.nombre
    if data.apellido is not None:
        current_user.apellido = data.apellido
    if data.telefono is not None:
        current_user.telefono = data.telefono
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/verify-email")
async def verify_email(token: str, db: AsyncSession = Depends(get_db)):
    """Verifica el email del usuario mediante token enviado por correo."""
    error_url = f"{settings.FRONTEND_URL}/verificado?status=error"
    success_url = f"{settings.FRONTEND_URL}/verificado?status=success"
    
    try:
        payload = decode_access_token(token)
        if payload.get("type") != "email_verification":
            return RedirectResponse(url=error_url)
        email = payload.get("sub")
    except JWTError:
        return RedirectResponse(url=error_url)

    result = await db.execute(select(Usuario).where(Usuario.email == email))
    user = result.scalar_one_or_none()
    if not user:
        return RedirectResponse(url=error_url)
    
    if user.is_verified:
        return RedirectResponse(url=success_url)

    user.is_verified = True
    await db.commit()

    await email_service.enviar_bienvenida(user.email, user.nombre)
    return RedirectResponse(url=success_url)


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8)


@router.post("/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(
    request: Request,
    data: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    """Envía un link de reseteo de contraseña al email."""
    result = await db.execute(select(Usuario).where(Usuario.email == data.email))
    user = result.scalar_one_or_none()
    # Respuesta genérica siempre (exista o no la cuenta) para no permitir
    # enumeración de usuarios. Solo se envía el correo si el usuario existe.
    if user:
        token = create_password_reset_token(user.email, user.password_hash)
        await email_service.enviar_reset_password(user.email, token, user.nombre)
    return {"message": "Si el email está registrado, te enviamos un link para restablecer tu contraseña"}


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8)


@router.post("/change-password")
async def change_password(
    data: ChangePasswordRequest,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not await verify_password(data.current_password, current_user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Contraseña actual incorrecta")
    current_user.password_hash = await hash_password(data.new_password)
    db.add(current_user)
    await db.commit()
    return {"message": "Contraseña actualizada exitosamente"}


@router.post("/resend-verification")
@limiter.limit("3/minute")
async def resend_verification(
    request: Request,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Reenvía el email de verificación al usuario autenticado."""
    if current_user.is_verified:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El email ya está verificado")
    email_token = create_email_verification_token(current_user.email)
    await email_service.enviar_verificacion(current_user.email, email_token, current_user.nombre)
    return {"message": "Correo de verificación reenviado"}


@router.post("/reset-password")
@limiter.limit("5/minute")
async def reset_password(
    request: Request,
    data: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db),
):
    """Cambia la contraseña usando un token de reseteo."""
    try:
        payload = decode_access_token(data.token)
        if payload.get("type") != "password_reset":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token inválido")
        email = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token inválido o expirado")

    result = await db.execute(select(Usuario).where(Usuario.email == email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")

    # El token es de un solo uso: si el password_hash ya cambió desde que se
    # emitió (porque este mismo token ya se usó, o la contraseña cambió por
    # otra vía), la huella ya no calza (SEC-17).
    if payload.get("pwd_fp") != _password_fingerprint(user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Este link ya fue usado o ya no es válido. Solicita uno nuevo.",
        )

    user.password_hash = await hash_password(data.new_password)
    await db.commit()
    return {"message": "Contraseña actualizada exitosamente"}


# ─────────────────────────── MFA (TOTP) ───────────────────────────


class TotpEnableRequest(BaseModel):
    code: str


class TotpDisableRequest(BaseModel):
    password: str


@router.post("/totp/setup")
async def totp_setup(
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Genera un secreto TOTP (cifrado en BD) y devuelve el URI otpauth para el QR.
    No activa MFA todavía: requiere confirmar un código vía /totp/enable."""
    if current_user.totp_enabled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El MFA ya está activo")
    secret = generate_totp_secret()
    current_user.totp_secret = encrypt_totp_secret(secret)
    await db.commit()
    return {
        "otpauth_uri": totp_provisioning_uri(secret, current_user.email),
        "secret": secret,  # por si el usuario prefiere ingresarlo manualmente
    }


@router.post("/totp/enable")
async def totp_enable(
    data: TotpEnableRequest,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Confirma el primer código y activa MFA; devuelve los backup codes (una sola vez)."""
    if current_user.totp_enabled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El MFA ya está activo")
    if not current_user.totp_secret:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Primero llama a /totp/setup")
    if not verify_totp(decrypt_totp_secret(current_user.totp_secret), data.code):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código inválido")

    plain_codes, hashes_json = generate_backup_codes()
    current_user.totp_enabled = True
    current_user.backup_codes = hashes_json
    await db.commit()
    return {"message": "MFA activado", "backup_codes": plain_codes}


@router.post("/totp/disable")
async def totp_disable(
    data: TotpDisableRequest,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Desactiva MFA. Requiere la contraseña actual (re-auth)."""
    if not await verify_password(data.password, current_user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Contraseña incorrecta")
    if current_user.rol.value == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="El MFA es obligatorio para administradores")
    current_user.totp_enabled = False
    current_user.totp_secret = None
    current_user.backup_codes = None
    await db.commit()
    return {"message": "MFA desactivado"}


# ─────────────────────────── Social OAuth ───────────────────────────


GOOGLE_TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"


class SocialLoginRequest(BaseModel):
    provider: str  # "google"
    id_token: str
    rol: str = "cliente"  # solo se usa al registrar por primera vez


async def _verificar_id_token_google(id_token: str) -> dict:
    """Valida un id_token de Google contra tokeninfo y devuelve su payload.
    Compartido por el flujo id_token directo (móvil) y el de redirect (web)."""
    async with httpx.AsyncClient() as client:
        resp = await client.get(GOOGLE_TOKENINFO_URL, params={"id_token": id_token})

    if resp.status_code != 200:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Google inválido o expirado.",
        )

    payload = resp.json()

    # Validar que el token fue emitido para nuestra app. Si GOOGLE_CLIENT_ID
    # no está configurado, fallar en vez de aceptar tokens de cualquier
    # audiencia (evita saltarse la validación por un secret faltante).
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login con Google no configurado en el servidor.",
        )
    if payload.get("aud") != settings.GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token no pertenece a esta aplicación.",
        )
    return payload


async def _resolver_o_crear_usuario_google(db: AsyncSession, payload: dict, rol: str) -> Usuario:
    """Busca por google_id, luego por email (vinculando), o crea la cuenta.
    `rol` solo se usa si hay que crear una cuenta nueva."""
    google_id = payload.get("sub")
    email = payload.get("email")
    nombre = payload.get("given_name") or payload.get("name", "Usuario").split()[0]
    apellido = payload.get("family_name") or (payload.get("name", "").split()[-1] if " " in payload.get("name", "") else "Google")
    avatar_url = payload.get("picture")
    email_verified = payload.get("email_verified") == "true" or payload.get("email_verified") is True

    if not google_id or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token de Google no contiene email o ID de usuario.",
        )

    # ── Buscar por google_id primero, luego por email ──
    result = await db.execute(select(Usuario).where(Usuario.google_id == google_id))
    user = result.scalar_one_or_none()

    if not user:
        # Buscar por email (puede existir cuenta local con mismo email)
        result_email = await db.execute(select(Usuario).where(Usuario.email == email))
        user = result_email.scalar_one_or_none()
        if user:
            # Vincular google_id a la cuenta local existente
            user.google_id = google_id
            user.auth_provider = "google"
            if avatar_url and not user.avatar_url:
                user.avatar_url = avatar_url
            await db.commit()
            await db.refresh(user)

    if not user:
        # ── Registrar nuevo usuario social ──
        codigo = _generar_codigo_referido()
        while (await db.execute(select(Usuario).where(Usuario.codigo_referido == codigo))).scalar_one_or_none():
            codigo = _generar_codigo_referido()

        user = Usuario(
            email=email,
            password_hash=None,  # cuentas OAuth no tienen contraseña local
            nombre=nombre,
            apellido=apellido,
            rol=rol,
            es_proveedor=(rol == "proveedor"),
            google_id=google_id,
            auth_provider="google",
            avatar_url=avatar_url,
            is_active=True,
            is_verified=email_verified,
            codigo_referido=codigo,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cuenta desactivada.")

    return user


@router.post("/social", response_model=RegistroResponse)
@limiter.limit("10/minute")
async def social_login(
    request: Request,
    data: SocialLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Autenticación social (flujo id_token directo — móvil). Verifica el
    id_token con Google y devuelve un JWT propio. Si el usuario no existe,
    lo registra automáticamente."""

    if data.provider != "google":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Proveedor no soportado. Use 'google'.",
        )

    if data.rol not in ("cliente", "proveedor"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rol inválido. Debe ser 'cliente' o 'proveedor'",
        )

    payload = await _verificar_id_token_google(data.id_token)
    user = await _resolver_o_crear_usuario_google(db, payload, data.rol)

    access_token = create_access_token(str(user.id))
    return RegistroResponse(access_token=access_token, token_type="bearer", user=user)


# ─────────────────────── Google OAuth por redirect (web) ───────────────────────


GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"


def _google_redirect_uri() -> str:
    return f"{settings.BACKEND_URL}{settings.API_V1_PREFIX}/auth/google/callback"


@router.get("/google/login")
@limiter.limit("20/minute")
async def google_login_redirect(request: Request, intent: str = Query("cliente")):
    """Punto de entrada del flujo por redirect: el navegador navega acá y
    salimos con un 302 hacia la pantalla de consentimiento de Google.
    `intent` (cliente|proveedor) solo decide a dónde navega el frontend al
    volver — la cuenta nueva siempre nace cliente (ver _resolver_o_crear_usuario_google)."""
    if intent not in ("cliente", "proveedor"):
        intent = "cliente"
    if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login con Google no configurado en el servidor.",
        )

    params = {
        "client_id": settings.GOOGLE_CLIENT_ID,
        "redirect_uri": _google_redirect_uri(),
        "response_type": "code",
        "scope": "openid email profile",
        "state": create_oauth_state_token(intent),
        "prompt": "select_account",
    }
    return RedirectResponse(url=f"{GOOGLE_AUTH_URL}?{urlencode(params)}")


@router.get("/google/callback")
@limiter.limit("30/minute")
async def google_callback(
    request: Request,
    code: str | None = None,
    state: str | None = None,
    error: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    """Google vuelve acá con el `code`. Lo canjeamos por tokens, resolvemos o
    creamos el usuario, y mandamos al frontend con un código de intercambio
    de 60s — nunca el JWT de sesión real viaja en la URL."""
    error_url = f"{settings.FRONTEND_URL}/login?error=google_oauth"

    if error or not code or not state:
        return RedirectResponse(url=error_url)

    try:
        state_payload = decode_typed_token(state, "oauth_state")
    except JWTError:
        return RedirectResponse(url=error_url)
    intent = state_payload.get("intent", "cliente")

    async with httpx.AsyncClient() as client:
        token_resp = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "code": code,
                "client_id": settings.GOOGLE_CLIENT_ID,
                "client_secret": settings.GOOGLE_CLIENT_SECRET,
                "redirect_uri": _google_redirect_uri(),
                "grant_type": "authorization_code",
            },
        )
    if token_resp.status_code != 200:
        return RedirectResponse(url=error_url)

    id_token = token_resp.json().get("id_token")
    if not id_token:
        return RedirectResponse(url=error_url)

    try:
        payload = await _verificar_id_token_google(id_token)
        user = await _resolver_o_crear_usuario_google(db, payload, "cliente")
    except HTTPException:
        return RedirectResponse(url=error_url)

    exchange_code = create_exchange_code_token(str(user.id))
    return RedirectResponse(
        url=f"{settings.FRONTEND_URL}/auth/google/callback?xc={exchange_code}&intent={intent}"
    )


class OAuthExchangeRequest(BaseModel):
    code: str


@router.post("/oauth/exchange", response_model=RegistroResponse)
@limiter.limit("20/minute")
async def oauth_exchange(
    request: Request,
    data: OAuthExchangeRequest,
    db: AsyncSession = Depends(get_db),
):
    """Canjea el código de intercambio de 60s (emitido por /google/callback)
    por el JWT de sesión real."""
    try:
        payload = decode_typed_token(data.code, "exchange_code")
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Código de intercambio inválido o expirado.",
        )

    user_id = payload.get("sub")
    result = await db.execute(select(Usuario).where(Usuario.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario no encontrado o inactivo.")

    access_token = create_access_token(str(user.id))
    return RegistroResponse(access_token=access_token, token_type="bearer", user=user)
