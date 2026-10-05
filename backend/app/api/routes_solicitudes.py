from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user, require_email_verificado
from app.database import get_db
from app.models import Categoria, Solicitud, StatusSolicitud, Subcategoria, Usuario
from app.schemas import SolicitudCreate, SolicitudResponse

router = APIRouter(prefix="/solicitudes", tags=["solicitudes"])


@router.post("", response_model=SolicitudResponse, status_code=status.HTTP_201_CREATED)
async def crear_solicitud(
    data: SolicitudCreate,
    current_user: Usuario = Depends(require_email_verificado),
    db: AsyncSession = Depends(get_db),
):
    if not (current_user.es_cliente or current_user.rol.value == "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tu cuenta no tiene habilitadas las funciones de cliente")

    # Si categoria_id es una subcategoría, resolvemos al padre (FK apunta a `categorias`)
    categoria_id = data.categoria_id
    if categoria_id:
        cat_check = await db.execute(select(Categoria).where(Categoria.id == categoria_id))
        if not cat_check.scalar_one_or_none():
            sub_check = await db.execute(select(Subcategoria).where(Subcategoria.id == categoria_id))
            sub = sub_check.scalar_one_or_none()
            categoria_id = sub.categoria_id if sub else None

    solicitud = Solicitud(
        cliente_id=current_user.id,
        categoria_id=categoria_id,
        titulo=data.titulo,
        descripcion=data.descripcion,
        presupuesto_max=data.presupuesto_max,
        ubicacion_texto=data.ubicacion_texto,
        status=StatusSolicitud.ABIERTA,
    )
    db.add(solicitud)
    await db.commit()
    await db.refresh(solicitud)
    return {
        "id": solicitud.id,
        "cliente_id": solicitud.cliente_id,
        "categoria_id": solicitud.categoria_id,
        "titulo": solicitud.titulo,
        "descripcion": solicitud.descripcion,
        "presupuesto_max": solicitud.presupuesto_max,
        "ubicacion_texto": solicitud.ubicacion_texto,
        "status": solicitud.status.value,
        "cliente_nombre": f"{current_user.nombre} {current_user.apellido}",
        "propuestas_count": 0,
        "created_at": solicitud.created_at,
        "updated_at": solicitud.updated_at,
    }


@router.get("")
async def listar_solicitudes(
    categoria_id: str | None = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    base_query = select(Solicitud).where(Solicitud.status == StatusSolicitud.ABIERTA)
    if categoria_id:
        base_query = base_query.where(Solicitud.categoria_id == categoria_id)

    count_result = await db.execute(select(func.count()).select_from(base_query.subquery()))
    total = count_result.scalar() or 0

    query = (
        base_query
        .options(selectinload(Solicitud.cliente), selectinload(Solicitud.propuestas))
        .offset(skip)
        .limit(limit)
        .order_by(Solicitud.created_at.desc())
    )
    result = await db.execute(query)
    solicitudes = result.scalars().all()

    response = []
    for s in solicitudes:
        cliente = s.cliente
        categoria_nombre = None
        if s.categoria_id:
            cat_result = await db.execute(select(Categoria).where(Categoria.id == s.categoria_id))
            cat = cat_result.scalar_one_or_none()
            categoria_nombre = cat.nombre if cat else None
        response.append({
            "id": s.id,
            "cliente_id": s.cliente_id,
            "categoria_id": s.categoria_id,
            "categoria_nombre": categoria_nombre,
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "presupuesto_max": s.presupuesto_max,
            "ubicacion_texto": s.ubicacion_texto,
            "status": s.status.value,
            "cliente_nombre": f"{cliente.nombre} {cliente.apellido}" if cliente else None,
            "propuestas_count": len(s.propuestas) if s.propuestas else 0,
            "created_at": s.created_at,
            "updated_at": s.updated_at,
        })
    return {"total": total, "limit": limit, "offset": skip, "items": response}


@router.get("/mis-solicitudes", response_model=list[SolicitudResponse])
async def listar_mis_solicitudes(
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Solicitud)
        .options(selectinload(Solicitud.propuestas))
        .where(Solicitud.cliente_id == current_user.id)
        .order_by(Solicitud.created_at.desc())
    )
    solicitudes = result.scalars().all()

    response = []
    for s in solicitudes:
        response.append({
            "id": s.id,
            "cliente_id": s.cliente_id,
            "categoria_id": s.categoria_id,
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "presupuesto_max": s.presupuesto_max,
            "ubicacion_texto": s.ubicacion_texto,
            "status": s.status.value,
            "cliente_nombre": f"{current_user.nombre} {current_user.apellido}",
            "propuestas_count": len(s.propuestas) if s.propuestas else 0,
            "created_at": s.created_at,
            "updated_at": s.updated_at,
        })
    return response


@router.patch("/{solicitud_id}/cerrar")
async def cerrar_solicitud(
    solicitud_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Solicitud).where(Solicitud.id == solicitud_id))
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud.cliente_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo el cliente puede cerrar la solicitud")
    if solicitud.status != StatusSolicitud.ABIERTA:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La solicitud ya está cerrada")

    solicitud.status = StatusSolicitud.CERRADA
    await db.commit()
    return {"status": solicitud.status.value}


@router.get("/{solicitud_id}", response_model=SolicitudResponse)
async def get_solicitud(
    solicitud_id: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Solicitud)
        .options(selectinload(Solicitud.cliente), selectinload(Solicitud.propuestas))
        .where(Solicitud.id == solicitud_id)
    )
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")

    cliente = solicitud.cliente
    propuestas_count = len(solicitud.propuestas) if solicitud.propuestas else 0

    return {
        "id": solicitud.id,
        "cliente_id": solicitud.cliente_id,
        "categoria_id": solicitud.categoria_id,
        "titulo": solicitud.titulo,
        "descripcion": solicitud.descripcion,
        "presupuesto_max": solicitud.presupuesto_max,
        "ubicacion_texto": solicitud.ubicacion_texto,
        "status": solicitud.status.value,
        "cliente_nombre": f"{cliente.nombre} {cliente.apellido}" if cliente else None,
        "propuestas_count": propuestas_count,
        "created_at": solicitud.created_at,
        "updated_at": solicitud.updated_at,
    }
