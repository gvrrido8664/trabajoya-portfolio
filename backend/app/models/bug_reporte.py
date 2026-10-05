import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import BaseModel


class AreaBug(str, PyEnum):
    DISENO = "DISENO"
    FUNCION = "FUNCION"
    LOGICA = "LOGICA"
    OTRO = "OTRO"


class EstadoBug(str, PyEnum):
    ABIERTO = "ABIERTO"
    EN_PROCESO = "EN_PROCESO"
    RESUELTO = "RESUELTO"


class BugReport(BaseModel):
    __tablename__ = "bug_reportes"

    usuario_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    titulo: Mapped[str] = mapped_column(String(200), nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    area: Mapped[AreaBug] = mapped_column(
        Enum(AreaBug, name="area_bug"), default=AreaBug.OTRO, nullable=False
    )
    status: Mapped[EstadoBug] = mapped_column(
        Enum(EstadoBug, name="estado_bug"), default=EstadoBug.ABIERTO, nullable=False
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
