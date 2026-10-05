from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user
from app.database import get_db
from app.models import (
    Contratacion,
    EstadoContratacion,
    Propuesta,
    RolUsuario,
    Solicitud,
    StatusPropuesta,
    StatusSolicitud,
    Usuario,
)
from app.schemas import PropuestaCreate, PropuestaResponse

router = APIRouter(prefix="/solicitudes/{solicitud_id}/propuestas", tags=["propuestas"])
propuestas_router = APIRouter(prefix="/propuestas", tags=["propuestas"])


@router.post("", response_model=PropuestaResponse, status_code=status.HTTP_201_CREATED)
async def crear_propuesta(
    solicitud_id: str,
    data: PropuestaCreate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not (current_user.es_proveedor or current_user.rol.value == "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Activa el modo proveedor para enviar propuestas")

    from datetime import datetime, timezone
    from app.models import Suscripcion, EstadoSuscripcion
    
    result_sub = await db.execute(
        select(Suscripcion)
        .options(selectinload(Suscripcion.plan))
        .where(
            Suscripcion.usuario_id == current_user.id, 
            Suscripcion.status == EstadoSuscripcion.ACTIVA
        )
        .order_by(Suscripcion.created_at.desc())
        .limit(1)
    )
    sub = result_sub.scalar_one_or_none()
    
    is_active = False
    if sub and sub.plan:
        if sub.fecha_vencimiento is None or sub.fecha_vencimiento > datetime.now(timezone.utc):
            is_active = True
            
    plan_slug = sub.plan.slug if (sub and sub.plan and is_active) else "basico"
    
    if plan_slug == "basico":
        result_count = await db.execute(
            select(func.count(Propuesta.id)).where(
                Propuesta.proveedor_id == current_user.id,
                Propuesta.status == StatusPropuesta.PENDIENTE
            )
        )
        propuestas_pendientes = result_count.scalar() or 0
        if propuestas_pendientes >= 3:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Límite alcanzado: el plan Básico permite un máximo de 3 propuestas pendientes simultáneas."
            )

    result = await db.execute(select(Solicitud).where(Solicitud.id == solicitud_id))
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud.status != StatusSolicitud.ABIERTA:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La solicitud ya está cerrada")
    if solicitud.cliente_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes enviar una propuesta a tu propia solicitud")

    # Verificar que no haya enviado propuesta duplicada
    existing = await db.execute(
        select(Propuesta).where(
            Propuesta.solicitud_id == solicitud_id,
            Propuesta.proveedor_id == current_user.id,
            Propuesta.status == StatusPropuesta.PENDIENTE,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya enviaste una propuesta para esta solicitud")

    propuesta = Propuesta(
        solicitud_id=solicitud.id,
        proveedor_id=current_user.id,
        descripcion=data.descripcion,
        precio=data.precio,
        tiempo_estimado=data.tiempo_estimado,
        status=StatusPropuesta.PENDIENTE,
    )
    db.add(propuesta)
    await db.commit()
    await db.refresh(propuesta)

    return {
        "id": propuesta.id,
        "solicitud_id": propuesta.solicitud_id,
        "proveedor_id": propuesta.proveedor_id,
        "descripcion": propuesta.descripcion,
        "precio": propuesta.precio,
        "tiempo_estimado": propuesta.tiempo_estimado,
        "status": propuesta.status.value,
        "proveedor_nombre": f"{current_user.nombre} {current_user.apellido}",
        "solicitud_titulo": solicitud.titulo,
        "created_at": propuesta.created_at,
        "updated_at": propuesta.updated_at,
    }


@router.get("", response_model=list[PropuestaResponse])
async def listar_propuestas(
    solicitud_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Solicitud).where(Solicitud.id == solicitud_id))
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud.cliente_id != current_user.id and current_user.rol.value != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta solicitud")

    result = await db.execute(
        select(Propuesta)
        .options(selectinload(Propuesta.proveedor))
        .where(Propuesta.solicitud_id == solicitud_id)
        .order_by(Propuesta.created_at.desc())
    )
    propuestas = result.scalars().all()

    response = []
    for p in propuestas:
        proveedor = p.proveedor
        response.append({
            "id": p.id,
            "solicitud_id": p.solicitud_id,
            "proveedor_id": p.proveedor_id,
            "descripcion": p.descripcion,
            "precio": p.precio,
            "tiempo_estimado": p.tiempo_estimado,
            "status": p.status.value,
            "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else None,
            "solicitud_titulo": solicitud.titulo,
            "created_at": p.created_at,
            "updated_at": p.updated_at,
        })
    return response


@router.patch("/{propuesta_id}/aceptar")
async def aceptar_propuesta(
    solicitud_id: str,
    propuesta_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Solicitud).where(Solicitud.id == solicitud_id))
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud.cliente_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo el cliente puede aceptar propuestas")
    if solicitud.status != StatusSolicitud.ABIERTA:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La solicitud ya está cerrada")

    result = await db.execute(
        select(Propuesta).where(Propuesta.id == propuesta_id, Propuesta.solicitud_id == solicitud_id)
    )
    propuesta = result.scalar_one_or_none()
    if not propuesta:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Propuesta no encontrada")
    if propuesta.status != StatusPropuesta.PENDIENTE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La propuesta ya fue respondida")

    # Aceptar propuesta
    propuesta.status = StatusPropuesta.ACEPTADA

    # Rechazar las otras propuestas pendientes
    otras = await db.execute(
        select(Propuesta).where(
            Propuesta.solicitud_id == solicitud_id,
            Propuesta.id != propuesta_id,
            Propuesta.status == StatusPropuesta.PENDIENTE,
        )
    )
    for otra in otras.scalars().all():
        otra.status = StatusPropuesta.RECHAZADA

    # Cerrar solicitud
    solicitud.status = StatusSolicitud.CERRADA

    # Crear contratacion
    contratacion = Contratacion(
        cliente_id=current_user.id,
        proveedor_id=propuesta.proveedor_id,
        servicio_id=None,
        propuesta_id=propuesta.id,
        status=EstadoContratacion.ACEPTADO,
        monto_acordado=propuesta.precio,
        mensaje_solicitud=solicitud.descripcion,
    )
    db.add(contratacion)
    await db.commit()
    await db.refresh(contratacion)
    await db.refresh(propuesta)

    result_pv = await db.execute(select(Usuario).where(Usuario.id == propuesta.proveedor_id))
    proveedor = result_pv.scalar_one_or_none()

    return {
        "id": propuesta.id,
        "solicitud_id": propuesta.solicitud_id,
        "proveedor_id": propuesta.proveedor_id,
        "descripcion": propuesta.descripcion,
        "precio": propuesta.precio,
        "tiempo_estimado": propuesta.tiempo_estimado,
        "status": propuesta.status.value,
        "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else None,
        "solicitud_titulo": solicitud.titulo,
        "contratacion_id": str(contratacion.id),
        "created_at": propuesta.created_at,
        "updated_at": propuesta.updated_at,
    }


