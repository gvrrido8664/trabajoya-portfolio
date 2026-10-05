import uuid
from enum import Enum as PyEnum

from sqlalchemy import Enum as SAEnum, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class StatusPropuesta(str, PyEnum):
    PENDIENTE = "PENDIENTE"
    ACEPTADA = "ACEPTADA"
    RECHAZADA = "RECHAZADA"
    CANCELADA = "CANCELADA"


class Propuesta(BaseModel):
    __tablename__ = "propuestas"

    solicitud_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("solicitudes.id"), nullable=False, index=True)
    proveedor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    precio: Mapped[float] = mapped_column(Float, nullable=False)
    tiempo_estimado: Mapped[str] = mapped_column(String(100), nullable=False)
    status: Mapped[StatusPropuesta] = mapped_column(
        SAEnum(StatusPropuesta, name="status_propuesta"),
        default=StatusPropuesta.PENDIENTE,
        nullable=False,
    )

    solicitud = relationship("Solicitud", back_populates="propuestas")
    proveedor = relationship("Usuario", back_populates="propuestas")
