import uuid
from enum import Enum as PyEnum

from sqlalchemy import Boolean, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from geoalchemy2 import Geography

from app.models.base import BaseModel


class EstadoServicio(str, PyEnum):
    ACTIVO = "ACTIVO"
    PAUSADO = "PAUSADO"
    ELIMINADO = "ELIMINADO"


class Servicio(BaseModel):
    __tablename__ = "servicios"

    proveedor_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False, index=True)
    categoria_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("categorias.id"), nullable=False, index=True)
    subcategoria_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("subcategorias.id"), nullable=True, index=True)
    titulo: Mapped[str] = mapped_column(String(200), nullable=False)
    descripcion: Mapped[str] = mapped_column(Text, nullable=False)
    precio_min: Mapped[float | None] = mapped_column(Float)
    precio_max: Mapped[float | None] = mapped_column(Float)
    ubicacion: Mapped[str | None] = mapped_column(Geography("POINT", srid=4326))
    radio_cobertura_km: Mapped[int] = mapped_column(Integer, default=10, nullable=False)
    direccion_texto: Mapped[str | None] = mapped_column(String(500))
    status: Mapped[EstadoServicio] = mapped_column(
        Enum(EstadoServicio, name="estado_servicio"), default=EstadoServicio.ACTIVO, nullable=False
    )
    fotos: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    es_destacado: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    proveedor = relationship("Usuario", back_populates="servicios", foreign_keys=[proveedor_id])
    categoria = relationship("Categoria", back_populates="servicios", foreign_keys=[categoria_id])
    subcategoria = relationship("Subcategoria", back_populates="servicios", foreign_keys=[subcategoria_id])
    contrataciones = relationship("Contratacion", back_populates="servicio")
