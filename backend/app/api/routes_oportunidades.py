from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import Categoria, Solicitud, StatusSolicitud

router = APIRouter(prefix="/oportunidades", tags=["oportunidades"])


@router.get("")
async def listar_oportunidades(
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Solicitud)
        .options(selectinload(Solicitud.categoria))
        .where(Solicitud.status == StatusSolicitud.ABIERTA)
        .order_by(Solicitud.created_at.desc())
        .limit(limit)
    )
    solicitudes = result.scalars().all()

    oportunidades = []
    for s in solicitudes:
        cat = s.categoria
        oportunidades.append({
            "id": str(s.id),
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "categoria_nombre": cat.nombre if cat else None,
            "ubicacion_texto": s.ubicacion_texto,
            "presupuesto_max": s.presupuesto_max,
            "created_at": s.created_at.isoformat(),
        })

    return oportunidades
