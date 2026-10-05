from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import json
import re

from app.api.dependencies import get_current_user, get_current_provider
from app.database import get_db
from app.models import EstadoServicio, Servicio, Usuario
from app.services.upload_service import upload_service

router = APIRouter(prefix="/upload", tags=["upload"])


@router.post("/documento")
async def upload_documento(
    selfie: UploadFile = File(...),
    documento: UploadFile = File(...),
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Sube selfie + documento de identidad (bucket privado) y deja la verificación
    en estado 'pending' para revisión manual del admin."""
    if current_user.doc_estado == "approved":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Tu identidad ya está verificada")
    try:
        r_selfie = await upload_service.upload_documento(selfie, str(current_user.id), "selfie")
        r_doc = await upload_service.upload_documento(documento, str(current_user.id), "documento")
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    current_user.doc_url = json.dumps({"selfie": r_selfie["path"], "documento": r_doc["path"]})
    current_user.doc_estado = "pending"
    current_user.doc_verified_at = None
    await db.commit()
    return {"estado": "pending", "message": "Documentos enviados. Quedan en revisión."}


@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        result = await upload_service.upload_avatar(file, str(current_user.id))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    current_user.avatar_url = result["url"]
    await db.commit()
    return {"url": result["url"]}


@router.post("/servicio/{servicio_id}")
async def upload_foto_servicio(
    servicio_id: str,
    file: UploadFile = File(...),
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Servicio).where(Servicio.id == servicio_id, Servicio.status != EstadoServicio.ELIMINADO)
    )
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    if servicio.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes modificar este servicio")

    # Fotos existentes (ARRAY de PostgreSQL, ya es lista)
    fotos_actuales = servicio.fotos if servicio.fotos else []
    if len(fotos_actuales) >= 5:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Máximo 5 fotos por servicio")

    try:
        result_upload = await upload_service.upload_foto_servicio(file, str(servicio.id), len(fotos_actuales))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    fotos_actuales.append(result_upload["url"])
    servicio.fotos = fotos_actuales
    await db.commit()

    return {"url": result_upload["url"], "fotos": fotos_actuales}


@router.post("/chat")
async def upload_chat_file(
    file: UploadFile = File(...),
    current_user: Usuario = Depends(get_current_user),
):
    try:
        result = await upload_service.upload_chat_file(file, str(current_user.id))
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    return {"url": result["url"]}


@router.delete("/{public_id}")
async def delete_upload(
    public_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if public_id.startswith(f"usuarios/{current_user.id}/"):
        pass  # el usuario borra su propio avatar

    elif public_id.startswith("servicios/"):
        m = re.match(r"^servicios/([^/]+)/", public_id)
        if not m:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="public_id inválido")
        servicio_id = m.group(1)
        result = await db.execute(
            select(Servicio).where(Servicio.id == servicio_id, Servicio.status != EstadoServicio.ELIMINADO)
        )
        servicio = result.scalar_one_or_none()
        if not servicio:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
        if servicio.proveedor_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes borrar archivos de un servicio que no te pertenece")

    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes permiso para borrar este archivo")

    ok = await upload_service.delete(public_id)
    if not ok:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Archivo no encontrado")

    return {"message": "Archivo eliminado"}
