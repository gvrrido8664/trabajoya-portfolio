from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class PagoCreate(BaseModel):
    contratacion_id: UUID


class PagoResponse(BaseModel):
    id: UUID
    contratacion_id: UUID
    monto: float
    status: str
    preference_id: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class PagoPreferenceResponse(BaseModel):
    id: str | None = None
    init_point: str
    sandbox_init_point: str | None = None
    preference_id: str | None = None
    external_reference: str | None = None
    status: str = "pending"
