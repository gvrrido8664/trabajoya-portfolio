from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Categoria(BaseModel):
    __tablename__ = "categorias"

    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    icono: Mapped[str | None] = mapped_column(String(50))
    descripcion: Mapped[str | None] = mapped_column(Text)
    servicios = relationship("Servicio", back_populates="categoria", foreign_keys="Servicio.categoria_id",
                              lazy="selectin")
