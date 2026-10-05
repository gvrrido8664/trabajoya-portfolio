import logging

import resend

from app.core.config import settings

logger = logging.getLogger(__name__)


class EmailService:
    FROM_EMAIL = "TrabajoYa <noreply@somostrabajoya.cl>"

    async def _send(self, to: str, subject: str, html: str) -> bool:
        if not settings.RESEND_API_KEY:
            print(f"\n{'='*60}", flush=True)
            print(f"[EMAIL DEV] To: {to}", flush=True)
            print(f"[EMAIL DEV] Subject: {subject}", flush=True)
            print(f"[EMAIL DEV] Body:\n{html[:800]}", flush=True)
            print(f"{'='*60}\n", flush=True)
            return True

        resend.api_key = settings.RESEND_API_KEY
        try:
            await resend.Emails.send_async({
                "from": self.FROM_EMAIL,
                "to": [to],
                "subject": subject,
                "html": html,
            })
            return True
        except Exception as e:
            logger.exception("Error sending email via Resend: %s", e)
            return False

    async def enviar_verificacion(self, email: str, token: str, nombre: str) -> bool:
        link = f"{settings.FRONTEND_URL}/#/verify-email?token={token}"
        html = f"""
        <h1>¡Bienvenido a TrabajoYa, {nombre}!</h1>
        <p>Gracias por registrarte. Solo falta un paso para activar tu cuenta:</p>
        <a href="{link}" style="display:inline-block;padding:12px 24px;background:#2563eb;color:white;text-decoration:none;border-radius:8px;">
            Verificar mi email
        </a>
        <p>O copia este link: {link}</p>
        <p>Este enlace expira en 24 horas.</p>
        """
        return await self._send(email, "Verifica tu email — TrabajoYa", html)

    async def enviar_reset_password(self, email: str, token: str, nombre: str) -> bool:
        link = f"{settings.FRONTEND_URL}/#/reset-password?token={token}"
        html = f"""
        <h1>Restablecer contraseña</h1>
        <p>Hola {nombre}, recibimos una solicitud para cambiar tu contraseña:</p>
        <a href="{link}" style="display:inline-block;padding:12px 24px;background:#2563eb;color:white;text-decoration:none;border-radius:8px;">
            Cambiar contraseña
        </a>
        <p>O copia este link: {link}</p>
        <p>Este enlace expira en 1 hora. Si no solicitaste esto, ignora este email.</p>
        """
        return await self._send(email, "Restablece tu contraseña — TrabajoYa", html)

    async def enviar_bienvenida(self, email: str, nombre: str) -> bool:
        html = f"""
        <h1>¡Bienvenido a TrabajoYa, {nombre}!</h1>
        <p>Tu cuenta ha sido verificada exitosamente.</p>
        <p>Ya puedes comenzar a usar la plataforma:</p>
        <ul>
            <li>Si eres <b>cliente</b>: busca servicios cerca de ti</li>
            <li>Si eres <b>proveedor</b>: publica tus servicios y recibe solicitudes</li>
        </ul>
        <p>¡Gracias por confiar en TrabajoYa!</p>
        """
        return await self._send(email, "¡Cuenta verificada! — TrabajoYa", html)

    async def enviar_otp(self, email: str, codigo: str, nombre: str) -> bool:
        html = f"""
        <h1>Tu código de verificación</h1>
        <p>Hola {nombre},</p>
        <p>Usa este código para verificar tu teléfono:</p>
        <div style="font-size:32px;font-weight:bold;letter-spacing:8px;text-align:center;padding:24px;background:#F3F4F6;border-radius:12px;margin:16px 0;">
            {codigo}
        </div>
        <p>Este código expira en 10 minutos.</p>
        <p>Si no solicitaste esto, ignora este mensaje.</p>
        """
        return await self._send(email, "Tu código de verificación — TrabajoYa", html)


email_service = EmailService()
