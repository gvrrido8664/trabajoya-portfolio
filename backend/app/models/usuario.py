import uuid
from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import BaseModel


class RolUsuario(str, PyEnum):
    CLIENTE = "cliente"
    PROVEEDOR = "proveedor"
    ADMIN = "admin"


class Usuario(BaseModel):
    __tablename__ = "usuarios"

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)  # nullable para cuentas OAuth
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    apellido: Mapped[str] = mapped_column(String(100), nullable=False)
    telefono: Mapped[str | None] = mapped_column(String(20))
    # Rol primario legacy (se conserva durante la transición a capacidades;
    # sigue siendo la fuente para distinguir admin y para stats/admin).
    rol: Mapped[RolUsuario] = mapped_column(Enum(RolUsuario, name="rol_usuario"), default=RolUsuario.CLIENTE, nullable=False)

    # --- Capacidades por rol (identidad única, modo activo en frontend) ---
    es_cliente: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    es_proveedor: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    proveedor_activado_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    auth_provider: Mapped[str] = mapped_column(String(20), default="local", nullable=False)  # local | google | apple
    google_id: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True, index=True)
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    bio: Mapped[str | None] = mapped_column(Text)
    habilidades: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # --- Verificación / MFA ---
    telefono_verificado: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    totp_secret: Mapped[str | None] = mapped_column(String(255))  # Base32 cifrado (Fernet)
    totp_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    backup_codes: Mapped[str | None] = mapped_column(Text)  # JSON: lista de hashes bcrypt (un solo uso)
    doc_estado: Mapped[str] = mapped_column(String(20), default="none", nullable=False)  # none/pending/approved/rejected
    doc_url: Mapped[str | None] = mapped_column(String(500))
    doc_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # --- Cuenta conectada del agregador (MP Connect) eliminada ---

    # --- MercadoPago Connect ---
    mp_access_token: Mapped[str | None] = mapped_column(String(255))
    mp_refresh_token: Mapped[str | None] = mapped_column(String(255))
    mp_user_id: Mapped[str | None] = mapped_column(String(255))
    mp_public_key: Mapped[str | None] = mapped_column(String(255))
    mp_configured: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    avg_rating: Mapped[float] = mapped_column(Float, default=0.0)  # legacy global; ver ratings por rol
    avg_rating_proveedor: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    avg_rating_cliente: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    codigo_referido: Mapped[str | None] = mapped_column(String(20), unique=True, index=True)
    referidos_count: Mapped[int] = mapped_column(default=0, nullable=False)
    referido_por: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=True)

    servicios = relationship("Servicio", back_populates="proveedor", lazy="selectin")
    contrataciones_cliente = relationship(
        "Contratacion", back_populates="cliente", foreign_keys="Contratacion.cliente_id", lazy="selectin"
    )
    contrataciones_proveedor = relationship(
        "Contratacion", back_populates="proveedor", foreign_keys="Contratacion.proveedor_id", lazy="selectin"
    )
    solicitudes = relationship("Solicitud", back_populates="cliente", lazy="selectin")
    propuestas = relationship("Propuesta", back_populates="proveedor", lazy="selectin")
    certificaciones = relationship("Certificacion", back_populates="proveedor", lazy="selectin", cascade="all, delete-orphan")
