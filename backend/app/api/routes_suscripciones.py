import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_provider, get_current_user
from app.database import async_session, get_db
from app.models import EstadoSuscripcion, Plan, Suscripcion, Usuario
from app.services.payment_service import payment_service

router = APIRouter(prefix="/suscripciones", tags=["suscripciones"])


class CrearSuscripcionRequest(BaseModel):
    plan_slug: str


@router.get("/planes")
async def listar_planes(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Plan).order_by(Plan.precio_mensual))
    planes = result.scalars().all()
    return [
        {
            "id": str(p.id),
            "nombre": p.nombre,
            "slug": p.slug,
            "descripcion": p.descripcion,
            "beneficios": p.beneficios or [],
            "precio_mensual": p.precio_mensual,
        }
        for p in planes
    ]


@router.post("/crear")
async def crear_suscripcion(
    data: CrearSuscripcionRequest,
    current_user: Usuario = Depends(get_current_provider),
):
    """Crea una suscripción a un plan premium."""
    async with async_session() as session:
        from sqlalchemy import select

        # Sin este chequeo, un proveedor que ya tiene una suscripción activa
        # podía volver a pasar por el checkout y pagar dos veces (o quedar
        # con 2 suscripciones ACTIVA superpuestas).
        existing = await session.execute(
            select(Suscripcion)
            .where(Suscripcion.usuario_id == current_user.id, Suscripcion.status == EstadoSuscripcion.ACTIVA)
            .limit(1)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ya tienes una suscripción activa. Cancélala antes de contratar otra.",
            )

        result = await session.execute(select(Plan).where(Plan.slug == data.plan_slug))
        plan = result.scalar_one_or_none()
        if not plan:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Plan no encontrado")

        titulo = f"Suscripción {plan.nombre} - TrabajoYa"
        ext_ref = f"suscripcion_{plan.id}_{current_user.id}"
        preference = await payment_service.crear_preferencia(
            contratacion_id=ext_ref, monto=plan.precio_mensual, titulo=titulo
        )
        return preference


@router.post("/cancelar")
async def cancelar_suscripcion(
    current_user: Usuario = Depends(get_current_provider),
):
    async with async_session() as session:
        from sqlalchemy import select

        result = await session.execute(
            select(Suscripcion)
            .where(Suscripcion.usuario_id == current_user.id, Suscripcion.status == EstadoSuscripcion.ACTIVA)
            .order_by(Suscripcion.created_at.desc())
            .limit(1)
        )
        sub = result.scalar_one_or_none()
        if not sub:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No tienes una suscripción activa")

        sub.status = EstadoSuscripcion.CANCELADA
        await session.commit()
        return {"message": "Suscripción cancelada exitosamente"}


@router.get("/me")
async def mi_suscripcion(
    current_user: Usuario = Depends(get_current_provider),
):
    """Consulta el estado de suscripción actual."""
    async with async_session() as session:
        from sqlalchemy import select

        result = await session.execute(
            select(Suscripcion)
            .where(Suscripcion.usuario_id == current_user.id)
            .order_by(Suscripcion.created_at.desc())
            .limit(1)
        )
        sub = result.scalar_one_or_none()
        if not sub:
            return {"tiene_suscripcion": False, "plan_slug": None}

        plan_result = await session.execute(select(Plan).where(Plan.id == sub.plan_id))
        plan = plan_result.scalar_one_or_none()

        return {
            "tiene_suscripcion": True,
            "plan_slug": plan.slug if plan else str(sub.plan_id),
            "status": sub.status.value.upper(),
            "fecha_inicio": sub.fecha_inicio.isoformat(),
            "fecha_fin": sub.fecha_vencimiento.isoformat() if sub.fecha_vencimiento else None,
        }
