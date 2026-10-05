from sqlalchemy import Float, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class Plan(BaseModel):
    __tablename__ = "planes"

    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    descripcion: Mapped[str | None] = mapped_column(Text)
    beneficios: Mapped[list[str] | None] = mapped_column(ARRAY(String))
    precio_mensual: Mapped[float] = mapped_column(Float, nullable=False)

    suscripciones = relationship("Suscripcion", back_populates="plan", lazy="selectin")
