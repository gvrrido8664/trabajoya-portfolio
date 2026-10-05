import re
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_, select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from geoalchemy2.elements import WKTElement

from app.api.dependencies import get_current_provider, get_current_user
from app.database import get_db
from app.models import Categoria, EstadoServicio, Servicio, Usuario, Suscripcion, EstadoSuscripcion, Plan
from app.schemas import ServicioCreate, ServicioResponse, ServicioUpdate

router = APIRouter(prefix="/servicios", tags=["servicios"])


def _parse_ubicacion(ubicacion_str: str | None) -> tuple[float | None, float | None]:
    if not ubicacion_str:
        return None, None
    m = re.search(r'POINT\s*\(([\d\.\-e\+]+)\s+([\d\.\-e\+]+)\)', str(ubicacion_str))
    if m:
        lng = float(m.group(1))
        lat = float(m.group(2))
        return lat, lng
    return None, None


async def _enrich_servicios(servicios, db: AsyncSession = None):
    premium_provider_ids = set()
    if db and servicios:
        provider_ids = {s.proveedor_id for s in servicios if s.proveedor_id}
        if provider_ids:
            now = datetime.now(timezone.utc)
            stmt = (
                select(Suscripcion.usuario_id)
                .join(Plan, Plan.id == Suscripcion.plan_id)
                .where(
                    Suscripcion.usuario_id.in_(provider_ids),
                    Suscripcion.status == EstadoSuscripcion.ACTIVA,
                    Plan.slug == "premium",
                    (Suscripcion.fecha_vencimiento == None) | (Suscripcion.fecha_vencimiento > now)
                )
            )
            result = await db.execute(stmt)
            premium_provider_ids = {row[0] for row in result.all()}

    enriched = []
    for s in servicios:
        proveedor = s.proveedor
        categoria = s.categoria
        subcategoria = s.subcategoria
        lat, lng = _parse_ubicacion(s.ubicacion)
        is_premium = s.proveedor_id in premium_provider_ids
        
        enriched.append({
            "id": str(s.id),
            "proveedor_id": str(s.proveedor_id),
            "proveedor_nombre": f"{proveedor.nombre} {proveedor.apellido}" if proveedor else "",
            "proveedor_rating": proveedor.avg_rating_proveedor if proveedor else 0.0,
            "proveedor_doc_estado": proveedor.doc_estado if proveedor else "none",
            "proveedor_es_premium": is_premium,
            "categoria_id": str(s.categoria_id),
            "categoria_nombre": categoria.nombre if categoria else None,
            "categoria_icono": categoria.icono if categoria else None,
            "subcategoria_id": str(s.subcategoria_id) if s.subcategoria_id else None,
            "subcategoria_nombre": subcategoria.nombre if subcategoria else None,
            "subcategoria_icono": subcategoria.icono if subcategoria else None,
            "titulo": s.titulo,
            "descripcion": s.descripcion,
            "precio_min": s.precio_min,
            "precio_max": s.precio_max,
            "radio_cobertura_km": s.radio_cobertura_km,
            "direccion_texto": s.direccion_texto,
            "fotos": s.fotos,
            "es_destacado": s.es_destacado,
            "status": s.status.value.upper(),
            "distancia": None,
            "latitud": lat,
            "longitud": lng,
            "created_at": s.created_at.isoformat(),
            "updated_at": s.updated_at.isoformat(),
        })
    return enriched



