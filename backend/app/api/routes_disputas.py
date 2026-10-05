from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_admin, get_current_user
from app.database import get_db
from app.models import Contratacion, Disputa, EstadoContratacion, EstadoDisputa, Usuario
from app.schemas import DisputaCreate
from app.services.payment_service import payment_service

router = APIRouter(prefix="/disputas", tags=["disputas"])


@router.post("/contratacion/{contratacion_id}", status_code=status.HTTP_201_CREATED)
async def abrir_disputa(
    contratacion_id: str,
    data: DisputaCreate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No participaste en esta contratación")
    if contratacion.status != EstadoContratacion.ACEPTADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No se puede abrir disputa en este estado")

    existing = await db.execute(select(Disputa).where(Disputa.contratacion_id == contratacion_id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya existe una disputa para esta contratación")

    disputa = Disputa(
        contratacion_id=contratacion.id,
        abierta_por_id=current_user.id,
        motivo=data.motivo,
    )
    db.add(disputa)
    await db.commit()
    await db.refresh(disputa)
    return {
        "id": str(disputa.id),
        "contratacion_id": str(disputa.contratacion_id),
        "abridor_id": str(disputa.abierta_por_id),
        "motivo": disputa.motivo,
        "evidencias": data.evidencias,
        "status": "ABIERTA",
        "resolucion": None,
        "created_at": disputa.created_at.isoformat(),
    }


@router.get("/admin")
async def listar_disputas(
    status_filter: str | None = Query(None, alias="status"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Disputa)
    if status_filter:
        status_filter = status_filter.upper()
        query = query.where(Disputa.status == status_filter)
    query = query.order_by(Disputa.created_at.desc())
    result = await db.execute(query)
    disputas = result.scalars().all()
    return {
        "total": len(disputas),
        "data": [
            {
                "id": str(d.id),
                "contratacion_id": str(d.contratacion_id),
                "abridor_id": str(d.abierta_por_id),
                "motivo": d.motivo,
                "status": d.status.value.upper(),
                "resolucion": d.resolucion,
                "created_at": d.created_at.isoformat(),
            }
            for d in disputas
        ],
    }


class ResolverDisputaRequest(BaseModel):
    resolucion: str


@router.patch("/admin/{disputa_id}/resolver")
async def resolver_disputa(
    disputa_id: str,
    data: ResolverDisputaRequest,
    accion: str = Query(..., description="reembolsar o liberar"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    if accion not in ("reembolsar", "liberar"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Acción debe ser 'reembolsar' o 'liberar'")

    result = await db.execute(select(Disputa).where(Disputa.id == disputa_id))
    disputa = result.scalar_one_or_none()
    if not disputa:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Disputa no encontrada")
    if disputa.status != EstadoDisputa.ABIERTA:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La disputa ya fue resuelta")

    disputa.status = EstadoDisputa.RESUELTA
    disputa.resolucion = data.resolucion

    # Ejecutar acción sobre el pago.
    # En el modelo sin custodia, el dinero ya está en la cuenta del proveedor:
    #  - "liberar"  → el proveedor conserva el pago; no hay acción de fondos, solo se cierra.
    #  - "reembolsar" → se reembolsa al cliente contra la cuenta MP del proveedor (su token).
    if accion == "reembolsar":
        from app.models import EstadoPago, Pago
        from app.core.security import decrypt_secret

        result_pago = await db.execute(
            select(Pago).where(Pago.contratacion_id == disputa.contratacion_id)
        )
        pago = result_pago.scalar_one_or_none()
        if pago and pago.mp_payment_id:
            # el pago vive en la cuenta de la plataforma
            ok = await payment_service.reembolsar_pago(pago.mp_payment_id)
            if not ok:
                raise HTTPException(status_code=502, detail="No se pudo reembolsar en MercadoPago")
        if pago:
            pago.status = EstadoPago.CANCELADO

    await db.commit()
    return {"id": str(disputa.id), "estado": disputa.status.value, "accion": accion}
