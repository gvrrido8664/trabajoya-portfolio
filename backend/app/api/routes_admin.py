from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_admin
from app.core.config import settings
from app.database import get_db
from app.models import (
    Categoria,
    Contratacion,
    EstadoContratacion,
    EstadoPago,
    EstadoServicio,
    EstadoSuscripcion,
    MetodoPago,
    Pago,
    Plan,
    RolUsuario,
    Servicio,
    Suscripcion,
    Usuario,
)

router = APIRouter(prefix="/admin", tags=["admin"])


class AdminUserCreate(BaseModel):
    email: EmailStr
    password: str
    nombre: str
    apellido: str
    rol: str = "cliente"
    telefono: str | None = None


class AdminUserUpdate(BaseModel):
    email: EmailStr | None = None
    nombre: str | None = None
    apellido: str | None = None
    telefono: str | None = None
    rol: str | None = None
    is_active: bool | None = None


class AdminSuscripcionStatusUpdate(BaseModel):
    status: str


class AdminAsignarPlanRequest(BaseModel):
    usuario_id: str
    plan_slug: str


@router.get("/stats")
async def dashboard_stats(
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Métricas generales del dashboard."""
    now = datetime.now(timezone.utc)
    inicio_mes = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    total_usuarios = (await db.execute(select(func.count(Usuario.id)))).scalar() or 0
    total_proveedores = (
        await db.execute(select(func.count(Usuario.id)).where(Usuario.rol == RolUsuario.PROVEEDOR))
    ).scalar() or 0
    total_clientes = (
        await db.execute(select(func.count(Usuario.id)).where(Usuario.rol == RolUsuario.CLIENTE))
    ).scalar() or 0
    servicios_activos = (
        await db.execute(
            select(func.count(Servicio.id)).where(Servicio.status == EstadoServicio.ACTIVO)
        )
    ).scalar() or 0
    contrataciones_mes = (
        await db.execute(
            select(func.count(Contratacion.id)).where(Contratacion.created_at >= inicio_mes)
        )
    ).scalar() or 0
    contrataciones_total = (
        await db.execute(select(func.count(Contratacion.id)))
    ).scalar() or 0
    volumen_mes = (
        await db.execute(
            select(func.coalesce(func.sum(Pago.monto), 0)).where(
                Pago.status == EstadoPago.APROBADO, Pago.created_at >= inicio_mes
            )
        )
    ).scalar() or 0

    # Contrataciones por mes (últimos 6 meses)
    contrataciones_por_mes = []
    for i in range(5, -1, -1):
        mes_inicio = (inicio_mes - timedelta(days=30 * i)).replace(day=1)
        mes_fin = (mes_inicio + timedelta(days=32)).replace(day=1)
        count = (await db.execute(
            select(func.count(Contratacion.id)).where(
                Contratacion.created_at >= mes_inicio,
                Contratacion.created_at < mes_fin,
            )
        )).scalar() or 0
        contrataciones_por_mes.append({
            "mes": mes_inicio.strftime("%Y-%m"),
            "total": count,
        })

    # Top categorías
    result_cats = await db.execute(
        select(Categoria.nombre, func.count(Servicio.id))
        .join(Servicio, Servicio.categoria_id == Categoria.id)
        .where(Servicio.status == EstadoServicio.ACTIVO)
        .group_by(Categoria.nombre)
        .order_by(func.count(Servicio.id).desc())
        .limit(5)
    )
    top_categorias = [{"nombre": r[0], "total": r[1]} for r in result_cats.all()]

    # Top proveedores por rating
    result_top = await db.execute(
        select(
            Usuario.nombre,
            Usuario.apellido,
            Usuario.avg_rating,
            func.coalesce(func.count(Contratacion.id), 0).label("total_contratos"),
        )
        .outerjoin(Contratacion, Contratacion.proveedor_id == Usuario.id)
        .where(Usuario.rol == RolUsuario.PROVEEDOR, Usuario.avg_rating > 0)
        .group_by(Usuario.id)
        .order_by(Usuario.avg_rating.desc())
        .limit(5)
    )
    top_proveedores = [
        {"nombre": f"{r.nombre} {r.apellido}", "rating": float(r.avg_rating), "total_contratos": r.total_contratos}
        for r in result_top.all()
    ]

    return {
        "usuarios": {"total": total_usuarios, "proveedores": total_proveedores, "clientes": total_clientes},
        "servicios_activos": servicios_activos,
        "contrataciones": {"total": contrataciones_total, "este_mes": contrataciones_mes},
        "volumen_transaccionado_mes": round(float(volumen_mes), 2),
        "contrataciones_por_mes": contrataciones_por_mes,
        "top_categorias": top_categorias,
        "top_proveedores": top_proveedores,
    }


@router.get("/usuarios")
async def listar_usuarios(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    rol: str | None = Query(None),
    email: str | None = Query(None),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Usuario)
    if rol:
        query = query.where(Usuario.rol == rol.lower())
    if email:
        query = query.where(Usuario.email.ilike(f"%{email}%"))
    query = query.order_by(Usuario.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    usuarios = result.scalars().all()
    total = (await db.execute(select(func.count(Usuario.id)))).scalar() or 0
    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "data": [
            {
                "id": str(u.id),
                "email": u.email,
                "nombre": u.nombre,
                "apellido": u.apellido,
                "telefono": u.telefono,
                "rol": u.rol.value,
                "avatar_url": u.avatar_url,
                "bio": u.bio,
                "habilidades": u.habilidades,
                "is_active": u.is_active,
                "is_verified": u.is_verified,
                "avg_rating": u.avg_rating,
                "codigo_referido": u.codigo_referido,
                "referidos_count": u.referidos_count,
                "created_at": u.created_at.isoformat(),
                "updated_at": u.updated_at.isoformat() if u.updated_at else None,
            }
            for u in usuarios
        ],
    }


@router.patch("/usuarios/{usuario_id}/toggle-active")
async def toggle_usuario_activo(
    usuario_id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Usuario).where(Usuario.id == usuario_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    user.is_active = not user.is_active
    await db.commit()
    return {"id": str(user.id), "is_active": user.is_active}


@router.post("/usuarios", status_code=status.HTTP_201_CREATED)
async def crear_usuario(
    data: AdminUserCreate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    from app.core.security import hash_password

    exists = await db.execute(select(Usuario).where(Usuario.email == data.email))
    if exists.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="El email ya existe")

    user = Usuario(
        email=data.email,
        password_hash=await hash_password(data.password),
        nombre=data.nombre,
        apellido=data.apellido,
        telefono=data.telefono,
        rol=data.rol,
        es_proveedor=(data.rol == "proveedor"),
        is_verified=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return {
        "id": str(user.id),
        "email": user.email,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "rol": user.rol.value,
        "is_active": user.is_active,
    }


@router.put("/usuarios/{usuario_id}")
async def actualizar_usuario(
    usuario_id: str,
    data: AdminUserUpdate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Usuario).where(Usuario.id == usuario_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")

    updates = data.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(user, key, value)
    await db.commit()
    await db.refresh(user)
    return {
        "id": str(user.id),
        "email": user.email,
        "nombre": user.nombre,
        "apellido": user.apellido,
        "telefono": user.telefono,
        "rol": user.rol.value,
        "is_active": user.is_active,
        "is_verified": user.is_verified,
        "avg_rating": user.avg_rating,
    }


@router.get("/servicios")
async def listar_servicios_admin(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status_filter: str | None = Query(None, alias="status"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Servicio)
    count_query = select(func.count()).select_from(Servicio)
    if status_filter:
        status_filter = status_filter.upper()
        query = query.where(Servicio.status == status_filter)
        count_query = count_query.where(Servicio.status == status_filter)
    total = (await db.execute(count_query)).scalar() or 0
    query = query.order_by(Servicio.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    servicios = result.scalars().all()

    enriched = []
    for s in servicios:
        result_pv = await db.execute(select(Usuario).where(Usuario.id == s.proveedor_id))
        proveedor = result_pv.scalar_one_or_none()
        result_cat = await db.execute(select(Categoria).where(Categoria.id == s.categoria_id))
        categoria = result_cat.scalar_one_or_none()
        lat = lng = None
        if s.ubicacion:
            m = __import__('re').search(r'POINT\s*\(([\d\.\-e\+]+)\s+([\d\.\-e\+]+)\)', str(s.ubicacion))
            if m:
                lng = float(m.group(1))
                lat = float(m.group(2))
        enriched.append({
            "id": str(s.id),
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "proveedor_id": str(s.proveedor_id),
            "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else None,
            "proveedor_rating": proveedor.avg_rating if proveedor else 0.0,
            "categoria_id": str(s.categoria_id),
            "categoria_nombre": categoria.nombre if categoria else None,
            "status": s.status.value,
            "precio_min": s.precio_min,
            "precio_max": s.precio_max,
            "radio_cobertura_km": s.radio_cobertura_km,
            "direccion_texto": s.direccion_texto,
            "fotos": s.fotos,
            "es_destacado": s.es_destacado,
            "distancia": None,
            "latitud": lat,
            "longitud": lng,
            "created_at": s.created_at.isoformat(),
            "updated_at": s.updated_at.isoformat() if s.updated_at else None,
        })
    return {
        "total": total,
        "data": enriched,
    }


@router.get("/pagos")
async def listar_pagos(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status_filter: str | None = Query(None, alias="status"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Pago)
    if status_filter:
        status_filter = status_filter.upper()
        query = query.where(Pago.status == status_filter)
    count_query = select(func.count()).select_from(Pago)
    if status_filter:
        count_query = count_query.where(Pago.status == status_filter)
    total = (await db.execute(count_query)).scalar() or 0
    query = query.order_by(Pago.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    pagos = result.scalars().all()
    total_vol = (
        await db.execute(select(func.coalesce(func.sum(Pago.monto), 0)).where(Pago.status == EstadoPago.APROBADO))
    ).scalar() or 0
    return {
        "total": total,
        "volumen_total_aprobado": round(float(total_vol), 2),
        "data": [
            {
                "id": str(p.id),
                "contratacion_id": str(p.contratacion_id),
                "monto": p.monto,
                "metodo_pago": p.metodo_pago.value if p.metodo_pago else "MERCADOPAGO",
                "fee_plataforma": round(p.monto * settings.FEE_PLATAFORMA, 2),
                "monto_neto": round(p.monto - p.monto * settings.FEE_PLATAFORMA, 2),
                "status": p.status.value,
                "created_at": p.created_at.isoformat(),
            }
            for p in pagos
        ],
    }


@router.get("/suscripciones")
async def listar_suscripciones_admin(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    # Obtener proveedores
    query = (
        select(Usuario)
        .where(Usuario.rol == RolUsuario.PROVEEDOR)
        .order_by(Usuario.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    proveedores = result.scalars().all()
    total = (await db.execute(select(func.count(Usuario.id)).where(Usuario.rol == RolUsuario.PROVEEDOR))).scalar() or 0

    # Obtener suscripciones activas
    proveedor_ids = [p.id for p in proveedores]
    if proveedor_ids:
        subs_result = await db.execute(
            select(Suscripcion)
            .options(selectinload(Suscripcion.plan))
            .where(
                Suscripcion.usuario_id.in_(proveedor_ids), 
                Suscripcion.status == EstadoSuscripcion.ACTIVA
            )
        )
        subs = subs_result.scalars().all()
        subs_map = {s.usuario_id: s for s in subs}
    else:
        subs_map = {}

    data = []
    for p in proveedores:
        s = subs_map.get(p.id)
        data.append({
            "usuario_id": str(p.id),
            "usuario_nombre": p.nombre,
            "usuario_apellido": p.apellido,
            "usuario_email": p.email,
            "plan_id": str(s.plan_id) if s else None,
            "plan_nombre": s.plan.nombre if s and s.plan else "Ninguno",
            "plan_slug": s.plan.slug if s and s.plan else None,
            "status": s.status.value if s else "INACTIVA",
            "fecha_inicio": s.fecha_inicio.isoformat() if s else None,
            "fecha_vencimiento": s.fecha_vencimiento.isoformat() if s and s.fecha_vencimiento else None,
        })

    return {
        "total": total,
        "data": data,
    }


@router.post("/suscripciones/asignar")
async def admin_asignar_suscripcion(
    data: AdminAsignarPlanRequest,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    # Verify user
    user_result = await db.execute(select(Usuario).where(Usuario.id == data.usuario_id))
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    # Get plan
    plan_result = await db.execute(select(Plan).where(Plan.slug == data.plan_slug))
    plan = plan_result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan no encontrado")
        
    # Cancel existing active subscriptions
    active_subs = await db.execute(
        select(Suscripcion).where(
            Suscripcion.usuario_id == user.id, 
            Suscripcion.status == EstadoSuscripcion.ACTIVA
        )
    )
    for sub in active_subs.scalars().all():
        sub.status = EstadoSuscripcion.CANCELADA
        
    # Create new subscription
    nueva_sub = Suscripcion(
        usuario_id=user.id,
        plan_id=plan.id,
        status=EstadoSuscripcion.ACTIVA,
        fecha_inicio=datetime.now(timezone.utc),
        fecha_vencimiento=None # Asignada manualmente, no expira
    )
    db.add(nueva_sub)
    await db.commit()
    return {"message": f"Plan {plan.nombre} asignado correctamente."}


@router.post("/suscripciones/{suscripcion_id}/cancelar")
async def admin_cancelar_suscripcion(
    suscripcion_id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Suscripcion).where(Suscripcion.id == suscripcion_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Suscripción no encontrada")
    sub.status = "CANCELADA"
    await db.commit()
    return {"message": "Suscripción cancelada exitosamente"}


@router.put("/suscripciones/{suscripcion_id}/estado")
async def admin_actualizar_estado_suscripcion(
    suscripcion_id: str,
    data: AdminSuscripcionStatusUpdate,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Suscripcion).where(Suscripcion.id == suscripcion_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Suscripción no encontrada")
    
    valid_statuses = ["ACTIVA", "VENCIDA", "CANCELADA"]
    if data.status not in valid_statuses:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Estado inválido. Debe ser uno de {valid_statuses}")
        
    sub.status = data.status
    await db.commit()
    return {"message": f"Estado de suscripción actualizado a {data.status}"}


@router.get("/buscar")
async def admin_buscar(
    q: str = Query(..., min_length=1),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    usuarios = await db.execute(
        select(Usuario)
        .where(
            Usuario.email.ilike(f"%{q}%") | Usuario.nombre.ilike(f"%{q}%") | Usuario.apellido.ilike(f"%{q}%")
        )
        .limit(20)
    )
    servicios = await db.execute(
        select(Servicio)
        .where(Servicio.titulo.ilike(f"%{q}%") | Servicio.descripcion.ilike(f"%{q}%"))
        .limit(20)
    )
    return {
        "usuarios": [
            {"id": str(u.id), "email": u.email, "nombre": u.nombre, "apellido": u.apellido, "rol": u.rol.value}
            for u in usuarios.scalars().all()
        ],
        "servicios": [
            {"id": str(s.id), "titulo": s.titulo, "status": s.status.value}
            for s in servicios.scalars().all()
        ],
    }


@router.post("/categorias/sync-iconos")
async def sync_iconos_categorias(
    current_user: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    from app.update_iconos import ICONOS
    result = await db.execute(select(Categoria))
    categorias = result.scalars().all()
    updated = []
    for cat in categorias:
        icono = ICONOS.get(cat.slug)
        if icono and cat.icono != icono:
            cat.icono = icono
            updated.append({"slug": cat.slug, "icono": icono})
    await db.commit()
    return {"updated": len(updated), "categorias": updated}


# ─────────────────── Verificación de identidad (revisión manual) ───────────────────


@router.get("/verificaciones")
async def listar_verificaciones(
    estado: str = Query("pending"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    """Lista usuarios con documentos en el estado dado (por defecto pendientes),
    con URLs firmadas de corta duración para revisar."""
    import json
    from app.services.upload_service import upload_service

    result = await db.execute(
        select(Usuario).where(Usuario.doc_estado == estado).order_by(Usuario.updated_at.desc())
    )
    items = []
    for u in result.scalars().all():
        selfie_url = doc_url = None
        if u.doc_url:
            try:
                paths = json.loads(u.doc_url)
                selfie_url = await upload_service.signed_url_documento(paths.get("selfie", ""))
                doc_url = await upload_service.signed_url_documento(paths.get("documento", ""))
            except Exception:
                pass
        items.append({
            "id": str(u.id),
            "nombre": f"{u.nombre} {u.apellido}",
            "email": u.email,
            "rol": u.rol.value,
            "doc_estado": u.doc_estado,
            "selfie_url": selfie_url,
            "documento_url": doc_url,
        })
    return {"items": items}


@router.post("/verificaciones/{user_id}/aprobar")
async def aprobar_verificacion(
    user_id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Usuario).where(Usuario.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    user.doc_estado = "approved"
    user.doc_verified_at = datetime.now(timezone.utc)
    await db.commit()
    return {"estado": "approved"}


@router.post("/verificaciones/{user_id}/rechazar")
async def rechazar_verificacion(
    user_id: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Usuario).where(Usuario.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    user.doc_estado = "rejected"
    user.doc_verified_at = None
    await db.commit()
    return {"estado": "rejected"}