@router.post("", response_model=ServicioResponse, status_code=status.HTTP_201_CREATED)
async def crear_servicio(
    data: ServicioCreate,
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes verificar tu email para publicar servicios",
        )
    if current_user.doc_estado != 'approved':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Debes verificar tu identidad para publicar servicios",
        )

    from app.models import Suscripcion, EstadoSuscripcion, Plan
    from sqlalchemy import func
    
    result_sub = await db.execute(
        select(Suscripcion)
        .options(selectinload(Suscripcion.plan))
        .where(Suscripcion.usuario_id == current_user.id, Suscripcion.status == EstadoSuscripcion.ACTIVA)
        .order_by(Suscripcion.created_at.desc())
        .limit(1)
    )
    sub = result_sub.scalar_one_or_none()
    plan_slug = sub.plan.slug if sub and sub.plan else "basico"

    if plan_slug == "basico":
        result_count = await db.execute(
            select(func.count(Servicio.id)).where(
                Servicio.proveedor_id == current_user.id,
                Servicio.status != EstadoServicio.ELIMINADO
            )
        )
        total_servicios = result_count.scalar() or 0
        if total_servicios >= 2:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Límite alcanzado: el plan Básico permite publicar un máximo de 2 servicios."
            )

    servicio = Servicio(
        proveedor_id=current_user.id,
        **data.model_dump(exclude={"latitud", "longitud"}),
    )
    if data.latitud is not None and data.longitud is not None:
        servicio.ubicacion = WKTElement(f"POINT({data.longitud} {data.latitud})", srid=4326)
    db.add(servicio)
    await db.commit()
    await db.refresh(servicio)
    return servicio


