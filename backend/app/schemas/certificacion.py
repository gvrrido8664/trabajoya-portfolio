from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field

class CertificacionBase(BaseModel):
    titulo: str = Field(..., max_length=100)
    institucion: str = Field(..., max_length=100)
    archivo_url: str = Field(..., max_length=500)
    fecha_emision: datetime | None = None

class CertificacionCreate(CertificacionBase):
    pass

class CertificacionResponse(CertificacionBase):
    id: UUID
    usuario_id: UUID
    estado: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
