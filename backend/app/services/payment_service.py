import logging
import uuid
from contextlib import asynccontextmanager

import httpx
from sqlalchemy import select

from app.core.config import settings
from app.core.security import decrypt_secret
from app.database import async_session
from app.models import Contratacion, EstadoPago, MetodoPago, Pago, Usuario

logger = logging.getLogger(__name__)


class PaymentService:
    """Pagos vía MercadoPago.

    - Suscripciones (ingreso propio de la plataforma): se cobran a la cuenta de la
      plataforma (`MP_ACCESS_TOKEN`).
    - Pago cliente→proveedor: se crea con el token OAuth del PROVEEDOR (MP Connect),
      de modo que el 100% cae en la cuenta del proveedor. La plataforma NO custodia.
    """

    BASE_URL = "https://api.mercadopago.com"
    HTTPX_TIMEOUT = httpx.Timeout(10.0)

    def _headers(self) -> dict:
        """Headers con el token de la plataforma."""
        return {
            "Authorization": f"Bearer {settings.MP_ACCESS_TOKEN}",
            "Content-Type": "application/json",
            "X-Idempotency-Key": str(uuid.uuid4()),
        }

    @asynccontextmanager
    async def _client(self):
        async with httpx.AsyncClient(timeout=self.HTTPX_TIMEOUT) as client:
            yield client

    async def crear_preferencia(
        self,
        contratacion_id: str,
        monto: float,
        titulo: str,
        proveedor_mp_token: str | None = None,
    ) -> dict:
        """Crea una preferencia de checkout.

        Si se pasa proveedor_mp_token, se crea a nombre del proveedor y se cobra el marketplace_fee.
        Si no, se cobra a la cuenta de la plataforma (ej. suscripciones).
        """
        webhook_url = f"{settings.BACKEND_URL}/api/v1/pagos/webhooks/pagos"
        payload = {
            "items": [{
                "title": titulo,
                "quantity": 1,
                "unit_price": float(monto),
                "currency_id": "CLP",
            }],
            "back_urls": {
                "success": f"{settings.FRONTEND_URL}/pago/resultado/{contratacion_id}?status=success",
                "failure": f"{settings.FRONTEND_URL}/pago/resultado/{contratacion_id}?status=failure",
                "pending": f"{settings.FRONTEND_URL}/pago/resultado/{contratacion_id}?status=pending",
            },
            "auto_return": "approved",
            "notification_url": webhook_url,
            "external_reference": contratacion_id,
        }

        token_a_usar = settings.MP_ACCESS_TOKEN
        if proveedor_mp_token:
            token_a_usar = proveedor_mp_token
            # La comisión de la plataforma se envía en el fee
            # fee_plataforma = 0.10 (ejemplo 10%)
            comision = round(float(monto) * getattr(settings, 'FEE_PLATAFORMA', 0.10), 2)
            if comision > 0:
                payload["marketplace_fee"] = comision

        headers = {
            "Authorization": f"Bearer {token_a_usar}",
            "Content-Type": "application/json",
            "X-Idempotency-Key": str(uuid.uuid4()),
        }

        async with self._client() as client:
            resp = await client.post(
                f"{self.BASE_URL}/checkout/preferences",
                json=payload,
                headers=headers,
            )

        if resp.status_code >= 400:
            logger.error("mp_crear_preferencia_error", extra={"status": resp.status_code, "body": resp.text[:300]})
            from fastapi import HTTPException, status
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Error al conectar con MercadoPago: {resp.text[:200]}"
            )

        data = resp.json()

        # Registro Pago PENDIENTE (recibo) solo para pagos de contratación, no suscripciones
        if contratacion_id and not str(contratacion_id).startswith("suscripcion_"):
            async with async_session() as session:
                existente = await session.execute(
                    select(Pago).where(Pago.contratacion_id == contratacion_id)
                )
                if not existente.scalar_one_or_none():
                    pago = Pago(
                        contratacion_id=contratacion_id,
                        monto=monto,
                        status=EstadoPago.PENDIENTE,
                        metodo_pago=MetodoPago.MERCADOPAGO,
                        preference_id=data.get("id"),
                    )
                    session.add(pago)
                    await session.commit()

        return data

    async def procesar_webhook(self, payment_id: int) -> dict:
        """Procesa la notificación de pago."""
        # Nota: El webhook de Marketplace lo recibe la app usando su token de plataforma (o el del vendedor).
        # MercadoPago permite consultar el pago usando el token de la plataforma si somos la app integrada.
        async with self._client() as client:
            resp = await client.get(
                f"{self.BASE_URL}/v1/payments/{payment_id}",
                headers=self._headers(),
            )

        if resp.status_code >= 400:
            logger.error("mp_consulta_pago_error", extra={"payment_id": payment_id, "status": resp.status_code})
            resp.raise_for_status()

        data = resp.json()
        contratacion_id = data.get("external_reference")
        mp_id = str(data["id"])
        mp_status = data.get("status")

        if contratacion_id and contratacion_id.startswith("suscripcion_"):
            if mp_status == "approved":
                await self._aprobar_suscripcion(contratacion_id, mp_id)
            return data

        if mp_status == "approved" and contratacion_id:
            await self._aprobar_pago(contratacion_id, data, mp_id)
        elif mp_status in ("rejected", "cancelled") and contratacion_id:
            await self._rechazar_pago(contratacion_id, mp_id, mp_status)

        return data

    async def _aprobar_suscripcion(self, external_reference: str, mp_id: str):
        parts = external_reference.split("_")
        if len(parts) != 3:
            return
        plan_id_str, user_id_str = parts[1], parts[2]

        from app.models import Suscripcion, EstadoSuscripcion
        from datetime import datetime, timezone, timedelta

        async with async_session() as session:
            sub = Suscripcion(
                usuario_id=uuid.UUID(user_id_str),
                plan_id=uuid.UUID(plan_id_str),
                status=EstadoSuscripcion.ACTIVA,
                fecha_inicio=datetime.now(timezone.utc),
                fecha_vencimiento=datetime.now(timezone.utc) + timedelta(days=30),
            )
            session.add(sub)
            await session.commit()
            logger.info("suscripcion_aprobada", extra={"user_id": user_id_str, "plan_id": plan_id_str})

    async def _aprobar_pago(self, contratacion_id: str, payment_data: dict, mp_id: str):
        async with async_session() as session:
            existente = await session.execute(
                select(Pago).where(Pago.mp_payment_id == mp_id)
            )
            if existente.scalar_one_or_none():
                logger.info("pago_ya_procesado", extra={"mp_payment_id": mp_id})
                return

            monto = float(payment_data["transaction_amount"])

            result = await session.execute(
                select(Contratacion).where(Contratacion.id == contratacion_id)
            )
            contratacion = result.scalar_one_or_none()
            if not contratacion:
                logger.warning("contratacion_no_encontrada", extra={"contratacion_id": contratacion_id})
                return

            pago_result = await session.execute(
                select(Pago).where(Pago.contratacion_id == contratacion_id)
            )
            pago = pago_result.scalar_one_or_none()
            if pago:
                if pago.status == EstadoPago.APROBADO:
                    logger.info("pago_ya_aprobado", extra={"contratacion_id": contratacion_id})
                    return
                pago.status = EstadoPago.APROBADO
                pago.mp_payment_id = mp_id
                pago.monto = monto
                pago.preference_id = payment_data.get("preference_id")
            else:
                pago = Pago(
                    contratacion_id=contratacion.id,
                    monto=monto,
                    status=EstadoPago.APROBADO,
                    metodo_pago=MetodoPago.MERCADOPAGO,
                    mp_payment_id=mp_id,
                    preference_id=payment_data.get("preference_id"),
                )
                session.add(pago)

            await session.commit()
            logger.info("pago_aprobado", extra={"contratacion_id": contratacion_id, "mp_payment_id": mp_id})
            
            # El dinero ya fue dividido y entregado al proveedor por MP Connect
            pago.payout_status = "COMPLETADO"
            await session.commit()

    async def _rechazar_pago(self, contratacion_id: str, mp_id: str, mp_status: str):
        async with async_session() as session:
            pago_result = await session.execute(
                select(Pago).where(Pago.contratacion_id == contratacion_id)
            )
            pago = pago_result.scalar_one_or_none()
            if pago:
                pago.status = EstadoPago.RECHAZADO
                pago.mp_payment_id = mp_id
                await session.commit()
                logger.info("pago_rechazado", extra={"contratacion_id": contratacion_id, "mp_status": mp_status})

    async def reembolsar_pago(self, mp_payment_id: str) -> bool:
        """Reembolso total."""
        async with self._client() as client:
            resp = await client.post(
                f"{self.BASE_URL}/v1/payments/{mp_payment_id}/refunds",
                headers=self._headers(),
            )
        if resp.status_code >= 400:
            logger.error("mp_reembolso_error", extra={"mp_payment_id": mp_payment_id, "status": resp.status_code, "body": resp.text[:300]})
            return False
        logger.info("mp_reembolso_ok", extra={"mp_payment_id": mp_payment_id})
        return True


payment_service = PaymentService()
