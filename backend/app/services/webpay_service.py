import hashlib
import hmac
import logging
import uuid
from base64 import b64decode, b64encode
from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy import select

from app.core.config import settings
from app.database import async_session
from app.models import EstadoPago, MetodoPago, Pago

logger = logging.getLogger(__name__)

WEBPAY_BASE = "https://webpay3gint.transbank.cl"  # integration (sandbox)


class WebpayService:
    HTTPX_TIMEOUT = httpx.Timeout(15.0)

    @property
    def _base(self) -> str:
        if settings.WEBPAY_ENVIRONMENT == "production":
            return "https://webpay3g.transbank.cl"
        return WEBPAY_BASE

    def _auth_headers(self) -> dict:
        return {
            "Tbk-Api-Key-Id": settings.WEBPAY_COMMERCE_CODE,
            "Tbk-Api-Key-Secret": settings.WEBPAY_API_KEY,
            "Content-Type": "application/json",
        }

    async def init_transaction(self, monto: float, buy_order: str, session_id: str, return_url: str) -> dict:
        """Inicia transacción Webpay Plus. Retorna url + token."""
        payload = {
            "buy_order": buy_order[:26],
            "session_id": session_id[:61],
            "amount": monto,
            "return_url": return_url,
        }
        async with httpx.AsyncClient(timeout=self.HTTPX_TIMEOUT) as client:
            resp = await client.post(
                f"{self._base}/rswebpaytransaction/api/webpay/v1.2/transactions",
                json=payload,
                headers=self._auth_headers(),
            )
        if resp.status_code >= 400:
            logger.error("webpay_init_error", status=resp.status_code, body=resp.text)
            resp.raise_for_status()
        data = resp.json()
        logger.info("webpay_init_ok", token=data.get("token", "")[:16])
        return data

    async def commit_transaction(self, token: str) -> dict:
        """Confirma (recibe el resultado de) una transacción Webpay."""
        async with httpx.AsyncClient(timeout=self.HTTPX_TIMEOUT) as client:
            resp = await client.put(
                f"{self._base}/rswebpaytransaction/api/webpay/v1.2/transactions/{token}",
                headers=self._auth_headers(),
            )
        if resp.status_code >= 400:
            logger.error("webpay_commit_error", token=token[:16], status=resp.status_code)
            resp.raise_for_status()
        data = resp.json()
        logger.info("webpay_commit_ok", token=token[:16], status=data.get("status"))
        return data

    async def transaction_status(self, token: str) -> dict:
        """Consulta el estado de una transacción Webpay."""
        async with httpx.AsyncClient(timeout=self.HTTPX_TIMEOUT) as client:
            resp = await client.get(
                f"{self._base}/rswebpaytransaction/api/webpay/v1.2/transactions/{token}",
                headers=self._auth_headers(),
            )
        if resp.status_code >= 400:
            logger.error("webpay_status_error", token=token[:16], status=resp.status_code)
            resp.raise_for_status()
        return resp.json()

    async def procesar_commit(self, token: str, contratacion_id: str, monto: float) -> dict:
        """Commit + registra el pago aprobado en DB."""
        data = await self.commit_transaction(token)
        status = data.get("status")
        response_code = data.get("response_code")  # 0 = aprobado

        if status == "AUTHORIZED" and response_code == 0:
            async with async_session() as session:
                pago_result = await session.execute(
                    select(Pago).where(Pago.contratacion_id == contratacion_id)
                )
                pago = pago_result.scalar_one_or_none()
                if pago:
                    if pago.status == EstadoPago.APROBADO:
                        logger.info("webpay_pago_ya_aprobado", contratacion_id=contratacion_id)
                        return data
                    pago.status = EstadoPago.APROBADO
                    pago.webpay_token = token
                    pago.webpay_tbk_id = data.get("buy_order", "")
                else:
                    pago = Pago(
                        contratacion_id=contratacion_id,
                        monto=monto,
                        status=EstadoPago.APROBADO,
                        metodo_pago=MetodoPago.WEBPAY,
                        webpay_token=token,
                        webpay_tbk_id=data.get("buy_order", ""),
                    )
                    session.add(pago)
                await session.commit()
                logger.info("webpay_pago_aprobado", contratacion_id=contratacion_id)
        else:
            logger.warning("webpay_pago_rechazado", status=status, response_code=response_code)

        return data


webpay_service = WebpayService()
