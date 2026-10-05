from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class OtroUsuario(BaseModel):
    id: UUID
    nombre: str
    avatar_url: str | None = None
    is_online: bool = False  # <-- ¡ESTO ES LO QUE FALTABA!


class MensajeResponse(BaseModel):
    id: UUID
    contratacion_id: UUID
    emisor_id: UUID
    contenido: str
    leido: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ConversacionResumen(BaseModel):
    contratacion_id: UUID
    servicio_titulo: str | None = None
    otro_usuario: OtroUsuario | None = None
    otro_usuario_nombre: str | None = None
    ultimo_mensaje: str | None
    ultimo_mensaje_fecha: datetime | None
    mensajes_no_leidos: int
    leido: bool = True
    updated_at: datetime | None = None


class MensajeEnviar(BaseModel):
    contenido: str
