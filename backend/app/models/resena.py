import uuid

from sqlalchemy import Float, ForeignKey, Integer, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Resena(BaseModel):
    __tablename__ = "resenas"
    __table_args__ = (
        UniqueConstraint("contratacion_id", "calificador_id", name="uix_resena_contratacion_calificador"),
    )

    contratacion_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("contrataciones.id"), nullable=False)
    calificador_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    calificado_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    puntuacion: Mapped[int] = mapped_column(Integer, nullable=False)
    comentario: Mapped[str | None] = mapped_column(Text)

    contratacion = relationship("Contratacion", back_populates="resenas", foreign_keys=[contratacion_id])
