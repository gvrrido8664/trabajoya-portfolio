import hashlib
import hmac
import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.core.config import settings
from app.core.security import decrypt_secret
from app.database import get_db
from app.models import Contratacion, EstadoContratacion, EstadoPago, MetodoPago, Pago, Usuario
from app.services.payment_service import payment_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/pagos", tags=["pagos"])


def _build_estado(pago: Pago) -> dict:
    """Estado del pago (recibo). La plataforma cobra 0% por transacción → el 100% es del proveedor."""
    return {
        "status": pago.status.value,
        "monto": pago.monto,
        "metodo_pago": pago.metodo_pago.value if pago.metodo_pago else None,
        "payout_status": pago.payout_status,
    }


async def _validar_pago(contratacion_id: str, current_user: Usuario, db: AsyncSession):
    """Valida que la contratación exista, el usuario sea el cliente y esté ACEPTADO."""
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if contratacion.cliente_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Solo el cliente puede iniciar el pago")
    if contratacion.status != EstadoContratacion.ACEPTADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="La contratación debe estar aceptada para pagar")
    # Validar que no exista un pago ya aprobado
    pago_exist = await db.execute(select(Pago).where(Pago.contratacion_id == contratacion_id))
    pago = pago_exist.scalar_one_or_none()
    if pago and pago.status == EstadoPago.APROBADO:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Esta contratación ya tiene un pago aprobado")
    monto = contratacion.monto_acordado or 0
    if monto <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Monto inválido")
    return contratacion, monto


# ─── MercadoPago (pago directo a la cuenta del proveedor) ────────────────────


@router.post("/crear")
async def crear_pago_mp(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Crea una preferencia de pago en la cuenta MP de la plataforma."""
    contratacion, monto = await _validar_pago(contratacion_id, current_user, db)

    # El proveedor debe tener su cuenta bancaria configurada
    proveedor = await db.get(Usuario, contratacion.proveedor_id)
    if not proveedor or not proveedor.mp_configured or not proveedor.mp_access_token:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El proveedor aún no ha conectado MercadoPago para recibir pagos.",
        )

    titulo = f"Servicio TrabajoYa #{str(contratacion.id)[:8]}"
    try:
        proveedor_token = decrypt_secret(proveedor.mp_access_token)
    except Exception:
        logger.exception("mp_connect_token_invalido", extra={"proveedor_id": str(proveedor.id)})
        raise HTTPException(status_code=503, detail="La cuenta de pago del proveedor debe reconectarse")
    preference = await payment_service.crear_preferencia(
        str(contratacion.id), monto, titulo, proveedor_token
    )
    return preference


@router.post("/acordar-en-persona")
async def acordar_pago_en_persona(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """El cliente confirma que acordará el pago en persona con el proveedor."""
    contratacion, monto = await _validar_pago(contratacion_id, current_user, db)

    # Creamos el registro de pago ya aprobado como en persona
    pago = Pago(
        contratacion_id=contratacion.id,
        monto=monto,
        status=EstadoPago.APROBADO,
        metodo_pago=MetodoPago.ACORDAR_EN_PERSONA,
        payout_status="COMPLETADO", # Consideramos el payout resuelto
    )
    db.add(pago)
    await db.commit()

    return {"status": "success", "metodo": "ACORDAR_EN_PERSONA"}


@router.post("/webhooks/pagos")
async def webhook_pagos(request: Request):
    """Webhook de MercadoPago — validación HMAC + idempotencia."""
    raw_body = await request.body()
    body = await request.json()
    
    payment_id = body.get("data", {}).get("id")
    if not payment_id:
        return {"status": "ignorado", "detail": "sin payment_id"}
    
    try:
        pid = int(payment_id)
    except (ValueError, TypeError):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="payment_id inválido")

    # Validación HMAC MercadoPago.
    # Si el secreto está configurado (producción), la firma es OBLIGATORIA:
    # cualquier firma ausente, malformada o inválida => 403. Nunca se procesa
    # un webhook sin verificar cuando hay secreto. Sin secreto (dev local) se
    # advierte y se procesa para permitir pruebas.
    x_signature = request.headers.get("x-signature")
    x_request_id = request.headers.get("x-request-id")
    if settings.MP_WEBHOOK_SECRET:
        if not (x_signature and x_request_id):
            logger.warning("webhook_mp_sin_firma", pid=pid)
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Firma requerida")
        parts = dict(p.split("=", 1) for p in x_signature.split(",") if "=" in p)
        ts = parts.get("ts")
        v1 = parts.get("v1")
        if not (ts and v1):
            logger.warning("webhook_mp_firma_malformada", pid=pid)
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Firma malformada")
        manifest = f"id={body.get('data', {}).get('id')};request-id={x_request_id};ts={ts};"
        hmac_obj = hmac.new(settings.MP_WEBHOOK_SECRET.encode(), manifest.encode(), hashlib.sha256)
        if not hmac.compare_digest(hmac_obj.hexdigest(), v1):
            logger.warning("webhook_mp_firma_invalida", pid=pid)
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Firma HMAC inválida")
    else:
        logger.warning("webhook_mp_secret_no_configurado", pid=pid)

    await payment_service.procesar_webhook(pid)
    return {"status": "procesado"}


# ─── Estado del pago (recibo) ────────────────────────────


@router.get("/{contratacion_id}/estado")
async def estado_pago(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Consulta el estado del pago de una contratación."""
    result = await db.execute(select(Pago).where(Pago.contratacion_id == contratacion_id))
    pago = result.scalar_one_or_none()
    if not pago:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No hay pago registrado")

    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if contratacion and current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este pago")
    return _build_estado(pago)
