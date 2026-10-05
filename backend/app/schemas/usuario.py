from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_validator


class UsuarioPublicResponse(BaseModel):
    """Perfil público de un usuario (sin PII: omite email, teléfono y código de referido)."""
    id: UUID
    nombre: str
    apellido: str
    avatar_url: str | None = None
    bio: str | None = None
    habilidades: str | None = None
    rol: str
    es_proveedor: bool = False
    avg_rating: float
    avg_rating_proveedor: float = 0.0
    avg_rating_cliente: float = 0.0
    is_verified: bool
    doc_estado: str
    created_at: datetime

    model_config = {"from_attributes": True}


class UsuarioUpdate(BaseModel):
    nombre: str | None = None
    apellido: str | None = None
    telefono: str | None = None
    bio: str | None = None
    habilidades: str | None = None
    avatar_url: str | None = None


class UbicacionUpdate(BaseModel):
    lat: float
    lng: float

    @field_validator("lat")
    @classmethod
    def latitud_valida(cls, v: float) -> float:
        if not -90 <= v <= 90:
            raise ValueError("Latitud debe estar entre -90 y 90")
        return v

    @field_validator("lng")
    @classmethod
    def longitud_valida(cls, v: float) -> float:
        if not -180 <= v <= 180:
            raise ValueError("Longitud debe estar entre -180 y 180")
        return v


class ProveedorResumen(BaseModel):
    id: UUID
    nombre: str
    apellido: str
    avatar_url: str | None
    avg_rating: float
    avg_rating_proveedor: float = 0.0
    bio: str | None

    model_config = {"from_attributes": True}
