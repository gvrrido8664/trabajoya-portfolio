from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, computed_field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    # True cuando las credenciales son válidas pero falta el segundo factor (2FA).
    # Se responde 200 con este flag (en vez de 401) para que el frontend pida el
    # código sin generar un error en la consola del navegador.
    mfa_required: bool = False


class TokenPayload(BaseModel):
    sub: str
    exp: int


class RegistroRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    nombre: str
    apellido: str
    telefono: str | None = None
    rol: str = "cliente"
    codigo_referido: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    totp_code: str | None = None  # requerido si la cuenta tiene MFA activo


class UsuarioResponse(BaseModel):
    id: UUID
    email: str
    nombre: str
    apellido: str
    telefono: str | None
    rol: str
    es_cliente: bool = True
    es_proveedor: bool = False
    proveedor_activado_at: datetime | None = None
    avatar_url: str | None
    bio: str | None
    habilidades: str | None
    is_active: bool
    is_verified: bool
    telefono_verificado: bool = False
    totp_enabled: bool = False
    doc_estado: str = "none"
    avg_rating: float
    avg_rating_proveedor: float = 0.0
    avg_rating_cliente: float = 0.0
    referidos_count: int
    codigo_referido: str | None = None
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}

    @computed_field
    @property
    def email_verificado(self) -> bool:
        return self.is_verified

    @computed_field
    @property
    def verification_level(self) -> int:
        """0 none · 1 email · 2 +teléfono · 3 +documento aprobado."""
        if not self.is_verified:
            return 0
        if not self.telefono_verificado:
            return 1
        if self.doc_estado != "approved":
            return 2
        return 3


class RegistroResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UsuarioResponse
