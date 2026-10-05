from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user, require_email_verificado
from app.database import get_db
from app.models import (
    Contratacion,
    EstadoContratacion,
    EstadoPago,
    EstadoServicio,
    Pago,
    Propuesta,
    Resena,
    Servicio,
    Solicitud,
    Usuario,
)
from app.schemas import (
    ContratacionCreate,
    ContratacionResponse,
    ResenaCreate,
    ResenaResponse,
)
from app.services.rating_service import crear_resena as crear_resena_service

router = APIRouter(prefix="/contrataciones", tags=["contrataciones"])


@router.post("", response_model=ContratacionResponse, status_code=status.HTTP_201_CREATED)
async def crear_contratacion(
    data: ContratacionCreate,
    current_user: Usuario = Depends(require_email_verificado),
    db: AsyncSession = Depends(get_db),
):
    if not (current_user.es_cliente or current_user.rol.value == "admin"):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tu cuenta no tiene habilitadas las funciones de cliente")

    result = await db.execute(
        select(Servicio).where(Servicio.id == data.servicio_id, Servicio.status == EstadoServicio.ACTIVO)
    )
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado o inactivo")
    if servicio.proveedor_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No puedes contratar tu propio servicio")

    monto_final = data.monto_acordado if data.monto_acordado is not None else servicio.precio_min

    contratacion = Contratacion(
        cliente_id=current_user.id,
        proveedor_id=servicio.proveedor_id,
        servicio_id=servicio.id,
        monto_acordado=monto_final,
        mensaje_solicitud=data.mensaje_solicitud,
        fecha_programada=data.fecha_programada,
    )
    db.add(contratacion)
    await db.commit()
    await db.refresh(contratacion)
    return contratacion


@router.get("")
async def listar_contrataciones(
    current_user: Usuario = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    base_query = select(Contratacion).where(
        (Contratacion.cliente_id == current_user.id) | (Contratacion.proveedor_id == current_user.id)
    )
    count_result = await db.execute(select(func.count()).select_from(base_query.subquery()))
    total = count_result.scalar() or 0

    query = (
        base_query
        .options(
            selectinload(Contratacion.cliente),
            selectinload(Contratacion.proveedor),
            selectinload(Contratacion.servicio),
            selectinload(Contratacion.propuesta).selectinload(Propuesta.solicitud),
            selectinload(Contratacion.pago),
            selectinload(Contratacion.resenas),
        )
        .offset(skip)
        .limit(limit)
        .order_by(Contratacion.created_at.desc())
    )
    result = await db.execute(query)
    contrataciones = result.scalars().all()

    enriched = []
    for c in contrataciones:
        cliente = c.cliente
        proveedor = c.proveedor

        servicio_titulo = ""
        if c.servicio:
            servicio_titulo = c.servicio.titulo
        elif c.propuesta and c.propuesta.solicitud:
            servicio_titulo = c.propuesta.solicitud.titulo
        elif c.propuesta:
            servicio_titulo = "Propuesta aceptada"

        enriched.append({
            "id": str(c.id),
            "cliente_id": str(c.cliente_id),
            "proveedor_id": str(c.proveedor_id),
            "servicio_id": str(c.servicio_id) if c.servicio_id else None,
            "propuesta_id": str(c.propuesta_id) if c.propuesta_id else None,
            "status": c.status.value.upper(),
            "monto_acordado": c.monto_acordado,
            "mensaje_solicitud": c.mensaje_solicitud,
            "fecha_programada": c.fecha_programada.isoformat() if c.fecha_programada else None,
            "cliente_nombre": f"{cliente.nombre} {cliente.apellido}" if cliente else "",
            "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else "",
            "servicio_titulo": servicio_titulo,
            "pago_status": c.pago.status.value.upper() if c.pago else None,
            "payout_status": c.pago.payout_status if c.pago else None,
            "has_reviewed": any(r.calificador_id == current_user.id for r in c.resenas),
            "created_at": c.created_at.isoformat(),
            "updated_at": c.updated_at.isoformat(),
        })
    return {"total": total, "limit": limit, "offset": skip, "items": enriched}


@router.get("/{contratacion_id}")
async def get_contratacion(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Contratacion)
        .options(
            selectinload(Contratacion.cliente),
            selectinload(Contratacion.proveedor),
            selectinload(Contratacion.servicio).selectinload(Servicio.categoria),
            selectinload(Contratacion.servicio).selectinload(Servicio.subcategoria),
            selectinload(Contratacion.propuesta).selectinload(Propuesta.solicitud),
            selectinload(Contratacion.pago),
            selectinload(Contratacion.resenas),
        )
        .where(Contratacion.id == contratacion_id)
    )
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if contratacion.cliente_id != current_user.id and contratacion.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta contratación")

    cliente = contratacion.cliente
    proveedor = contratacion.proveedor

    categoria_nombre = None
    categoria_icono = None
    subcategoria_nombre = None
    subcategoria_icono = None
    if contratacion.servicio:
        if contratacion.servicio.categoria:
            cat = contratacion.servicio.categoria
            categoria_nombre = cat.nombre
            categoria_icono = cat.icono
        if contratacion.servicio.subcategoria:
            sub = contratacion.servicio.subcategoria
            subcategoria_nombre = sub.nombre
            subcategoria_icono = sub.icono

    servicio_titulo = ""
    if contratacion.servicio:
        servicio_titulo = contratacion.servicio.titulo
    elif contratacion.propuesta and contratacion.propuesta.solicitud:
        servicio_titulo = contratacion.propuesta.solicitud.titulo
    elif contratacion.propuesta:
        servicio_titulo = "Propuesta aceptada"

    return {
        "id": str(contratacion.id),
        "cliente_id": str(contratacion.cliente_id),
        "proveedor_id": str(contratacion.proveedor_id),
        "servicio_id": str(contratacion.servicio_id) if contratacion.servicio_id else None,
        "propuesta_id": str(contratacion.propuesta_id) if contratacion.propuesta_id else None,
        "status": contratacion.status.value.upper(),
        "monto_acordado": contratacion.monto_acordado,
        "mensaje_solicitud": contratacion.mensaje_solicitud,
        "fecha_programada": contratacion.fecha_programada.isoformat() if contratacion.fecha_programada else None,
        "cliente_nombre": f"{cliente.nombre} {cliente.apellido}" if cliente else "",
        "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else "",
        "servicio_titulo": servicio_titulo,
        "categoria_nombre": categoria_nombre,
        "categoria_icono": categoria_icono,
        "subcategoria_nombre": subcategoria_nombre,
        "subcategoria_icono": subcategoria_icono,
        "pago_status": contratacion.pago.status.value.upper() if contratacion.pago else None,
        "payout_status": contratacion.pago.payout_status if contratacion.pago else None,
        "has_reviewed": any(r.calificador_id == current_user.id for r in contratacion.resenas),
        "created_at": contratacion.created_at.isoformat(),
        "updated_at": contratacion.updated_at.isoformat(),
    }


