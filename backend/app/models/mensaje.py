import uuid

from sqlalchemy import Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Mensaje(BaseModel):
    __tablename__ = "mensajes"

    contratacion_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("contrataciones.id"), nullable=False, index=True)
    emisor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    contenido: Mapped[str] = mapped_column(Text, nullable=False)
    leido: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    contratacion = relationship("Contratacion", back_populates="mensajes", foreign_keys=[contratacion_id])