@router.patch("/{propuesta_id}/rechazar")
async def rechazar_propuesta(
    solicitud_id: str,
    propuesta_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Solicitud).where(Solicitud.id == solicitud_id))
    solicitud = result.scalar_one_or_none()
    if not solicitud:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Solicitud no encontrada")
    if solicitud.cliente_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo el cliente puede rechazar propuestas")

    result = await db.execute(
        select(Propuesta).where(Propuesta.id == propuesta_id, Propuesta.solicitud_id == solicitud_id)
    )
    propuesta = result.scalar_one_or_none()
    if not propuesta:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Propuesta no encontrada")
    if propuesta.status != StatusPropuesta.PENDIENTE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La propuesta ya fue respondida")

    propuesta.status = StatusPropuesta.RECHAZADA
    await db.commit()

    return {
        "id": propuesta.id,
        "solicitud_id": propuesta.solicitud_id,
        "proveedor_id": propuesta.proveedor_id,
        "status": propuesta.status.value,
    }


@propuestas_router.get("/mis-propuestas")
async def listar_mis_propuestas(
    current_user: Usuario = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Propuesta)
        .options(selectinload(Propuesta.solicitud))
        .where(Propuesta.proveedor_id == current_user.id)
        .order_by(Propuesta.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    propuestas = result.scalars().all()

    response = []
    for p in propuestas:
        solicitud = p.solicitud
        response.append({
            "id": p.id,
            "solicitud_id": p.solicitud_id,
            "proveedor_id": p.proveedor_id,
            "descripcion": p.descripcion,
            "precio": p.precio,
            "tiempo_estimado": p.tiempo_estimado,
            "status": p.status.value,
            "proveedor_nombre": f"{current_user.nombre} {current_user.apellido}",
            "solicitud_titulo": solicitud.titulo if solicitud else None,
            "created_at": p.created_at,
            "updated_at": p.updated_at,
        })
    return response
