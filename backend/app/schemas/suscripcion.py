from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class PlanResponse(BaseModel):
    id: UUID
    nombre: str
    descripcion: str | None
    beneficios: list[str] | None
    precio_mensual: float

    model_config = {"from_attributes": True}


class SuscripcionCreate(BaseModel):
    plan_id: UUID


class SuscripcionResponse(BaseModel):
    id: UUID
    usuario_id: UUID
    plan_id: UUID
    plan_slug: str | None = None
    plan_nombre: str | None = None
    status: str
    fecha_inicio: datetime
    fecha_vencimiento: datetime | None
    precio_mensual: float | None = None

    model_config = {"from_attributes": True}
