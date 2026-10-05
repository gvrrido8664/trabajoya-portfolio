from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SolicitudCreate(BaseModel):
    titulo: str
    descripcion: str
    categoria_id: UUID | None = None
    presupuesto_max: float | None = None
    ubicacion_texto: str | None = None


class SolicitudResponse(BaseModel):
    id: UUID
    cliente_id: UUID
    categoria_id: UUID | None = None
    titulo: str
    descripcion: str
    presupuesto_max: float | None = None
    ubicacion_texto: str | None = None
    status: str
    cliente_nombre: str | None = None
    propuestas_count: int = 0
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"from_attributes": True}
