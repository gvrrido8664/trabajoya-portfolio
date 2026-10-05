from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_admin
from app.database import get_db
from app.models import Categoria, Subcategoria, Usuario
from app.schemas import CategoriaResponse


class CategoriaCreate(BaseModel):
    nombre: str
    slug: str
    icono: str | None = None
    descripcion: str | None = None


class SubcategoriaCreate(BaseModel):
    nombre: str
    slug: str
    icono: str | None = None
    descripcion: str | None = None

router = APIRouter(prefix="/categorias", tags=["categorias"])


def _sub_to_dict(s: Subcategoria) -> dict:
    return {
        "id": str(s.id),
        "nombre": s.nombre,
        "slug": s.slug,
        "icono": s.icono,
        "descripcion": s.descripcion,
        "parent_id": str(s.categoria_id),
        "subcategorias": [],
    }


@router.get("", response_model=list[CategoriaResponse])
async def listar_categorias(
    db: AsyncSession = Depends(get_db),
):
    roots = (await db.execute(select(Categoria).order_by(Categoria.nombre))).scalars().all()
    subs = (await db.execute(select(Subcategoria).order_by(Subcategoria.nombre))).scalars().all()

    hijos_por_root = defaultdict(list)
    for s in subs:
        hijos_por_root[str(s.categoria_id)].append(_sub_to_dict(s))

    return [
        {
            "id": str(r.id),
            "nombre": r.nombre,
            "slug": r.slug,
            "icono": r.icono,
            "descripcion": r.descripcion,
            "parent_id": None,
            "subcategorias": hijos_por_root.get(str(r.id), []),
        }
        for r in roots
    ]


@router.get("/{slug}", response_model=CategoriaResponse)
async def get_categoria(slug: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Categoria).where(Categoria.slug == slug))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")

    subs = (await db.execute(
        select(Subcategoria).where(Subcategoria.categoria_id == cat.id).order_by(Subcategoria.nombre)
    )).scalars().all()

    return {
        "id": str(cat.id),
        "nombre": cat.nombre,
        "slug": cat.slug,
        "icono": cat.icono,
        "descripcion": cat.descripcion,
        "parent_id": None,
        "subcategorias": [_sub_to_dict(s) for s in subs],
    }


@router.get("/{id}/subcategorias", response_model=list[CategoriaResponse])
async def get_subcategorias(id: str, db: AsyncSession = Depends(get_db)):
    subs = (await db.execute(
        select(Subcategoria).where(Subcategoria.categoria_id == id).order_by(Subcategoria.nombre)
    )).scalars().all()
    return [_sub_to_dict(s) for s in subs]


@router.post("", response_model=CategoriaResponse, status_code=status.HTTP_201_CREATED)
async def crear_categoria(
    data: CategoriaCreate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    cat = Categoria(**data.model_dump())
    db.add(cat)
    await db.commit()
    await db.refresh(cat)
    return {
        "id": str(cat.id),
        "nombre": cat.nombre,
        "slug": cat.slug,
        "icono": cat.icono,
        "descripcion": cat.descripcion,
        "parent_id": None,
        "subcategorias": [],
    }


@router.put("/{id}", response_model=CategoriaResponse)
async def editar_categoria(
    id: str,
    data: CategoriaCreate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Categoria).where(Categoria.id == id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(cat, key, value)
    
    await db.commit()
    await db.refresh(cat)
    
    subs = (await db.execute(
        select(Subcategoria).where(Subcategoria.categoria_id == cat.id).order_by(Subcategoria.nombre)
    )).scalars().all()
    
    return {
        "id": str(cat.id),
        "nombre": cat.nombre,
        "slug": cat.slug,
        "icono": cat.icono,
        "descripcion": cat.descripcion,
        "parent_id": None,
        "subcategorias": [_sub_to_dict(s) for s in subs],
    }


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_categoria(
    id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Categoria).where(Categoria.id == id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
    
    await db.delete(cat)
    await db.commit()
    return None


@router.post("/{id}/subcategorias", status_code=status.HTTP_201_CREATED)
async def crear_subcategoria(
    id: str,
    data: SubcategoriaCreate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Categoria).where(Categoria.id == id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Categoria no encontrada")
        
    sub = Subcategoria(**data.model_dump(), categoria_id=id)
    db.add(sub)
    await db.commit()
    await db.refresh(sub)
    return _sub_to_dict(sub)


@router.put("/subcategorias/{sub_id}")
async def editar_subcategoria(
    sub_id: str,
    data: SubcategoriaCreate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Subcategoria).where(Subcategoria.id == sub_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subcategoria no encontrada")
    
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(sub, key, value)
        
    await db.commit()
    await db.refresh(sub)
    return _sub_to_dict(sub)


@router.delete("/subcategorias/{sub_id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar_subcategoria(
    sub_id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Subcategoria).where(Subcategoria.id == sub_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subcategoria no encontrada")
    
    await db.delete(sub)
    await db.commit()
    return None
