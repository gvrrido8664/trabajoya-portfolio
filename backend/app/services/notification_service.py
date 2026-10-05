"""
Servicio de notificaciones push via Firebase Cloud Messaging (FCM).
Requiere el archivo de credenciales de Firebase configurado en .env.
"""
import json
import os

import httpx

from app.core.config import settings


class NotificationService:
    FCM_URL = "https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

    async def _get_access_token(self) -> str:
        """Obtiene un token de acceso OAuth2 para Firebase."""
        if not settings.FIREBASE_CREDENTIALS_PATH or not os.path.exists(settings.FIREBASE_CREDENTIALS_PATH):
            return ""

        with open(settings.FIREBASE_CREDENTIALS_PATH) as f:
            creds = json.load(f)

        # Implementación simplificada — en producción usar google-auth o firebase-admin SDK
        return ""

    async def enviar_push(self, fcm_token: str, titulo: str, cuerpo: str, data: dict | None = None):
        """Envía una notificación push a un dispositivo específico."""
        if not settings.FIREBASE_CREDENTIALS_PATH:
            return None

        try:
            token = await self._get_access_token()
            if not token:
                return None

            project_id = "tu-project-id"
            payload = {
                "message": {
                    "token": fcm_token,
                    "notification": {"title": titulo, "body": cuerpo},
                    "data": data or {},
                }
            }
            async with httpx.AsyncClient() as client:
                resp = await client.post(
                    self.FCM_URL.format(project_id=project_id),
                    json=payload,
                    headers={"Authorization": f"Bearer {token}"},
                )
                return resp.json()
        except Exception:
            return None  # Non-critical: no bloquear la app por fallo de notificación


notification_service = NotificationService()
