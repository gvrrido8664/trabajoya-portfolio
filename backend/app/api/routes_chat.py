import json
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user
from app.chat.connection_manager import manager
from app.core.security import decode_access_token
from app.database import async_session, get_db
from app.models import Contratacion, Mensaje, Usuario
from app.schemas import MensajeResponse, MensajeEnviar

router = APIRouter(prefix="/chat", tags=["chat"])

@router.websocket("/ws/{contratacion_id}")
async def websocket_chat(
    websocket: WebSocket,
    contratacion_id: str,
    token: str = Query(None),
):
    print(f"--- 1. INTENTO DE CONEXIÓN WS - Contratación: {contratacion_id} ---")
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
            print("--- ❌ ERROR: Token sin user_id ---")
            if accepted_subprotocol:
                await websocket.accept(subprotocol=accepted_subprotocol)
            else:
                await websocket.accept()
            await websocket.close(code=4001)
            return
    except Exception as e:
        print(f"--- ❌ ERROR: Fallo al decodificar token: {e} ---")
        if accepted_subprotocol:
            await websocket.accept(subprotocol=accepted_subprotocol)
        else:
            await websocket.accept()
        await websocket.close(code=4001)
        return

    if accepted_subprotocol:
        await websocket.accept(subprotocol=accepted_subprotocol)

    print(f"--- 2. USUARIO IDENTIFICADO: {user_id} ---")
    user_uuid = uuid.UUID(user_id)

    async with async_session() as session:
        result = await session.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
        contratacion = result.scalar_one_or_none()
        if not contratacion:
            print("--- ❌ ERROR: Contratación no encontrada ---")
            await websocket.close(code=4004)
            return
        if user_uuid not in (contratacion.cliente_id, contratacion.proveedor_id):
            print("--- ❌ ERROR: Usuario no pertenece a la contratación ---")
            await websocket.close(code=4003)
            return

        otro_user_id = str(
            contratacion.proveedor_id if user_uuid == contratacion.cliente_id else contratacion.cliente_id
        )

    await manager.connect(user_id, websocket)
    print("--- 3. WEBSOCKET ACEPTADO Y MANAGER CONECTADO ---")
    
    # ... resto del código ...
    
    # ==========================================
    # CORRECCIÓN 1: Marcar Online al conectar
    # ==========================================
    async with async_session() as session:
        result = await session.execute(select(Usuario).where(Usuario.id == user_uuid))
        usuario = result.scalar_one_or_none()
        if usuario:
            usuario.is_online = True
            await session.commit()
    # Le avisa a todos los demás conectados que este usuario acaba de entrar
    await manager.broadcast({"type": "estado:update"}, exclude=user_id)

    try:
        while True:
            raw = await websocket.receive_text()
            data = json.loads(raw)
            contenido = data.get("contenido", "").strip()
            if not contenido:
                continue

            async with async_session() as session:
                mensaje = Mensaje(
                    contratacion_id=uuid.UUID(contratacion_id),
                    emisor_id=user_uuid,
                    contenido=contenido,
                )
                session.add(mensaje)
                await session.commit()
                await session.refresh(mensaje)

                payload_msg = {
                    "id": str(mensaje.id),
                    "contratacion_id": contratacion_id,
                    "emisor_id": user_id,
                    "contenido": contenido,
                    "leido": False,
                    "created_at": mensaje.created_at.isoformat(),
                }

            # Echo to ALL sender connections (multi-tab) + other user
            await manager.send_personal_message(user_id, payload_msg)
            await manager.send_personal_message(otro_user_id, payload_msg)

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
        
        # ==========================================
        # CORRECCIÓN 2: Marcar Offline al salir
        # ==========================================
        # Verificamos si realmente no le quedan más websockets activos a este usuario
        is_still_connected = user_id in manager.active_connections and len(manager.active_connections[user_id]) > 0
        
        if not is_still_connected:
            async with async_session() as session:
                result = await session.execute(select(Usuario).where(Usuario.id == user_uuid))
                usuario = result.scalar_one_or_none()
                if usuario:
                    usuario.is_online = False
                    await session.commit()
            
            # Avisa a los demás que se fue
            await manager.broadcast({"type": "estado:update"}, exclude=user_id)


