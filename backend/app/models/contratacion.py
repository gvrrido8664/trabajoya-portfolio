import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class EstadoContratacion(str, PyEnum):
    PENDIENTE = "PENDIENTE"
    ACEPTADO = "ACEPTADO"
    RECHAZADO = "RECHAZADO"
    COMPLETADO = "COMPLETADO"
    CANCELADO = "CANCELADO"
    DISPUTA = "DISPUTA"


class Contratacion(BaseModel):
    __tablename__ = "contrataciones"

    cliente_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    proveedor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    servicio_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("servicios.id"), nullable=True, index=True)
    propuesta_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("propuestas.id"), nullable=True)
    status: Mapped[EstadoContratacion] = mapped_column(
        Enum(EstadoContratacion, name="estado_contratacion"),
        default=EstadoContratacion.PENDIENTE,
        nullable=False,
    )
    monto_acordado: Mapped[float | None] = mapped_column(Float)
    mensaje_solicitud: Mapped[str | None] = mapped_column(Text)
    fecha_programada: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    cliente = relationship("Usuario", back_populates="contrataciones_cliente", foreign_keys=[cliente_id])
    proveedor = relationship("Usuario", back_populates="contrataciones_proveedor", foreign_keys=[proveedor_id])
    servicio = relationship("Servicio", back_populates="contrataciones", foreign_keys=[servicio_id])
    propuesta = relationship("Propuesta")
    mensajes = relationship("Mensaje", back_populates="contratacion")
    resenas = relationship("Resena", back_populates="contratacion")
    pago = relationship("Pago", back_populates="contratacion", uselist=False)
