import logging
import time

from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request, HTTPException, WebSocket, Query
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.config import settings
from app.core.limiter import limiter

# ─── Logging estructurado ─────────────────────────────
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer() if settings.DEBUG else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(logging.INFO),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)
logger = structlog.get_logger()

# ─── Rate Limiter (definido en app/core/limiter.py) ───


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("app_start", app_name=settings.APP_NAME, debug=settings.DEBUG)

    if "*" in settings.CORS_ORIGINS and settings.CORS_ORIGINS != ["*"]:
        logger.warning("cors_config_mixed_wildcard")

    yield
    logger.info("app_shutdown")


import sentry_sdk

if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment="development" if settings.DEBUG else "production",
        traces_sample_rate=1.0,
    )

# Docs (Swagger/ReDoc/OpenAPI) solo en desarrollo. En producción se ocultan
# para no exponer el esquema completo de la API.
app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    # Permitir localhost siempre para poder probar Flutter Web localmente contra Produccion
    allow_origin_regex=r"^https?://localhost(:\d+)?$",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Exception Handlers ───────────────────────────────
# El frontend espera siempre {"detail": "mensaje string"}


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    first_error = exc.errors()[0] if exc.errors() else {}
    field = " -> ".join(str(loc) for loc in first_error.get("loc", [])) if first_error else ""
    msg = first_error.get("msg", "Error de validación")
    detail = f"{field}: {msg}" if field else msg
    return JSONResponse(status_code=422, content={"detail": detail})


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    logger.exception("error_interno", path=request.url.path)
    return JSONResponse(status_code=500, content={"detail": "Error interno del servidor"})


# ─── Request logging middleware ───────────────────────
# El CORS lo maneja exclusivamente CORSMiddleware (orígenes restringidos vía
# settings.CORS_ORIGINS). Este middleware solo registra la request; NO inyecta
# cabeceras CORS ni responde OPTIONS (eso permitiría a cualquier origen).
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = round(time.time() - start, 4)
    logger.info(
        "request",
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        duration=duration,
    )
    return response


# ─── Routers ──────────────────────────────────────────
from app.api.routes_auth import router as auth_router
from app.api.routes_usuarios import router as usuarios_router
from app.api.routes_categorias import router as categorias_router
from app.api.routes_servicios import router as servicios_router
from app.api.routes_contrataciones import router as contrataciones_router
from app.api.routes_chat import router as chat_router
from app.api.routes_pagos import router as pagos_router
from app.api.routes_suscripciones import router as suscripciones_router
from app.api.routes_upload import router as upload_router
from app.api.routes_admin import router as admin_router
from app.api.routes_disputas import router as disputas_router
from app.api.routes_resenas import router as resenas_router
from app.api.routes_bugs import router as bugs_router
from app.api.routes_proveedores import router as proveedores_router
from app.api.routes_oportunidades import router as oportunidades_router
from app.api.routes_solicitudes import router as solicitudes_router
from app.api.routes_propuestas import router as propuestas_sub_router
from app.api.routes_propuestas import propuestas_router as propuestas_main_router
from app.api.routes_landing import router as landing_router
from app.api.routes_mercadopago import router as mercadopago_router

app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
app.include_router(usuarios_router, prefix=settings.API_V1_PREFIX)
app.include_router(categorias_router, prefix=settings.API_V1_PREFIX)
app.include_router(servicios_router, prefix=settings.API_V1_PREFIX)
app.include_router(contrataciones_router, prefix=settings.API_V1_PREFIX)
app.include_router(chat_router, prefix=settings.API_V1_PREFIX)
app.include_router(pagos_router, prefix=settings.API_V1_PREFIX)
app.include_router(suscripciones_router, prefix=settings.API_V1_PREFIX)
app.include_router(upload_router, prefix=settings.API_V1_PREFIX)
app.include_router(admin_router, prefix=settings.API_V1_PREFIX)
app.include_router(disputas_router, prefix=settings.API_V1_PREFIX)
app.include_router(resenas_router, prefix=settings.API_V1_PREFIX)
app.include_router(proveedores_router, prefix=settings.API_V1_PREFIX)
app.include_router(oportunidades_router, prefix=settings.API_V1_PREFIX)
app.include_router(solicitudes_router, prefix=settings.API_V1_PREFIX)
app.include_router(propuestas_sub_router, prefix=settings.API_V1_PREFIX)
app.include_router(propuestas_main_router, prefix=settings.API_V1_PREFIX)
app.include_router(bugs_router, prefix=settings.API_V1_PREFIX)
app.include_router(landing_router, prefix=settings.API_V1_PREFIX)
app.include_router(mercadopago_router, prefix=settings.API_V1_PREFIX)


@app.get("/health")
async def health_check():
    return {"status": "ok"}


@app.websocket("/api/v1/ws")
async def global_websocket(
    websocket: WebSocket,
    token: str = Query(None),
):
    import uuid
    from sqlalchemy import select
    from fastapi import WebSocketDisconnect
    from app.core.security import decode_access_token
    from app.database import async_session
    from app.models import Usuario
    from app.chat.connection_manager import manager

    ws_token = None
    subprotocols = websocket.headers.get("sec-websocket-protocol", "")
    accepted_subprotocol = None
    for protocol in subprotocols.split(","):
        protocol = protocol.strip()
        if protocol.startswith("access_token."):
            ws_token = protocol.replace("access_token.", "", 1)
            accepted_subprotocol = protocol
            break

    token = token or ws_token
    if not token:
        try:
            await websocket.accept()
        except Exception:
            pass
        await websocket.close(code=4001)
        return

    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            if accepted_subprotocol:
                await websocket.accept(subprotocol=accepted_subprotocol)
            else:
                await websocket.accept()
            await websocket.close(code=4001)
            return
    except Exception:
        if accepted_subprotocol:
            await websocket.accept(subprotocol=accepted_subprotocol)
        else:
            await websocket.accept()
        await websocket.close(code=4001)
        return

    if accepted_subprotocol:
        await websocket.accept(subprotocol=accepted_subprotocol)

    user_uuid = uuid.UUID(user_id)
    await manager.connect(user_id, websocket)

    # Marcar online en la base de datos
    async with async_session() as session:
        result = await session.execute(select(Usuario).where(Usuario.id == user_uuid))
        usuario = result.scalar_one_or_none()
        if usuario:
            usuario.is_online = True
            await session.commit()
    
    # Notificar a los demás que se conectó
    await manager.broadcast({"type": "estado:update"}, exclude=user_id)

    try:
        while True:
            # Mantener la conexión abierta
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)

        # Marcar offline solo si no le quedan otras conexiones activas (ej. múltiples pestañas)
        if not manager.is_user_connected(user_id):
            async with async_session() as session:
                result = await session.execute(select(Usuario).where(Usuario.id == user_uuid))
                usuario = result.scalar_one_or_none()
                if usuario:
                    usuario.is_online = False
                    await session.commit()
            
            # Notificar a los demás que se desconectó
            await manager.broadcast({"type": "estado:update"}, exclude=user_id)
