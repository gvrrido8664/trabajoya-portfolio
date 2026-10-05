from uuid import UUID

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID as UUIDType
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Subcategoria(BaseModel):
    __tablename__ = "subcategorias"

    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    icono: Mapped[str | None] = mapped_column(String(50))
    descripcion: Mapped[str | None] = mapped_column(Text)
    categoria_id: Mapped[UUID] = mapped_column(
        UUIDType(as_uuid=True),
        ForeignKey("categorias.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    categoria = relationship("Categoria", lazy="selectin")
    servicios = relationship("Servicio", back_populates="subcategoria", foreign_keys="Servicio.subcategoria_id",
                              lazy="selectin")
