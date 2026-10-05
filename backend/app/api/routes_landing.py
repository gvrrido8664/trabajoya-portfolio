from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import (
    Contratacion,
    EstadoContratacion,
    RolUsuario,
    Servicio,
    EstadoServicio,
    Solicitud,
    StatusSolicitud,
    Usuario,
)

router = APIRouter(prefix="/landing", tags=["landing"])


@router.get("/stats")
async def landing_stats(db: AsyncSession = Depends(get_db)):
    now = datetime.now(timezone.utc)
    inicio_hoy = now.replace(hour=0, minute=0, second=0, microsecond=0)

    total_proveedores = (
        await db.execute(
            select(func.count(Usuario.id)).where(
                Usuario.es_proveedor == True,
                Usuario.is_active == True,
            )
        )
    ).scalar() or 0

    total_clientes = (
        await db.execute(
            select(func.count(Usuario.id)).where(
                Usuario.rol == RolUsuario.CLIENTE,
                Usuario.is_active == True,
            )
        )
    ).scalar() or 0

    servicios_activos = (
        await db.execute(
            select(func.count(Servicio.id)).where(
                Servicio.status == EstadoServicio.ACTIVO
            )
        )
    ).scalar() or 0

    solicitudes_abiertas_hoy = (
        await db.execute(
            select(func.count(Solicitud.id)).where(
                Solicitud.status == StatusSolicitud.ABIERTA,
                Solicitud.created_at >= inicio_hoy,
            )
        )
    ).scalar() or 0

    contrataciones_completadas = (
        await db.execute(
            select(func.count(Contratacion.id)).where(
                Contratacion.status == EstadoContratacion.COMPLETADO
            )
        )
    ).scalar() or 0

    return {
        "clientes_activos": total_clientes,
        "proveedores_activos": total_proveedores,
        "servicios_activos": servicios_activos,
        "solicitudes_abiertas_hoy": solicitudes_abiertas_hoy,
        "contrataciones_completadas": contrataciones_completadas,
    }


@router.get("/highlights")
async def landing_highlights(
    limit: int = Query(5, ge=1, le=20),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Solicitud)
        .options(selectinload(Solicitud.cliente))
        .where(Solicitud.status == StatusSolicitud.ABIERTA)
        .order_by(Solicitud.created_at.desc())
        .limit(limit)
    )
    solicitudes = result.scalars().all()

    items = []
    for s in solicitudes:
        cliente = s.cliente
        items.append({
            "id": str(s.id),
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "ubicacion_texto": s.ubicacion_texto,
            "presupuesto_max": s.presupuesto_max,
            "cliente_nombre": f"{cliente.nombre} {cliente.apellido}" if cliente else "Anónimo",
            "cliente_inicial": cliente.nombre[0].upper() if cliente and cliente.nombre else "?",
            "created_at": s.created_at.isoformat(),
        })

    return items
