import uuid
from enum import Enum as PyEnum

from sqlalchemy import Boolean, Enum, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class EstadoPago(str, PyEnum):
    PENDIENTE = "PENDIENTE"
    APROBADO = "APROBADO"
    RECHAZADO = "RECHAZADO"
    CANCELADO = "CANCELADO"


class MetodoPago(str, PyEnum):
    MERCADOPAGO = "MERCADOPAGO"
    WEBPAY = "WEBPAY"
    ACORDAR_EN_PERSONA = "ACORDAR_EN_PERSONA"


class Pago(BaseModel):
    __tablename__ = "pagos"

    contratacion_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("contrataciones.id"), unique=True, nullable=False, index=True)
    monto: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[EstadoPago] = mapped_column(
        Enum(EstadoPago, name="estado_pago"), default=EstadoPago.PENDIENTE, nullable=False
    )
    metodo_pago: Mapped[MetodoPago] = mapped_column(
        Enum(MetodoPago, name="metodo_pago"), default=MetodoPago.MERCADOPAGO, nullable=False
    )
    preference_id: Mapped[str | None] = mapped_column(String(255))
    mp_payment_id: Mapped[str | None] = mapped_column(String(255), unique=True)
    webpay_token: Mapped[str | None] = mapped_column(String(255))
    webpay_tbk_id: Mapped[str | None] = mapped_column(String(255))
    payout_status: Mapped[str | None] = mapped_column(String(16))
    fintoc_transfer_id: Mapped[str | None] = mapped_column(String(128))

    contratacion = relationship("Contratacion", back_populates="pago", foreign_keys=[contratacion_id])
