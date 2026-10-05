import uuid

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Contratacion, EstadoContratacion, Resena, Usuario


async def crear_resena(
    db: AsyncSession,
    contratacion: Contratacion,
    calificador_id: uuid.UUID,
    puntuacion: int,
    comentario: str | None,
) -> Resena:
    """Crea una reseña mutua (cliente↔proveedor) para una contratación completada
    y recalcula los ratings del calificado. Única fuente de verdad: la usan tanto
    /resenas/{id} como /contrataciones/{id}/resena."""
    if calificador_id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No participaste en esta contratación")
    if contratacion.status != EstadoContratacion.COMPLETADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Solo se puede reseñar una contratación completada")

    existing = await db.execute(
        select(Resena).where(
            Resena.contratacion_id == contratacion.id,
            Resena.calificador_id == calificador_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya dejaste una reseña para esta contratación")

    calificado_id = (
        contratacion.proveedor_id if calificador_id == contratacion.cliente_id else contratacion.cliente_id
    )

    resena = Resena(
        contratacion_id=contratacion.id,
        calificador_id=calificador_id,
        calificado_id=calificado_id,
        puntuacion=puntuacion,
        comentario=comentario,
    )
    db.add(resena)
    await db.commit()
    await db.refresh(resena)

    await recalcular_ratings(db, calificado_id)
    return resena


async def recalcular_ratings(db: AsyncSession, calificado_id: uuid.UUID) -> None:
    """Recalcula avg_rating (legacy, global) y los promedios separados por rol
    (avg_rating_proveedor / avg_rating_cliente) según el contexto de cada reseña,
    derivado por join con la contratación (calificado_id == proveedor_id o cliente_id)."""
    result_user = await db.execute(select(Usuario).where(Usuario.id == calificado_id))
    usuario = result_user.scalar_one_or_none()
    if not usuario:
        return

    avg_global = (
        await db.execute(select(func.round(func.avg(Resena.puntuacion), 2)).where(Resena.calificado_id == calificado_id))
    ).scalar()
    usuario.avg_rating = float(avg_global or 0.0)

    avg_proveedor = (
        await db.execute(
            select(func.round(func.avg(Resena.puntuacion), 2))
            .join(Contratacion, Contratacion.id == Resena.contratacion_id)
            .where(Resena.calificado_id == calificado_id, Resena.calificado_id == Contratacion.proveedor_id)
        )
    ).scalar()
    usuario.avg_rating_proveedor = float(avg_proveedor or 0.0)

    avg_cliente = (
        await db.execute(
            select(func.round(func.avg(Resena.puntuacion), 2))
            .join(Contratacion, Contratacion.id == Resena.contratacion_id)
            .where(Resena.calificado_id == calificado_id, Resena.calificado_id == Contratacion.cliente_id)
        )
    ).scalar()
    usuario.avg_rating_cliente = float(avg_cliente or 0.0)

    await db.commit()
