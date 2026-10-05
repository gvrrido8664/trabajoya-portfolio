from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class BugReportCreate(BaseModel):
    titulo: str
    descripcion: str
    area: str = "otro"


class BugReportResponse(BaseModel):
    id: UUID
    usuario_id: UUID
    titulo: str
    descripcion: str
    area: str
    status: str
    created_at: datetime
    resolved_at: datetime | None = None

    model_config = {"from_attributes": True}
