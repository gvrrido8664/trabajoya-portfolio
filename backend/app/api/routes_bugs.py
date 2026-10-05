from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user, get_current_admin
from app.database import get_db
from app.models import BugReport, Usuario
from app.schemas import BugReportCreate, BugReportResponse

router = APIRouter(tags=["bugs"])


@router.post("/bugs", response_model=BugReportResponse, status_code=status.HTTP_201_CREATED)
async def reportar_bug(
    data: BugReportCreate,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    bug = BugReport(
        usuario_id=current_user.id,
        titulo=data.titulo,
        descripcion=data.descripcion,
        area=data.area,
    )
    db.add(bug)
    await db.commit()
    await db.refresh(bug)
    return bug


@router.get("/bugs/mis-reportes", response_model=list[BugReportResponse])
async def mis_reportes(
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(BugReport)
        .where(BugReport.usuario_id == current_user.id)
        .order_by(BugReport.created_at.desc())
    )
    return result.scalars().all()


@router.get("/admin/bugs")
async def admin_listar_bugs(
    status_filter: str | None = Query(None, alias="status"),
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(BugReport)
    if status_filter:
        query = query.where(BugReport.status == status_filter)
    query = query.order_by(BugReport.created_at.desc())
    result = await db.execute(query)
    bugs = result.scalars().all()
    return {
        "total": len(bugs),
        "data": [
            {
                "id": str(b.id),
                "usuario_id": str(b.usuario_id),
                "titulo": b.titulo,
                "descripcion": b.descripcion,
                "area": b.area.value,
                "status": b.status.value,
                "created_at": b.created_at.isoformat(),
                "resolved_at": b.resolved_at.isoformat() if b.resolved_at else None,
            }
            for b in bugs
        ],
    }


@router.patch("/admin/bugs/{bug_id}")
async def admin_actualizar_bug(
    bug_id: str,
    status: str,
    _admin: Usuario = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(BugReport).where(BugReport.id == bug_id))
    bug = result.scalar_one_or_none()
    if not bug:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Bug no encontrado")

    bug.status = status
    if status == "resuelto":
        from datetime import datetime, timezone
        bug.resolved_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(bug.id), "status": bug.status.value}
