from uuid import UUID

from pydantic import BaseModel


class CategoriaResponse(BaseModel):
    id: UUID
    nombre: str
    slug: str
    icono: str | None
    descripcion: str | None
    parent_id: UUID | None = None
    subcategorias: list["CategoriaResponse"] = []


CategoriaResponse.model_rebuild()
