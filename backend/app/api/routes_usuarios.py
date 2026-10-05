from datetime import datetime, timezone

import structlog
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user, require_premium, get_current_provider
from app.database import get_db
from app.models import Usuario, Certificacion
from app.schemas import UbicacionUpdate, UsuarioPublicResponse, UsuarioResponse, UsuarioUpdate, CertificacionCreate, CertificacionResponse
from app.core.supabase import supabase
import uuid

router = APIRouter(prefix="/usuarios", tags=["usuarios"])
logger = structlog.get_logger()

@router.get("/me/certificaciones", response_model=list[CertificacionResponse])
async def mis_certificaciones(
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Certificacion).where(Certificacion.usuario_id == current_user.id)
    )
    return result.scalars().all()

@router.post("/me/certificaciones/upload")
async def upload_certificacion_file(
    file: UploadFile = File(...),
    current_user: Usuario = Depends(require_premium)
):
    if not supabase:
        raise HTTPException(status_code=500, detail="Supabase client not configured")
        
    try:
        file_ext = file.filename.split(".")[-1]
        file_name = f"{current_user.id}_{uuid.uuid4().hex}.{file_ext}"
        
        file_content = await file.read()
        
        res = supabase.storage.from_("certificaciones").upload(
            file_name,
            file_content,
            {"content-type": file.content_type}
        )
        
        public_url = supabase.storage.from_("certificaciones").get_public_url(file_name)
        return {"url": public_url}
    except Exception as e:
        # No propagar str(e) al cliente -- puede filtrar detalles internos
        # del SDK de Supabase (SEC-18). Se loguea acá porque envolver en
        # HTTPException evita que llegue al handler global (que sí loguea).
        logger.exception("error_subida_certificacion", error=str(e))
        raise HTTPException(status_code=500, detail="No se pudo subir el archivo")

@router.post("/me/certificaciones", response_model=CertificacionResponse)
async def agregar_certificacion(
    data: CertificacionCreate,
    current_user: Usuario = Depends(require_premium),
    db: AsyncSession = Depends(get_db),
):
    cert = Certificacion(
        usuario_id=current_user.id,
        titulo=data.titulo,
        institucion=data.institucion,
        archivo_url=data.archivo_url,
        fecha_emision=data.fecha_emision,
        estado="pending"
    )
    db.add(cert)
    await db.commit()
    await db.refresh(cert)
    return cert


@router.post("/me/activar-proveedor", response_model=UsuarioResponse)
async def activar_proveedor(
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Activa la capacidad proveedor sobre la cuenta actual. Requiere
    verificación de identidad aprobada. Idempotente: si ya está activa,
    devuelve el usuario sin cambios."""
    if current_user.es_proveedor:
        return current_user
    if current_user.doc_estado != "approved":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes aprobar la verificación de identidad para activar el modo proveedor",
        )
    current_user.es_proveedor = True
    current_user.proveedor_activado_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/{usuario_id}", response_model=UsuarioPublicResponse)
async def get_usuario(usuario_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Usuario).where(Usuario.id == usuario_id, Usuario.is_active == True))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")
    return user

@router.get("/{usuario_id}/certificaciones", response_model=list[CertificacionResponse])
async def get_usuario_certificaciones(usuario_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Certificacion)
        .where(Certificacion.usuario_id == usuario_id, Certificacion.estado == "approved")
    )
    return result.scalars().all()


@router.put("/me", response_model=UsuarioResponse)
async def update_usuario(
    data: UsuarioUpdate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(current_user, key, value)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.patch("/me/ubicacion")
async def update_ubicacion(
    data: UbicacionUpdate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    point_wkt = f"POINT({data.lng} {data.lat})"
    current_user.ubicacion = func.ST_GeogFromText(point_wkt)
    await db.commit()
    return {"message": "Ubicación actualizada"}


@router.get("/me/referidos")
async def mis_referidos(
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Estadísticas del programa de referidos del usuario."""
    result = await db.execute(
        select(Usuario).where(Usuario.referido_por == current_user.id)
    )
    referidos = result.scalars().all()

    return {
        "mi_codigo": current_user.codigo_referido,
        "total_referidos": current_user.referidos_count or 0,
        "referidos": [
            {
                "id": str(r.id),
                "nombre": r.nombre,
                "apellido": r.apellido,
                "is_verified": r.is_verified,
                "created_at": r.created_at.isoformat(),
            }
            for r in referidos
        ],
    }
