from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class DisputaCreate(BaseModel):
    motivo: str
    evidencias: list[str] | None = None


class DisputaResponse(BaseModel):
    id: UUID
    contratacion_id: UUID
    abierta_por_id: UUID
    motivo: str
    evidencias: list[str] | None = None
    status: str
    resolucion: str | None = None
    action_tomada: str | None = None
    created_at: datetime
    resolved_at: datetime | None = None

    model_config = {"from_attributes": True}
