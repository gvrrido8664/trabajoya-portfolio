from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_admin, get_current_user
from app.database import get_db
from app.models import Contratacion, Resena, Usuario
from app.schemas import ResenaCreate, ResenaResponse
from app.services.rating_service import crear_resena as crear_resena_service

router = APIRouter(prefix="/resenas", tags=["resenas"])


@router.post("/{contratacion_id}", response_model=ResenaResponse, status_code=status.HTTP_201_CREATED)
async def crear_resena(
    contratacion_id: str,
    data: ResenaCreate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Ruta legacy: mantenida por compatibilidad con clientes viejos. La lógica
    # (mutua: cliente o proveedor puede reseñar) vive en rating_service, misma
    # que usa POST /contrataciones/{id}/resena.
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")

    return await crear_resena_service(db, contratacion, current_user.id, data.puntuacion, data.comentario)


@router.get("/usuario/{usuario_id}", response_model=list[ResenaResponse])
async def listar_resenas_usuario(usuario_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Resena)
        .where(Resena.calificado_id == usuario_id)
        .order_by(Resena.created_at.desc())
    )
    return result.scalars().all()


@router.get("/admin")
async def listar_resenas_admin(
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Resena)
        .order_by(Resena.created_at.desc())
    )
    resenas = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "contratacion_id": str(r.contratacion_id),
            "calificador_id": str(r.calificador_id),
            "calificado_id": str(r.calificado_id),
            "puntuacion": r.puntuacion,
            "comentario": r.comentario,
            "created_at": r.created_at.isoformat(),
        }
        for r in resenas
    ]