@router.patch("/{contratacion_id}/aceptar")
async def aceptar_contratacion(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Contratacion).where(
            Contratacion.id == contratacion_id, Contratacion.proveedor_id == current_user.id
        )
    )
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if contratacion.status != EstadoContratacion.PENDIENTE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La contratación ya fue respondida")

    contratacion.status = EstadoContratacion.ACEPTADO
    await db.commit()
    return {"status": contratacion.status.value.upper()}


@router.patch("/{contratacion_id}/rechazar")
async def rechazar_contratacion(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Contratacion).where(
            Contratacion.id == contratacion_id, Contratacion.proveedor_id == current_user.id
        )
    )
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if contratacion.status != EstadoContratacion.PENDIENTE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La contratación ya fue respondida")

    contratacion.status = EstadoContratacion.RECHAZADO
    await db.commit()
    return {"status": contratacion.status.value.upper()}


@router.patch("/{contratacion_id}/cancelar")
async def cancelar_contratacion(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Contratacion).where(Contratacion.id == contratacion_id)
    )
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta contratación")
    if contratacion.status not in (EstadoContratacion.PENDIENTE, EstadoContratacion.ACEPTADO):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Solo se puede cancelar una contratación pendiente o aceptada")

    contratacion.status = EstadoContratacion.CANCELADO
    await db.commit()
    return {"status": contratacion.status.value.upper()}


@router.post("/{contratacion_id}/completar")
async def completar_contratacion(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    
    # Solo el proveedor puede decir que ya terminó el trabajo para recibir el dinero (o el cliente confirmando)
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a esta contratación")
    
    if contratacion.status != EstadoContratacion.ACEPTADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Estado no válido para finalizar")

    contratacion.status = EstadoContratacion.COMPLETADO
    await db.commit()

    return {"status": contratacion.status.value.upper()}


@router.post("/{contratacion_id}/resena", response_model=ResenaResponse, status_code=status.HTTP_201_CREATED)
async def crear_resena(
    contratacion_id: str,
    data: ResenaCreate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")

    return await crear_resena_service(db, contratacion, current_user.id, data.puntuacion, data.comentario)


@router.patch("/{contratacion_id}/monto")
async def actualizar_monto(
    contratacion_id: str,
    data: dict,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Contratacion).options(selectinload(Contratacion.pago)).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    
    if contratacion.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo el proveedor puede actualizar el monto")
    
    if contratacion.pago and contratacion.pago.status == EstadoPago.APROBADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No se puede cambiar el precio si el pago ya fue aprobado")

    nuevo_monto = data.get("monto_acordado")
    if nuevo_monto is None or nuevo_monto <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Monto inválido")

    contratacion.monto_acordado = nuevo_monto
    await db.commit()
    await db.refresh(contratacion)
    
    return await obtener_contratacion(contratacion_id, current_user, db)


@router.get("/usuario/{usuario_id}/resenas", response_model=list[ResenaResponse])
async def listar_resenas_usuario(usuario_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Resena)
        .where(Resena.calificado_id == usuario_id)
        .order_by(Resena.created_at.desc())
    )
    return result.scalars().all()