@router.get("")
async def listar_servicios(
    q: str | None = Query(None),
    categoria_id: str | None = Query(None),
    categoria_padre_id: str | None = Query(None),
    subcategoria_id: str | None = Query(None),
    proveedor_id: str | None = Query(None),
    activos: bool | None = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    # categoria_padre_id es alias de categoria_id (compatibilidad con el cliente Flutter)
    cat_id = categoria_id or categoria_padre_id

    if proveedor_id:
        query = select(Servicio).where(
            Servicio.proveedor_id == proveedor_id,
            Servicio.status != EstadoServicio.ELIMINADO,
        )
    else:
        query = select(Servicio).where(Servicio.status == EstadoServicio.ACTIVO)

    if activos is False:
        query = select(Servicio)

    if subcategoria_id:
        query = query.where(Servicio.subcategoria_id == subcategoria_id)
    elif cat_id:
        query = query.where(Servicio.categoria_id == cat_id)

    if q:
        like_pattern = f"%{q}%"
        query = query.join(Categoria, Servicio.categoria_id == Categoria.id, isouter=True)
        query = query.where(
            or_(
                Servicio.titulo.ilike(like_pattern),
                Servicio.descripcion.ilike(like_pattern),
                Categoria.nombre.ilike(like_pattern),
            )
        )

    now = datetime.now(timezone.utc)
    is_premium_subquery = (
        select(func.count(Suscripcion.id) > 0)
        .join(Plan, Plan.id == Suscripcion.plan_id)
        .where(
            Suscripcion.usuario_id == Servicio.proveedor_id,
            Suscripcion.status == EstadoSuscripcion.ACTIVA,
            Plan.slug == "premium",
            (Suscripcion.fecha_vencimiento == None) | (Suscripcion.fecha_vencimiento > now)
        )
        .scalar_subquery()
    )

    query = query.offset(skip).limit(limit).order_by(is_premium_subquery.desc(), Servicio.created_at.desc())
    query = query.options(
        selectinload(Servicio.proveedor),
        selectinload(Servicio.categoria),
        selectinload(Servicio.subcategoria),
    )
    result = await db.execute(query)
    servicios = result.scalars().all()
    return await _enrich_servicios(servicios, db)


@router.get("/buscar")
async def buscar_servicios_cercanos(
    lat: float = Query(...),
    lng: float = Query(...),
    radio_km: float | None = Query(None, description="Si se omite, usa el radio_cobertura_km propio de cada servicio"),
    categoria_id: str | None = Query(None, description="Filtrar por categoria raiz"),
    subcategoria_id: str | None = Query(None, description="Filtrar por subcategoria especifica"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import func

    point_wkt = f"POINT({lng} {lat})"
    distancia_expr = radio_km * 1000 if radio_km is not None else Servicio.radio_cobertura_km * 1000
    now = datetime.now(timezone.utc)
    is_premium_subquery = (
        select(func.count(Suscripcion.id) > 0)
        .join(Plan, Plan.id == Suscripcion.plan_id)
        .where(
            Suscripcion.usuario_id == Servicio.proveedor_id,
            Suscripcion.status == EstadoSuscripcion.ACTIVA,
            Plan.slug == "premium",
            (Suscripcion.fecha_vencimiento == None) | (Suscripcion.fecha_vencimiento > now)
        )
        .scalar_subquery()
    )

    query = (
        select(Servicio)
        .where(
            Servicio.status == EstadoServicio.ACTIVO,
            Servicio.ubicacion.isnot(None),
            func.ST_DWithin(
                Servicio.ubicacion,
                func.ST_GeogFromText(point_wkt),
                distancia_expr,
            ),
        )
        .order_by(
            # Respetar cercanía: agrupar por banda de 2 km y, dentro de cada
            # banda, priorizar Premium; luego por distancia exacta. Así un
            # Premium lejano no supera a un no-Premium claramente más cercano.
            func.floor(
                func.ST_Distance(
                    Servicio.ubicacion, func.ST_GeogFromText(point_wkt)
                ) / 2000
            ).asc(),
            is_premium_subquery.desc(),
            func.ST_Distance(
                Servicio.ubicacion,
                func.ST_GeogFromText(point_wkt),
            ).asc(),
        )
    )
    if subcategoria_id:
        query = query.where(Servicio.subcategoria_id == subcategoria_id)
    elif categoria_id:
        query = query.where(Servicio.categoria_id == categoria_id)
    query = query.offset(skip).limit(limit)
    query = query.options(
        selectinload(Servicio.proveedor),
        selectinload(Servicio.categoria),
        selectinload(Servicio.subcategoria),
    )
    result = await db.execute(query)
    servicios = result.scalars().all()
    return await _enrich_servicios(servicios, db)


@router.get("/{servicio_id}")
async def get_servicio(servicio_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Servicio)
        .options(
            selectinload(Servicio.proveedor),
            selectinload(Servicio.categoria),
            selectinload(Servicio.subcategoria),
        )
        .where(Servicio.id == servicio_id, Servicio.status != EstadoServicio.ELIMINADO)
    )
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    enriched = await _enrich_servicios([servicio], db)
    return enriched[0]


@router.put("/{servicio_id}", response_model=ServicioResponse)
async def update_servicio(
    servicio_id: str,
    data: ServicioUpdate,
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Servicio).where(Servicio.id == servicio_id))
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    if servicio.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes editar un servicio ajeno")

    update_data = data.model_dump(exclude_unset=True, exclude={"latitud", "longitud"})
    for key, value in update_data.items():
        setattr(servicio, key, value)

    if "latitud" in data.model_dump(exclude_unset=True) or "longitud" in data.model_dump(exclude_unset=True):
        if data.latitud is not None and data.longitud is not None:
            servicio.ubicacion = WKTElement(f"POINT({data.longitud} {data.latitud})", srid=4326)
        else:
            servicio.ubicacion = None

    await db.commit()
    await db.refresh(servicio)
    return servicio


@router.post("/{servicio_id}/destacar")
async def toggle_destacar(
    servicio_id: str,
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Servicio).where(Servicio.id == servicio_id))
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    if servicio.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes modificar un servicio ajeno")

    servicio.es_destacado = not servicio.es_destacado
    await db.commit()
    return {"es_destacado": servicio.es_destacado}


@router.patch("/{servicio_id}/pausar")
async def toggle_pausar(
    servicio_id: str,
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Servicio).where(Servicio.id == servicio_id))
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    if servicio.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes modificar un servicio ajeno")

    if servicio.status == EstadoServicio.ACTIVO:
        servicio.status = EstadoServicio.PAUSADO
    elif servicio.status == EstadoServicio.PAUSADO:
        servicio.status = EstadoServicio.ACTIVO
    await db.commit()
    return {"status": servicio.status.value.upper()}


@router.delete("/{servicio_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_servicio(
    servicio_id: str,
    current_user: Usuario = Depends(get_current_provider),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Servicio).where(Servicio.id == servicio_id))
    servicio = result.scalar_one_or_none()
    if not servicio:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Servicio no encontrado")
    if servicio.proveedor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No puedes eliminar un servicio ajeno")

    servicio.status = EstadoServicio.ELIMINADO
    await db.commit()
