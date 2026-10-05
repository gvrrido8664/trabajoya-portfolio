import asyncio
import hashlib
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings


def _password_fingerprint(password_hash: str | None) -> str:
    """Huella corta del password_hash actual. Se embebe en el token de reset
    para hacerlo de un solo uso sin necesitar tabla/columna de tokens usados:
    resetear la contraseña cambia el hash, así que cualquier reuso del mismo
    token (link filtrado, historial de correo, etc.) deja de calzar."""
    return hashlib.sha256((password_hash or "none").encode()).hexdigest()[:16]


async def hash_password(password: str) -> str:
    salt = await asyncio.to_thread(bcrypt.gensalt)
    hashed = await asyncio.to_thread(bcrypt.hashpw, password.encode("utf-8"), salt)
    return hashed.decode("utf-8")


async def verify_password(plain_password: str, hashed_password: str) -> bool:
    return await asyncio.to_thread(
        bcrypt.checkpw,
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8"),
    )


def create_access_token(user_id: str, expires_delta: timedelta | None = None) -> str:
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_email_verification_token(email: str) -> str:
    """Token de corta duración para verificar email (24 horas)."""
    expire = datetime.now(timezone.utc) + timedelta(hours=24)
    payload = {"sub": email, "type": "email_verification", "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_password_reset_token(email: str, password_hash: str | None) -> str:
    """Token de corta duración para resetear contraseña (1 hora), de un
    solo uso (ver _password_fingerprint)."""
    expire = datetime.now(timezone.utc) + timedelta(hours=1)
    payload = {
        "sub": email,
        "type": "password_reset",
        "pwd_fp": _password_fingerprint(password_hash),
        "exp": expire,
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


def create_oauth_state_token(intent: str) -> str:
    """Token corto (10 min) que viaja como `state` en el redirect a Google.
    Firmado por nosotros: evita que se falsifique el `intent` (cliente/proveedor)
    sin necesitar sesión ni tabla de nonces."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=10)
    payload = {"type": "oauth_state", "intent": intent, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_marketplace_oauth_state(user_id: str) -> str:
    """Estado firmado y de corta vida para enlazar una cuenta MercadoPago."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=10)
    payload = {"type": "mp_connect", "sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_exchange_code_token(user_id: str) -> str:
    """Código de intercambio de un solo viaje (60s) entre el callback del
    backend y POST /auth/oauth/exchange — evita dejar el JWT de sesión real
    en la URL/historial del navegador."""
    expire = datetime.now(timezone.utc) + timedelta(seconds=60)
    payload = {"type": "exchange_code", "sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_typed_token(token: str, expected_type: str) -> dict:
    """Decodifica un token de propósito específico y valida su `type`."""
    payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    if payload.get("type") != expected_type:
        raise JWTError(f"Tipo de token inválido: esperaba '{expected_type}'")
    return payload


# ─────────────────────────── MFA (TOTP) ───────────────────────────
import json
import secrets as _secrets

import pyotp
from cryptography.fernet import Fernet


def _fernet() -> Fernet:
    if not settings.TOTP_ENC_KEY:
        raise RuntimeError("TOTP_ENC_KEY no configurado")
    return Fernet(settings.TOTP_ENC_KEY.encode("utf-8"))


def generate_totp_secret() -> str:
    """Secreto Base32 nuevo para TOTP (sin cifrar)."""
    return pyotp.random_base32()


def encrypt_secret(value: str) -> str:
    """Cifra cualquier secreto en reposo con la clave Fernet de la app."""
    return _fernet().encrypt(value.encode("utf-8")).decode("utf-8")


def decrypt_secret(token: str) -> str:
    return _fernet().decrypt(token.encode("utf-8")).decode("utf-8")


def encrypt_totp_secret(secret: str) -> str:
    return encrypt_secret(secret)


def decrypt_totp_secret(token: str) -> str:
    return decrypt_secret(token)


def totp_provisioning_uri(secret: str, email: str) -> str:
    """URI otpauth:// para mostrar como QR en la app autenticadora."""
    return pyotp.totp.TOTP(secret).provisioning_uri(name=email, issuer_name="TrabajoYa")


def verify_totp(secret: str, code: str) -> bool:
    """Valida un código TOTP con ventana ±1 (tolera desfase de reloj)."""
    if not secret or not code:
        return False
    return pyotp.TOTP(secret).verify(code.strip(), valid_window=1)


# ────────────────────── Backup codes (recuperación) ──────────────────────


def generate_backup_codes(n: int = 8) -> tuple[list[str], str]:
    """Genera `n` códigos en claro y devuelve (códigos, json_de_hashes_bcrypt).
    Los códigos en claro se muestran UNA sola vez; en BD solo van los hashes."""
    plain = ["-".join((_secrets.token_hex(2), _secrets.token_hex(2))) for _ in range(n)]
    hashes = [
        bcrypt.hashpw(c.encode("utf-8"), bcrypt.gensalt()).decode("utf-8") for c in plain
    ]
    return plain, json.dumps(hashes)


def verify_and_consume_backup_code(stored_json: str | None, code: str) -> tuple[bool, str | None]:
    """Verifica un backup code; si es válido lo elimina (un solo uso).
    Devuelve (ok, nuevo_json_o_None)."""
    if not stored_json or not code:
        return False, stored_json
    try:
        hashes: list[str] = json.loads(stored_json)
    except Exception:
        return False, stored_json
    code_b = code.strip().encode("utf-8")
    for h in hashes:
        if bcrypt.checkpw(code_b, h.encode("utf-8")):
            hashes.remove(h)
            return True, json.dumps(hashes)
    return False, stored_json
