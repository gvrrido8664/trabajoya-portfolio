# API - Endpoints necesarios para el backend

Resumen: este documento lista los endpoints HTTP y eventos WebSocket que la app cliente (TrabajoYa) espera del backend, con método, path, autenticación requerida, parámetros y notas.

---

## Autenticación / Usuarios

- POST /auth/login
  - Body: { email, password }
  - Resp: { token, refreshToken, user }
  - Notes: JWT bearer

- POST /auth/register
  - Body: { name, email, password, role }
  - Resp: { user }

- POST /auth/logout
  - Auth: Bearer
  - Invalidate refresh token

- POST /auth/refresh
  - Body: { refreshToken }
  - Resp: { token, refreshToken }

- POST /auth/reset-password/request
  - Body: { email }
  - Sends reset link

- POST /auth/reset-password/confirm
  - Body: { token, newPassword }

- POST /auth/change-password
  - Auth: Bearer
  - Body: { currentPassword, newPassword }

- POST /auth/resend-verification
  - Body: { email }

- GET /usuarios/{id}
  - Resp: { userPublicData }
  - Used by: perfil público del proveedor

- PATCH /usuarios/{id}/avatar
  - Auth: Bearer
  - multipart/form-data: avatar file

## Servicios

- GET /servicios
  - Query: ?q=&categoria=&proveedorId=&skip=&limit=&sort=
  - Resp: [servicio], (optional) total
  - Pagination: skip & limit (or page & limit)

- GET /servicios/{id}
  - Resp: servicio detail (incluye fotos list)

- POST /servicios
  - Auth: Bearer (role: proveedor)
  - multipart/form-data: fields + fotos[] (multipart)
  - Resp: created servicio

- PATCH /servicios/{id}
  - Auth: Bearer (owner proveedor)
  - multipart/form-data allowed for replacing/adding fotos

- DELETE /servicios/{id}
  - Auth: Bearer (owner proveedor)

- POST /servicios/{id}/toggle-pause
  - Auth: Bearer (owner)

- GET /servicios/{id}/fotos
  - Resp: lista de URLs (opcional)

## Propuestas / Solicitudes (cliente ↔ proveedor)

- GET /solicitudes
  - Query: ?clienteId=&proveedorId=&skip=&limit=&status=

- POST /solicitudes
  - Auth: Bearer (cliente)
  - Body: { titulo, descripcion, categoriaId, presupuestoMax, ubicacionTexto }

- GET /solicitudes/{id}

- POST /propuestas
  - Auth: Bearer (proveedor)
  - Body: { solicitudId, precio, mensaje }

## Contrataciones

- GET /contrataciones
  - Query: ?usuarioId=&proveedorId=&skip=&limit=&status=

- GET /contrataciones/{id}

- POST /contrataciones
  - Auth: Bearer
  - Body: { propuestaId | servicioId, clienteId, detalles }

- POST /contrataciones/{id}/cancel
  - Auth: Bearer (cliente o proveedor según reglas)

- POST /contrataciones/{id}/dispute
  - Auth: Bearer
  - Body: { reason, details }

## Reseñas (reviews)

- GET /proveedores/{proveedorId}/resenas
  - Query: ?skip=&limit=
  - Resp: [resena], total (opcional)

- GET /usuarios/{usuarioId}/resenas
  - Query: ?skip=&limit=

- POST /contrataciones/{contratacionId}/resena
  - Auth: Bearer (cliente que completó contratacion)
  - Body: { puntuacion, comentario }
  - Resp: created resena

## Chat (WebSocket + HTTP fallback)

- WS /ws
  - Auth: query param token or subprotocol / header during handshake
  - Events (JSON):
    - cliente -> server: { type: 'mensaje:send', data: { conversacionId, text, attachments? } }
    - server -> cliente: { type: 'mensaje', data: { mensaje } }
    - server -> cliente: { type: 'conversaciones:update', data: { conversationSummary } }
  - Heartbeats / ping/pong recommended

- POST /chat/conversaciones/{id}/mensajes
  - Auth: Bearer
  - Body: { text }
  - Used as HTTP fallback and optimistic send

- GET /chat/conversaciones/{id}/mensajes
  - Query: ?skip=&limit=
  - Resp: [mensaje]

## Suscripciones / Pagos

- GET /suscripciones/planes
  - Resp: [plan]

- GET /usuarios/{id}/suscripcion
  - Auth: Bearer

- POST /suscripciones/subscribe
  - Auth: Bearer
  - Body: { planSlug }
  - Resp: { checkoutUrl } or immediate activation

- POST /suscripciones/cancel
  - Auth: Bearer

- POST /payments/webhook
  - Used by payment provider (verify signature)

- GET /pagos/historial
  - Auth: Bearer
  - Query: ?skip=&limit=

## Admin (roles/permissions)

- GET /admin/usuarios
  - Auth: Bearer (role: admin)
  - Query: ?q=&role=&skip=&limit=

- GET /admin/estadisticas/overview
  - Auth: Bearer (admin)

- PATCH /admin/usuarios/{id}/role
  - Auth: admin
  - Body: { role }

## Otros

- GET /categorias
  - Resp: [categoria]

- GET /config
  - Resp: app-level config (optional)

- Static/media hosting: URLs retornadas por servicios deben ser públicas o firmadas.

---

Notas generales:
- Usar autenticación Bearer (JWT) en headers: Authorization: Bearer <token>
- Normalizar paginación: prefer skip + limit or page + limit — usar consistentemente (la app actual usa skip & limit en muchos lugares).
- Para endpoints que devuelven listas, incluir opcionalmente { items: [...], total: N } para facilitar paginación en cliente.
- Multipart file uploads: fotos[] para servicios y avatar (avatar field single file).
- WS: documentar formato de evento y mensajes de error (ej. {type:'error', data:{code,msg}}).

