from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_validator


class ServicioCreate(BaseModel):
    categoria_id: UUID
    subcategoria_id: UUID | None = None
    titulo: str
    descripcion: str
    precio_min: float | None = None
    precio_max: float | None = None
    radio_cobertura_km: int = 10
    direccion_texto: str | None = None
    fotos: list[str] | None = None
    latitud: float | None = None
    longitud: float | None = None

    @field_validator("precio_min", "precio_max")
    @classmethod
    def precio_no_negativo(cls, v: float | None) -> float | None:
        if v is not None and v < 0:
            raise ValueError("El precio no puede ser negativo")
        return v

    @field_validator("radio_cobertura_km")
    @classmethod
    def radio_positivo(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("El radio de cobertura debe ser mayor a 0")
        return v


class ServicioUpdate(BaseModel):
    categoria_id: UUID | None = None
    subcategoria_id: UUID | None = None
    titulo: str | None = None
    descripcion: str | None = None
    precio_min: float | None = None
    precio_max: float | None = None
    radio_cobertura_km: int | None = None
    direccion_texto: str | None = None
    fotos: list[str] | None = None
    latitud: float | None = None
    longitud: float | None = None


class ServicioResponse(BaseModel):
    id: UUID
    proveedor_id: UUID
    categoria_id: UUID
    subcategoria_id: UUID | None = None
    titulo: str
    descripcion: str
    status: str
    precio_min: float | None
    precio_max: float | None
    radio_cobertura_km: int
    direccion_texto: str | None
    fotos: list[str] | None
    es_destacado: bool
    distancia: float | None = None
    proveedor_nombre: str | None = None
    proveedor_rating: float | None = None
    proveedor_doc_estado: str | None = None
    categoria_nombre: str | None = None
    subcategoria_nombre: str | None = None
    latitud: float | None = None
    longitud: float | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