@router.put("/{contratacion_id}/leer")
async def marcar_mensajes_leidos(
    contratacion_id: str,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Marca todos los mensajes no leídos de OTRO usuario como leídos."""
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este chat")

    await db.execute(
        update(Mensaje)
        .where(
            Mensaje.contratacion_id == contratacion_id,
            Mensaje.emisor_id != current_user.id,
            Mensaje.leido == False,
        )
        .values(leido=True)
    )
    await db.commit()

    # Notificar al otro usuario que sus mensajes fueron leídos
    otro_id = str(contratacion.proveedor_id if current_user.id == contratacion.cliente_id else contratacion.cliente_id)
    await manager.send_personal_message(otro_id, {
        "type": "mensajes:leido",
        "contratacion_id": contratacion_id,
    })

    return {"ok": True}


@router.post("/{contratacion_id}/mensajes", response_model=MensajeResponse, status_code=status.HTTP_201_CREATED)
async def enviar_mensaje(
    contratacion_id: str,
    data: MensajeEnviar,
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Envía un mensaje via REST (alternativa al WebSocket)."""
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este chat")

    mensaje = Mensaje(
        contratacion_id=uuid.UUID(contratacion_id),
        emisor_id=current_user.id,
        contenido=data.contenido,
    )
    db.add(mensaje)
    await db.commit()
    await db.refresh(mensaje)

    # Notificar via WebSocket a ambos usuarios de forma instantánea
    payload_msg = {
        "id": str(mensaje.id),
        "contratacion_id": contratacion_id,
        "emisor_id": str(current_user.id),
        "contenido": data.contenido,
        "leido": False,
        "created_at": mensaje.created_at.isoformat(),
    }
    otro_id = str(contratacion.proveedor_id if current_user.id == contratacion.cliente_id else contratacion.cliente_id)
    await manager.send_personal_message(str(current_user.id), payload_msg)
    await manager.send_personal_message(otro_id, payload_msg)

    return mensaje


@router.get("/{contratacion_id}/mensajes", response_model=list[MensajeResponse])
async def historial_mensajes(
    contratacion_id: str,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    current_user: Usuario = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Historial de mensajes de una contratación (REST, con paginación)."""
    result = await db.execute(select(Contratacion).where(Contratacion.id == contratacion_id))
    contratacion = result.scalar_one_or_none()
    if not contratacion:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contratación no encontrada")
    if current_user.id not in (contratacion.cliente_id, contratacion.proveedor_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No tienes acceso a este chat")

    result = await db.execute(
        select(Mensaje)
        .where(Mensaje.contratacion_id == contratacion_id)
        .order_by(Mensaje.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/conversaciones")
async def listar_conversaciones(
    current_user: Usuario = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Lista las contrataciones con último mensaje (vista previa tipo WhatsApp)."""
    base_query = select(Contratacion).where(
        (Contratacion.cliente_id == current_user.id) | (Contratacion.proveedor_id == current_user.id)
    )
    count_result = await db.execute(select(func.count()).select_from(base_query.subquery()))
    total = count_result.scalar() or 0

    result = await db.execute(
        base_query
        .options(selectinload(Contratacion.cliente), selectinload(Contratacion.proveedor))
        .offset(skip)
        .limit(limit)
        .order_by(Contratacion.updated_at.desc())
    )
    contrataciones = result.scalars().all()

    contratacion_ids = [c.id for c in contrataciones]

    ultimos_map = {}
    if contratacion_ids:
        result_msgs = await db.execute(
            select(Mensaje)
            .distinct(Mensaje.contratacion_id)
            .where(Mensaje.contratacion_id.in_(contratacion_ids))
            .order_by(Mensaje.contratacion_id, Mensaje.created_at.desc())
        )
        for m in result_msgs.scalars().all():
            ultimos_map[m.contratacion_id] = m

    no_leidos_map = {}
    if contratacion_ids:
        result_unread = await db.execute(
            select(Mensaje.contratacion_id, func.count(Mensaje.id))
            .where(
                Mensaje.contratacion_id.in_(contratacion_ids),
                Mensaje.emisor_id != current_user.id,
                Mensaje.leido == False,
            )
            .group_by(Mensaje.contratacion_id)
        )
        no_leidos_map = dict(result_unread.all())

    conversaciones = []
    seen_pares = set()

    for c in contrataciones:
        otro_id = str(c.proveedor_id if current_user.id == c.cliente_id else c.cliente_id)

        if otro_id in seen_pares:
            continue
        seen_pares.add(otro_id)

        otro_user = c.proveedor if current_user.id == c.cliente_id else c.cliente
        ultimo = ultimos_map.get(c.id)
        no_leidos = no_leidos_map.get(c.id, 0)

        # ==========================================
        # CORRECCIÓN 3: Formato esperado por Flutter
        # ==========================================
        conversaciones.append({
            "contratacion_id": str(c.id),
            "otro_usuario_nombre": f"{otro_user.nombre} {otro_user.apellido}" if otro_user else "Usuario",
            # Flutter busca este diccionario 'otro_usuario'
            "otro_usuario": {
                "id": otro_id,
                "avatar_url": otro_user.avatar_url if otro_user else None,
                # El rol de cuenta (Usuario.rol) es casi siempre "cliente" (toda
                # cuenta nace cliente); lo que el chat necesita mostrar es el rol
                # de la otra persona DENTRO de esta contratación, no de su cuenta.
                "rol": ("proveedor" if current_user.id == c.cliente_id else "cliente") if otro_user else "",
                "es_proveedor": otro_user.es_proveedor if otro_user else False,
                "is_online": otro_user.is_online if otro_user else False,
            },
            "ultimo_mensaje_contenido": ultimo.contenido if ultimo else None,
            "ultimo_mensaje_at": ultimo.created_at.isoformat() if ultimo else None,
            "mensajes_no_leidos_count": no_leidos,
            "status_contratacion": c.status.value.upper(),
        })

    return {"total": total, "limit": limit, "offset": skip, "items": conversaciones}