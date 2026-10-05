from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_validator


class ContratacionCreate(BaseModel):
    servicio_id: UUID
    monto_acordado: float | None = None
    mensaje_solicitud: str | None = None
    fecha_programada: datetime | None = None


class ContratacionResponse(BaseModel):
    id: UUID
    cliente_id: UUID
    proveedor_id: UUID
    servicio_id: UUID | None = None
    propuesta_id: UUID | None = None
    status: str
    monto_acordado: float | None
    mensaje_solicitud: str | None
    fecha_programada: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ContratacionEnrichedResponse(BaseModel):
    id: UUID
    cliente_id: UUID
    proveedor_id: UUID
    servicio_id: UUID | None = None
    propuesta_id: UUID | None = None
    status: str
    monto_acordado: float | None
    mensaje_solicitud: str | None
    fecha_programada: datetime | None
    servicio_titulo: str | None = None
    cliente_nombre: str | None = None
    proveedor_nombre: str | None = None
    pago_status: str | None = None
    has_reviewed: bool = False
    created_at: datetime
    updated_at: datetime


class ResenaCreate(BaseModel):
    puntuacion: int
    comentario: str | None = None

    @field_validator("puntuacion")
    @classmethod
    def puntuacion_valida(cls, v: int) -> int:
        if v < 1 or v > 5:
            raise ValueError("La puntuacion debe estar entre 1 y 5")
        return v


class ResenaResponse(BaseModel):
    id: UUID
    contratacion_id: UUID
    calificador_id: UUID
    calificado_id: UUID
    puntuacion: int
    comentario: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
