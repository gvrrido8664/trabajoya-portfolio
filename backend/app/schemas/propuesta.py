from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PropuestaCreate(BaseModel):
    descripcion: str
    precio: float = Field(gt=0)
    tiempo_estimado: str


class PropuestaResponse(BaseModel):
    id: UUID
    solicitud_id: UUID
    proveedor_id: UUID
    descripcion: str
    precio: float
    tiempo_estimado: str
    status: str
    proveedor_nombre: str | None = None
    solicitud_titulo: str | None = None
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}
