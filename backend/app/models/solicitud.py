import uuid
from enum import Enum as PyEnum

from sqlalchemy import Enum as SAEnum, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class StatusSolicitud(str, PyEnum):
    ABIERTA = "ABIERTA"
    CERRADA = "CERRADA"


class Solicitud(BaseModel):
    __tablename__ = "solicitudes"

    cliente_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    categoria_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("categorias.id"), nullable=True)
    titulo: Mapped[str] = mapped_column(String(200), nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    presupuesto_max: Mapped[float | None] = mapped_column(Float, nullable=True)
    ubicacion_texto: Mapped[str | None] = mapped_column(String(200), nullable=True)
    status: Mapped[StatusSolicitud] = mapped_column(
        SAEnum(StatusSolicitud, name="status_solicitud"),
        default=StatusSolicitud.ABIERTA,
        nullable=False,
    )

    cliente = relationship("Usuario", back_populates="solicitudes")
    categoria = relationship("Categoria")
    propuestas = relationship("Propuesta", back_populates="solicitud")
