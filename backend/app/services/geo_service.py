from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession


def make_point_wkt(lat: float, lng: float) -> str:
    """Crea una representación WKT de un punto geográfico (SRID 4326)."""
    return f"POINT({lng} {lat})"


def make_point_func(lat: float, lng: float):
    """Devuelve una expresión SQLAlchemy para ST_GeogFromText."""
    return func.ST_GeogFromText(make_point_wkt(lat, lng))


async def buscar_por_radio(
    db: AsyncSession,
    model,
    lat: float,
    lng: float,
    radio_km: float,
    filtros_extra: list | None = None,
    skip: int = 0,
    limit: int = 20,
):
    """Búsqueda geoespacial genérica: filtra registros dentro de un radio (en km)."""
    point = make_point_func(lat, lng)
    radio_metros = radio_km * 1000

    query = select(model).where(
        model.ubicacion.isnot(None),
        func.ST_DWithin(model.ubicacion, point, radio_metros),
    )

    if filtros_extra:
        for f in filtros_extra:
            query = query.where(f)

    query = (
        query
        .order_by(func.ST_Distance(model.ubicacion, point))
        .offset(skip)
        .limit(limit)
    )

    result = await db.execute(query)
    return result.scalars().all()
