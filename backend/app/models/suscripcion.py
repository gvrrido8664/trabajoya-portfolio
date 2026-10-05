import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import DateTime, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class EstadoSuscripcion(str, PyEnum):
    ACTIVA = "ACTIVA"
    CANCELADA = "CANCELADA"
    VENCIDA = "VENCIDA"


class Suscripcion(BaseModel):
    __tablename__ = "suscripciones"

    usuario_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    plan_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("planes.id"), nullable=False)
    status: Mapped[EstadoSuscripcion] = mapped_column(
        Enum(EstadoSuscripcion, name="estado_suscripcion"), default=EstadoSuscripcion.ACTIVA, nullable=False
    )
    fecha_inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    fecha_vencimiento: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    plan = relationship("Plan", back_populates="suscripciones", foreign_keys=[plan_id])
