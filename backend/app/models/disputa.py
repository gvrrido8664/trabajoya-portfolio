import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import BaseModel


class EstadoDisputa(str, PyEnum):
    ABIERTA = "ABIERTA"
    RESUELTA = "RESUELTA"


class Disputa(BaseModel):
    __tablename__ = "disputas"

    contratacion_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("contrataciones.id"), unique=True, nullable=False
    )
    abierta_por_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False
    )
    motivo: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[EstadoDisputa] = mapped_column(
        Enum(EstadoDisputa, name="estado_disputa"), default=EstadoDisputa.ABIERTA, nullable=False
    )
    resolucion: Mapped[str | None] = mapped_column(Text)
    action_tomada: Mapped[str | None] = mapped_column(String(50))
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
