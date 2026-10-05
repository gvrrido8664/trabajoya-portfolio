from datetime import datetime
import uuid
from sqlalchemy import String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Certificacion(BaseModel):
    __tablename__ = "certificaciones"

    usuario_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False)
    titulo: Mapped[str] = mapped_column(String(100), nullable=False)
    institucion: Mapped[str] = mapped_column(String(100), nullable=False)
    archivo_url: Mapped[str] = mapped_column(String(500), nullable=False)
    estado: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)  # pending, approved, rejected
    fecha_emision: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    proveedor = relationship("Usuario", back_populates="certificaciones", lazy="selectin")
