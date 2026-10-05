from fastapi import WebSocket


class ConnectionManager:
    """Gestiona conexiones WebSocket activas por usuario."""

    def __init__(self):
        self.active_connections: dict[str, list[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        from fastapi.websockets import WebSocketState
        if websocket.client_state == WebSocketState.CONNECTING:
            await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].remove(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, user_id: str, message: dict):
        """Envía un mensaje a todas las conexiones de un usuario.

        Un socket puede quedar registrado pero ya cerrado (el cliente se
        fue sin completar el handshake de cierre) -- sin este try/except,
        ws.send_json() lanza y tumba al endpoint que llamó a esto (ej.
        marcar_mensajes_leidos), pese a que su propio trabajo ya había
        terminado bien. Los sockets muertos se descartan y limpian.
        """
        if user_id not in self.active_connections:
            return
        dead = []
        for ws in self.active_connections[user_id]:
            try:
                await ws.send_json(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(user_id, ws)

    async def broadcast(self, message: dict, exclude: str | None = None):
        """Envía a todos los conectados, opcionalmente excluyendo a uno."""
        dead: list[tuple[str, WebSocket]] = []
        for uid, connections in list(self.active_connections.items()):
            if uid == exclude:
                continue
            for ws in connections:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead.append((uid, ws))
        for uid, ws in dead:
            self.disconnect(uid, ws)
    
    def is_user_connected(self, user_id: str) -> bool:
        """Verifica si el usuario tiene al menos un socket activo."""
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0


manager = ConnectionManager()
