from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Contratacion, Usuario, Suscripcion, EstadoSuscripcion, Plan

router = APIRouter(prefix="/proveedores", tags=["proveedores"])


def _is_premium_subquery(now: datetime):
    return (
        select(func.count(Suscripcion.id) > 0)
        .join(Plan, Plan.id == Suscripcion.plan_id)
        .where(
            Suscripcion.usuario_id == Usuario.id,
            Suscripcion.status == EstadoSuscripcion.ACTIVA,
            Plan.slug == "premium",
            (Suscripcion.fecha_vencimiento == None) | (Suscripcion.fecha_vencimiento > now)
        )
        .scalar_subquery()
    )


# Nota: "/top" debe declararse antes de "/{proveedor_id}" — FastAPI matchea
# rutas en orden de declaracion, y un path param captura cualquier string
# (incluido "top") si se declara primero.
@router.get("/top")
async def top_proveedores(
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    is_premium_subquery = _is_premium_subquery(now)

    result = await db.execute(
        select(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.avatar_url,
            Usuario.avg_rating_proveedor,
            Usuario.bio,
            func.coalesce(func.count(Contratacion.id), 0).label("total_contratos"),
            is_premium_subquery.label("es_premium"),
        )
        .outerjoin(Contratacion, Contratacion.proveedor_id == Usuario.id)
        .where(Usuario.es_proveedor == True, Usuario.is_active == True, Usuario.avg_rating_proveedor > 0)
        .group_by(Usuario.id)
        .order_by(is_premium_subquery.desc(), Usuario.avg_rating_proveedor.desc())
        .limit(limit)
    )
    rows = result.all()
    return [
        {
            "id": str(r.id),
            "nombre": f"{r.nombre} {r.apellido}",
            "avatar_url": r.avatar_url,
            "avg_rating": float(r.avg_rating_proveedor),
            "bio": r.bio,
            "total_contratos": r.total_contratos,
            "proveedor_es_premium": bool(r.es_premium),
        }
        for r in rows
    ]


@router.get("/{proveedor_id}")
async def perfil_publico_proveedor(proveedor_id: str, db: AsyncSession = Depends(get_db)):
    """Perfil público de un proveedor (sin datos privados: email, telefono, banco, etc)."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.avatar_url,
            Usuario.avg_rating_proveedor,
            Usuario.bio,
            Usuario.habilidades,
            Usuario.doc_estado,
            Usuario.created_at,
            func.coalesce(func.count(Contratacion.id), 0).label("total_contratos"),
            _is_premium_subquery(now).label("es_premium"),
        )
        .outerjoin(Contratacion, Contratacion.proveedor_id == Usuario.id)
        .where(Usuario.id == proveedor_id, Usuario.es_proveedor == True, Usuario.is_active == True)
        .group_by(Usuario.id)
    )
    r = result.first()
    if not r:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proveedor no encontrado")

    return {
        "id": str(r.id),
        "nombre": f"{r.nombre} {r.apellido}",
        "avatar_url": r.avatar_url,
        "avg_rating": float(r.avg_rating_proveedor),
        "bio": r.bio,
        "habilidades": r.habilidades,
        "identidad_verificada": r.doc_estado == "approved",
        "proveedor_es_premium": bool(r.es_premium),
        "total_contratos": r.total_contratos,
        "miembro_desde": r.created_at,
    }
