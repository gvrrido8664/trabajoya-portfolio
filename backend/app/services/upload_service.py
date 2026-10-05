"""
Servicio de subida de archivos a Supabase Storage.
Buckets requeridos (públicos): "avatars", "servicios"
"""
import asyncio

from fastapi import UploadFile
from supabase import create_client, Client

from app.core.config import settings


class UploadService:
    MAX_AVATAR_SIZE = 5 * 1024 * 1024    # 5 MB
    MAX_FOTO_SIZE   = 10 * 1024 * 1024   # 10 MB
    ALLOWED_TYPES   = {"image/jpeg", "image/png", "image/webp"}

    _client: Client | None = None

    def _get_client(self) -> Client:
        if self._client is None:
            self._client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)
        return self._client

    def _validate(self, file: UploadFile, max_size: int) -> None:
        if file.content_type not in self.ALLOWED_TYPES:
            raise ValueError("Formato no permitido. Usa JPEG, PNG o WebP")
        if file.size and file.size > max_size:
            raise ValueError(f"El archivo excede el tamaño máximo de {max_size // (1024 * 1024)} MB")

    def _ext(self, content_type: str) -> str:
        return {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}.get(content_type, "jpg")

    async def upload_avatar(self, file: UploadFile, user_id: str) -> dict:
        self._validate(file, self.MAX_AVATAR_SIZE)
        contents = await file.read()
        ext = self._ext(file.content_type)
        path = f"{user_id}/avatar.{ext}"
        client = self._get_client()

        await asyncio.to_thread(
            lambda: client.storage.from_("avatars").upload(
                path, contents,
                {"content-type": file.content_type, "upsert": "true"},
            )
        )
        url = client.storage.from_("avatars").get_public_url(path)
        return {"url": url, "public_id": f"avatars/{path}"}

    async def upload_foto_servicio(self, file: UploadFile, servicio_id: str, index: int) -> dict:
        self._validate(file, self.MAX_FOTO_SIZE)
        contents = await file.read()
        ext = self._ext(file.content_type)
        path = f"{servicio_id}/foto_{index}.{ext}"
        client = self._get_client()

        await asyncio.to_thread(
            lambda: client.storage.from_("servicios").upload(
                path, contents,
                {"content-type": file.content_type, "upsert": "true"},
            )
        )
        url = client.storage.from_("servicios").get_public_url(path)
        return {"url": url, "public_id": f"servicios/{path}"}

    async def upload_chat_file(self, file: UploadFile, user_id: str) -> dict:
        self._validate(file, self.MAX_FOTO_SIZE)
        contents = await file.read()
        ext = self._ext(file.content_type)
        ts = asyncio.get_running_loop().time()
        path = f"{user_id}/{int(ts * 1000)}.{ext}"
        client = self._get_client()

        await asyncio.to_thread(
            lambda: client.storage.from_("chat").upload(
                path, contents,
                {"content-type": file.content_type, "upsert": "true"},
            )
        )
        url = client.storage.from_("chat").get_public_url(path)
        return {"url": url, "public_id": f"chat/{path}"}

    async def upload_documento(self, file: UploadFile, user_id: str, tipo: str) -> dict:
        """Sube un documento de identidad al bucket PRIVADO 'documentos'.
        `tipo` ej: 'selfie' | 'documento'. Devuelve el path (no URL pública)."""
        self._validate(file, self.MAX_FOTO_SIZE)
        contents = await file.read()
        ext = self._ext(file.content_type)
        path = f"{user_id}/{tipo}.{ext}"
        client = self._get_client()
        await asyncio.to_thread(
            lambda: client.storage.from_("documentos").upload(
                path, contents,
                {"content-type": file.content_type, "upsert": "true"},
            )
        )
        return {"path": path}

    async def signed_url_documento(self, path: str, expires_in: int = 600) -> str | None:
        """URL firmada de corta duración para que el admin revise un documento privado."""
        client = self._get_client()
        try:
            res = await asyncio.to_thread(
                lambda: client.storage.from_("documentos").create_signed_url(path, expires_in)
            )
            return res.get("signedURL") or res.get("signedUrl") or res.get("signed_url")
        except Exception:
            return None

    async def delete(self, public_id: str) -> bool:
        # public_id format: "{bucket}/{path}"
        parts = public_id.split("/", 1)
        if len(parts) != 2:
            return False
        bucket, path = parts
        client = self._get_client()
        try:
            await asyncio.to_thread(
                lambda: client.storage.from_(bucket).remove([path])
            )
            return True
        except Exception:
            return False


upload_service = UploadService()
