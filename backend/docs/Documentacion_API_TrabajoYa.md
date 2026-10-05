# Documentación API TrabajoYa

## 1. Documentación Completa del Backend

### 1.1 Arquitectura y Stack

| Capa | Tecnología |
|------|-----------|
| Framework | **FastAPI 1.0+** (async, OpenAPI automático en `/docs`) |
| ASGI | Uvicorn |
| ORM | **SQLAlchemy 2.0** async con asyncpg |
| Base de Datos | **PostgreSQL 16 + PostGIS 3.4** (geográfico) |
| Validación | **Pydantic 2** (strict, `from_attributes=True`) |
| Auth | **JWT** (python-jose) + **bcrypt** |
| Rate Limiting | SlowAPI (100 req/min global) |
| Migraciones | Alembic |
| Logging | structlog (colores en dev, JSON en prod) |

**Estructura de carpetas:**
```
app/
├── main.py              # FastAPI app, middlewares, exception handlers, router registration
├── database.py          # Engine async, session factory, get_db()
├── core/
│   ├── config.py        # Settings via Pydantic (variables de entorno)
│   └── security.py      # JWT creation/decoding, bcrypt hash/verify
├── models/              # SQLAlchemy ORM (13 tablas)
├── schemas/             # Pydantic request/response
├── api/
│   ├── dependencies.py  # get_current_user, get_current_provider, get_current_admin
│   └── routes_*.py      # 16 routers
├── services/            # Integraciones externas
└── chat/                # WebSocket ConnectionManager
```

### 1.2 Flujos Principales

**Autenticación (JWT):**
```
POST /auth/register → hash_password + create_access_token + create_email_verification_token
POST /auth/login    → verify_password + create_access_token (7 días exp)
GET  /auth/me       → decode_access_token + query DB → UsuarioResponse
```
El token JWT contiene `{"sub": "<user_id>", "exp": <timestamp>}`. Se envía como `Authorization: Bearer <token>`. Las dependencias `get_current_user`, `get_current_provider`, `get_current_admin` verifican el token y el rol.

**Flujo de negocio (Servicio → Contratar → Pagar → Finalizar → Reseñar):**
```
1. Proveedor crea servicio (POST /servicios) → Estado: ACTIVO
2. Cliente busca servicios (GET /servicios/buscar) con filtro geoespacial
3. Cliente contrata (POST /contrataciones) → Estado: PENDIENTE
4. Proveedor acepta (PATCH /contrataciones/{id}/aceptar) → Estado: ACEPTADO
5. Cliente paga garantía (POST /pagos/crear) → Webhook MP → Pago APROBADO
6. Cualquier parte finaliza (PATCH /contrataciones/{id}/finalizar) → Estado: COMPLETADO
   (requiere pago aprobado si viene de servicio directo)
7. Cliente/Proveedor reseña (POST /contrataciones/{id}/resena) → avg_rating se recalcula
```

**Flujo alternativo (Solicitudes + Propuestas):**
```
1. Cliente crea solicitud (POST /solicitudes) → Estado: ABIERTA
2. Proveedores envían propuestas (POST /solicitudes/{id}/propuestas)
3. Cliente acepta una propuesta (PATCH .../propuestas/{id}/aceptar) →
   - Se crea Contratacion automáticamente con propuesta_id
   - Solicitud pasa a CERRADA
   - Otras propuestas pasan a RECHAZADAS
4. Continúa flujo normal (pago → finalizar → reseña)
```

**Búsqueda Geoespacial (`/servicios/buscar`):**
```sql
SELECT ... WHERE ST_DWithin(ubicacion, ST_GeogFromText('POINT(lng lat)'), radio_km * 1000)
ORDER BY ST_Distance(ubicacion, ST_GeogFromText('POINT(lng lat)'))
```
Usa PostGIS con columnas `Geography(POINT, 4326)`. Parámetros requeridos: `lat`, `lng`, opcional `radio_km` (default 10).

**Máquina de estados de Contratación:**
```
PENDIENTE → ACEPTADO → COMPLETADO → (opcional) DISPUTA
         → RECHAZADO
         → CANCELADO
```

### 1.3 Integraciones Externas

| Integración | Propósito | Endpoints involucrados | Configuración requerida |
|------------|-----------|----------------------|------------------------|
| **MercadoPago** | Pasarela de pagos (Checkout Pro) | `POST /pagos/crear` → crea preferencia MP; `POST /pagos/webhooks/mercadopago` → recibe notificación; webhook marca pago como APROBADO y contratación como COMPLETADA | `MP_ACCESS_TOKEN`, `MP_PUBLIC_KEY`, `MP_WEBHOOK_SECRET` |
| **Resend** | Email transaccional (verificación, bienvenida, reset password) | `POST /auth/register` → email verificación; `POST /auth/forgot-password` → email reset | `RESEND_API_KEY` — Si no está configurado, hace `print` en consola en lugar de enviar |
| **Cloudinary** | Almacenamiento de imágenes (avatares, fotos de servicio) | `POST /upload/avatar` (400x400 thumb); `POST /upload/servicio/{id}` (1200x800, máx 5 fotos); `DELETE /upload/{public_id}` | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` |
| **Firebase (FCM)** | Notificaciones push (implementación base, no bloqueante) | No expuesto directamente en rutas — llamado desde servicios internos | `FIREBASE_CREDENTIALS_PATH` — Si no está configurado, retorna `None` |

---

## 2. Contrato de la API (Request y Response)

### Módulo: Health

#### `GET /health`
- **Headers:** Ninguno
- **Request:** (vacio)
- **Response:**
```json
{"status": "ok"}
```

---

### Módulo: Auth — Prefijo `/api/v1/auth`

#### `POST /api/v1/auth/register`
- **Headers:** Ninguno
- **Request (body):**
```json
{
  "email": "juan@ejemplo.cl",
  "password": "MiPassword123",
  "nombre": "Juan",
  "apellido": "Perez",
  "telefono": "+56912345678",
  "rol": "cliente"
}
```
- **Query Params:** `?ref=CODIGO` (string, opcional — codigo de referido)
- **Response 201:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "3e8a7c1b-aaaa-4bbb-8888-cccccccccccc",
    "email": "juan@ejemplo.cl",
    "nombre": "Juan",
    "apellido": "Perez",
    "telefono": "+56912345678",
    "rol": "cliente",
    "avatar_url": null,
    "bio": null,
    "habilidades": null,
    "is_active": true,
    "is_verified": false,
    "avg_rating": 0.0,
    "referidos_count": 0,
    "codigo_referido": "A7XK9M2P",
    "created_at": "2026-06-17T12:00:00Z",
    "updated_at": "2026-06-17T12:00:00Z",
    "email_verificado": false
  }
}
```
- **Errores:** `409` email duplicado, `400` rol invalido

#### `POST /api/v1/auth/login`
- **Headers:** Ninguno
- **Request (body):**
```json
{
  "email": "juan@ejemplo.cl",
  "password": "MiPassword123"
}
```
- **Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```
- **Errores:** `400` credenciales invalidas, `403` cuenta desactivada

#### `GET /api/v1/auth/me`
- **Headers:** `Authorization: Bearer <token>`
- **Request:** (vacio)
- **Response 200:** Mismo que `user` en register, incluyendo `email_verificado`
- **Errores:** `401` token invalido/expirado

#### `GET /api/v1/auth/verify-email`
- **Headers:** Ninguno
- **Query:** `?token=<email_verification_token>`
- **Response 200:**
```json
{"message": "Email verificado exitosamente"}
```

#### `POST /api/v1/auth/forgot-password`
- **Headers:** Ninguno
- **Request (body):** `{"email": "juan@ejemplo.cl"}`
- **Response 200 (siempre):**
```json
{"message": "Si el email existe, recibiras un link para restablecer tu contraseña"}
```

#### `POST /api/v1/auth/reset-password`
- **Headers:** Ninguno
- **Request (body):**
```json
{
  "token": "eyJ...",
  "new_password": "NuevaPass123"
}
```
- **Response 200:**
```json
{"message": "Contraseña actualizada exitosamente"}
```

---

### Módulo: Usuarios — Prefijo `/api/v1/usuarios`

#### `GET /api/v1/usuarios/{usuario_id}`
- **Headers:** Ninguno (publico)
- **Response 200:**
```json
{
  "id": "3e8a7c1b-...",
  "email": "proveedor1@trabajoya.cl",
  "nombre": "Carlos",
  "apellido": "Munoz",
  "telefono": "+56912345678",
  "rol": "proveedor",
  "avatar_url": "https://res.cloudinary.com/...",
  "bio": "Soy Carlos, ofrezco servicios de calidad...",
  "habilidades": "[\"Plomeria\", \"Electricidad\"]",
  "is_active": true,
  "is_verified": true,
  "avg_rating": 4.5,
  "codigo_referido": "A7XK9M2P",
  "referidos_count": 3,
  "created_at": "2026-06-17T12:00:00Z",
  "updated_at": "2026-06-17T12:00:00Z",
  "email_verificado": true
}
```

#### `PUT /api/v1/usuarios/me`
- **Headers:** `Authorization: Bearer <token>`
- **Request (body):**
```json
{
  "nombre": "Juan Carlos",
  "apellido": "Perez Garcia",
  "telefono": "+56987654321",
  "bio": "Profesional con experiencia",
  "habilidades": "Plomeria, Electricidad",
  "avatar_url": "https://..."
}
```
- **Response 200:** `UsuarioResponse` actualizado

#### `PATCH /api/v1/usuarios/me/ubicacion` — ⚠️ BUG: referencia a columna eliminada
- **Headers:** `Authorization: Bearer <token>`
- **Request:**
```json
{
  "lat": -33.4489,
  "lng": -70.6693
}
```
- **El modelo `Usuario` ya no tiene campo `ubicacion`. Este endpoint tira `AttributeError`.**

#### `GET /api/v1/usuarios/me/referidos` — ⚠️ BUG: referencia a columna eliminada
- **Headers:** `Authorization: Bearer <token>`
- **Intenta `select(Usuario).where(Usuario.referido_por == ...)`. `Usuario.referido_por` fue eliminado del modelo.**

---

### Módulo: Categorias — Prefijo `/api/v1/categorias`

#### `GET /api/v1/categorias`
- **Headers:** Ninguno (publico)
- **Response 200:**
```json
[
  {
    "id": "a1b2c3d4-...",
    "nombre": "Plomeria",
    "slug": "plomeria",
    "icono": null,
    "descripcion": "Reparacion e instalacion de tuberias..."
  }
]
```

#### `GET /api/v1/categorias/{slug}`
- **Response 200:** Misma estructura, categoria individual

---

### Módulo: Servicios — Prefijo `/api/v1/servicios`

#### `POST /api/v1/servicios`
- **Headers:** `Authorization: Bearer <token>` (rol proveedor/admin)
- **Request (body):**
```json
{
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomeria a domicilio",
  "descripcion": "Reparacion de llaves, tuberias y calefont",
  "precio_min": 15000,
  "precio_max": 80000,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Chile",
  "fotos": ["https://..."]
}
```
- **Response 201:**
```json
{
  "id": "c3d4e5f6-...",
  "proveedor_id": "3e8a7c1b-...",
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomeria a domicilio",
  "descripcion": "Reparacion de llaves, tuberias y calefont",
  "status": "activo",
  "precio_min": 15000.0,
  "precio_max": 80000.0,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Chile",
  "fotos": ["https://..."],
  "es_destacado": false,
  "distancia": null,
  "proveedor_nombre": null,
  "proveedor_rating": null,
  "categoria_nombre": null,
  "created_at": "2026-06-17T12:00:00Z",
  "updated_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/servicios`
- **Headers:** Ninguno (publico)
- **Query params:** `?categoria_id=UUID` (opcional), `&proveedor_id=UUID` (opcional), `&skip=0`, `&limit=20` (max 100)
- **Response 200:** `[ServicioResponse enriched]` — incluye `proveedor_nombre`, `proveedor_rating`, `categoria_nombre`

#### `GET /api/v1/servicios/buscar`
- **Headers:** Ninguno (publico)
- **Query params:** `?lat=-33.4489&lng=-70.6693` (obligatorios), `&radio_km=10` (opcional, default 10), `&categoria_id=UUID` (opcional), `&skip=0&limit=20`
- **Response 200:** `[ServicioResponse enriched]` ordenados por distancia

#### `GET /api/v1/servicios/{servicio_id}`
- **Response 200:** `ServicioResponse enriched` individual

#### `PUT /api/v1/servicios/{servicio_id}`
- **Headers:** `Authorization: Bearer <token>` (propietario)
- **Request:** Mismos campos que create, todos opcionales
- **Response 200:** `ServicioResponse`

#### `POST /api/v1/servicios/{servicio_id}/destacar`
- **Headers:** `Authorization: Bearer <token>` (propietario)
- **Response 200:** `{"es_destacado": true}` (toggle)

#### `PATCH /api/v1/servicios/{servicio_id}/pausar`
- **Headers:** `Authorization: Bearer <token>` (propietario)
- **Response 200:** `{"status": "PAUSADO"}` (toggle activo <-> pausado)

#### `DELETE /api/v1/servicios/{servicio_id}`
- **Headers:** `Authorization: Bearer <token>` (propietario)
- **Response 204:** Sin contenido (eliminacion logica -> status ELIMINADO)

---

### Módulo: Contrataciones — Prefijo `/api/v1/contrataciones`

#### `POST /api/v1/contrataciones`
- **Headers:** `Authorization: Bearer <token>` (rol cliente)
- **Request (body):**
```json
{
  "servicio_id": "c3d4e5f6-...",
  "monto_acordado": 45000,
  "mensaje_solicitud": "Hola, necesito arreglar una llave...",
  "fecha_programada": "2026-06-20T15:00:00Z"
}
```
- **Response 201:**
```json
{
  "id": "d4e5f6a7-...",
  "cliente_id": "4f9b8c2d-...",
  "proveedor_id": "3e8a7c1b-...",
  "servicio_id": "c3d4e5f6-...",
  "propuesta_id": null,
  "status": "PENDIENTE",
  "monto_acordado": 45000.0,
  "mensaje_solicitud": "Hola, necesito arreglar una llave...",
  "fecha_programada": "2026-06-20T15:00:00Z",
  "created_at": "2026-06-17T12:00:00Z",
  "updated_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/contrataciones`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:** Array enriquecido con `cliente_nombre`, `proveedor_nombre`, `servicio_titulo`, `propuesta_id`

#### `GET /api/v1/contrataciones/{contratacion_id}`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Response 200:** Misma estructura enriquecida individual

#### `PATCH /api/v1/contrataciones/{contratacion_id}/aceptar`
- **Headers:** `Authorization: Bearer <token>` (proveedor)
- **Response 200:** `{"status": "ACEPTADO"}`

#### `PATCH /api/v1/contrataciones/{contratacion_id}/rechazar`
- **Headers:** `Authorization: Bearer <token>` (proveedor)
- **Response 200:** `{"status": "RECHAZADO"}`

#### `PATCH /api/v1/contrataciones/{contratacion_id}/finalizar`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Response 200:** `{"status": "COMPLETADO"}`
- **Validacion extra:** Si viene de servicio directo (tiene `servicio_id`), requiere pago APROBADO

#### `POST /api/v1/contrataciones/{contratacion_id}/resena`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Request (body):**
```json
{
  "puntuacion": 5,
  "comentario": "Excelente servicio"
}
```
- **Response 201:**
```json
{
  "id": "e5f6a7b8-...",
  "contratacion_id": "d4e5f6a7-...",
  "calificador_id": "4f9b8c2d-...",
  "calificado_id": "3e8a7c1b-...",
  "puntuacion": 5,
  "comentario": "Excelente servicio",
  "created_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/contrataciones/usuario/{usuario_id}/resenas`
- **Headers:** Ninguno (publico)
- **Response 200:** `[ResenaResponse]`

---

### Módulo: Resenas — Prefijo `/api/v1/resenas` — ⚠️ Ruta duplicada

#### `POST /api/v1/resenas/{contratacion_id}`
- **Headers:** `Authorization: Bearer <token>` (solo cliente)
- **Request/Response:** Identico a `POST /contrataciones/{id}/resena` pero solo permite al cliente

#### `GET /api/v1/resenas/usuario/{usuario_id}`
- **Response 200:** `[ResenaResponse]` (publico, resenas recibidas)

> **Nota:** Este modulo duplica funcionalidad de `routes_contrataciones.py`. El frontend debe usar el endpoint de contrataciones (`POST /contrataciones/{id}/resena`) que permite resenar a ambos participantes.

---

### Módulo: Chat — Prefijo `/api/v1/chat`

#### `WebSocket /api/v1/chat/ws/{contratacion_id}?token=<jwt>`
- **Conexion:** Query param `token` requerido. Sin cookie/sin header.
- **Autenticacion:** El token JWT se decodifica, se verifica que el usuario sea participante de la contratacion.
- **Formato mensaje enviado (cliente -> servidor):**
```json
{"contenido": "Hola, que tal?"}
```
- **Formato mensaje recibido (servidor -> clientes):**
```json
{
  "id": "f6a7b8c9-...",
  "contratacion_id": "d4e5f6a7-...",
  "emisor_id": "3e8a7c1b-...",
  "contenido": "Hola, que tal?",
  "leido": false,
  "created_at": "2026-06-17T12:00:00Z"
}
```
- **Broadcast:** El mensaje se envia al otro participante y tambien al emisor (echo).
- **Codigos de cierre:** `4001` token invalido, `4003` no eres participante, `4004` contratacion no encontrada.

#### `POST /api/v1/chat/{contratacion_id}/mensajes`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Request (body):**
```json
{"contenido": "Hola, que tal?"}
```
- **Response 201:**
```json
{
  "id": "f6a7b8c9-...",
  "contratacion_id": "d4e5f6a7-...",
  "emisor_id": "3e8a7c1b-...",
  "contenido": "Hola, que tal?",
  "leido": false,
  "created_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/chat/{contratacion_id}/mensajes`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Query:** `?skip=0&limit=50` (max 200)
- **Response 200:** `[MensajeResponse]` ordenado por fecha descendente

#### `GET /api/v1/chat/conversaciones`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:**
```json
[
  {
    "contratacion_id": "d4e5f6a7-...",
    "otro_usuario_id": "3e8a7c1b-...",
    "otro_usuario_nombre": "Carlos Munoz",
    "ultimo_mensaje": "Hola, que tal?",
    "ultimo_mensaje_fecha": "2026-06-17T12:00:00Z",
    "mensajes_no_leidos": 2,
    "status_contratacion": "ACEPTADO"
  }
]
```
- **Deduplicacion:** Solo retorna una conversacion por par de usuarios (la mas reciente).

---

### Módulo: Pagos — Prefijo `/api/v1/pagos`

#### `POST /api/v1/pagos/crear?contratacion_id=UUID`
- **Headers:** `Authorization: Bearer <token>` (solo cliente)
- **Response 200:**
```json
{
  "id": "preference_id_123",
  "init_point": "https://www.mercadopago.cl/checkout/v1/redirect?pref_id=123",
  "sandbox_init_point": "https://sandbox.mercadopago.cl/checkout/v1/redirect?pref_id=123",
  "preference_id": "123456789-abc",
  "external_reference": "d4e5f6a7-...",
  "status": "pending"
}
```

#### `POST /api/v1/pagos/webhooks/pagos`
- **Headers:** Ninguno (publico)
- **Request:** Body raw de MercadoPago
- **Response:** `{"status": "procesado"}`

#### `GET /api/v1/pagos/{contratacion_id}/estado`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Response 200:**
```json
{
  "status": "aprobado",
  "monto": 25000.0,
  "fee_plataforma": 2500.0,
  "monto_neto": 22500.0
}
```
- **Status posibles:** `PENDIENTE`, `APROBADO`, `RECHAZADO`, `CANCELADO`

---

### Módulo: Suscripciones — Prefijo `/api/v1/suscripciones`

#### `POST /api/v1/suscripciones/crear`
- **Headers:** `Authorization: Bearer <token>` (rol proveedor)
- **Request (body):**
```json
{"plan_slug": "premium"}
```
- **Response 200:** Preferencia de MercadoPago para el pago mensual

#### `GET /api/v1/suscripciones/me`
- **Headers:** `Authorization: Bearer <token>` (rol proveedor)
- **Response 200 (con suscripcion):**
```json
{
  "tiene_suscripcion": true,
  "plan_slug": "Premium",
  "status": "ACTIVA",
  "fecha_inicio": "2026-06-01T00:00:00Z",
  "fecha_fin": "2026-07-01T00:00:00Z"
}
```
- **Response 200 (sin suscripcion):**
```json
{
  "tiene_suscripcion": false,
  "plan_slug": null
}
```

---

### Módulo: Upload — Prefijo `/api/v1/upload`

#### `POST /api/v1/upload/avatar`
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`
- **Request:** `file=@avatar.jpg` (max 5 MB, JPEG/PNG/WebP, 400x400 thumb)
- **Response 200:** `{"url": "https://res.cloudinary.com/..."}`

#### `POST /api/v1/upload/servicio/{servicio_id}`
- **Headers:** `Authorization: Bearer <token>` (propietario), `Content-Type: multipart/form-data`
- **Request:** `file=@foto.jpg` (max 10 MB, max 5 fotos por servicio)
- **Response 200:** `{"url": "...", "fotos": ["...", "..."]}`

#### `DELETE /api/v1/upload/{public_id}`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:** `{"message": "Archivo eliminado"}`

---

### Módulo: Proveedores — Prefijo `/api/v1/proveedores`

#### `GET /api/v1/proveedores/top`
- **Headers:** Ninguno (publico)
- **Query:** `?limit=10` (max 50)
- **Response 200:**
```json
[
  {
    "id": "3e8a7c1b-...",
    "nombre": "Carlos Munoz",
    "avatar_url": "https://...",
    "avg_rating": 4.9,
    "bio": "Experto en plomeria...",
    "total_contratos": 12
  }
]
```

---

### Módulo: Oportunidades — Prefijo `/api/v1/oportunidades`

#### `GET /api/v1/oportunidades`
- **Headers:** Ninguno (publico)
- **Query:** `?limit=20` (max 100)
- **Response 200:**
```json
[
  {
    "contratacion_id": "d4e5f6a7-...",
    "servicio_id": "c3d4e5f6-...",
    "cliente_id": "4f9b8c2d-...",
    "cliente_nombre": "Andrea Herrera",
    "monto_acordado": 45000.0,
    "mensaje_solicitud": "Necesito arreglar una llave",
    "fecha_programada": "2026-06-20T15:00:00Z",
    "created_at": "2026-06-17T12:00:00Z"
  }
]
```

---

### Módulo: Propuestas — Prefijo `/api/v1/propuestas`

#### `POST /api/v1/solicitudes/{solicitud_id}/propuestas`
- **Headers:** `Authorization: Bearer <token>` (rol proveedor)
- **Request (body):**
```json
{
  "descripcion": "Puedo realizar el trabajo por $40,000",
  "precio": 40000.0,
  "tiempo_estimado": "2 dias"
}
```
- **Response 201:**
```json
{
  "id": "p1a2b3c4-...",
  "solicitud_id": "s1a2b3c4-...",
  "proveedor_id": "3e8a7c1b-...",
  "descripcion": "Puedo realizar el trabajo por $40,000",
  "precio": 40000.0,
  "tiempo_estimado": "2 dias",
  "status": "pendiente",
  "proveedor_nombre": "Carlos Perez",
  "solicitud_titulo": "Necesito plomero urgente",
  "created_at": "2026-06-17T12:00:00Z",
  "updated_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/solicitudes/{solicitud_id}/propuestas`
- **Headers:** `Authorization: Bearer <token>` (cliente propietario de la solicitud o admin)
- **Response 200:** `[PropuestaResponse]`

#### `PATCH /api/v1/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/aceptar`
- **Headers:** `Authorization: Bearer <token>` (cliente)
- **Effect:** Crea Contratacion, cierra Solicitud, rechaza otras propuestas
- **Response 200:** `PropuestaResponse` con `contratacion_id` extra

#### `PATCH /api/v1/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/rechazar`
- **Headers:** `Authorization: Bearer <token>` (cliente)
- **Response 200:** `{"id": "...", "solicitud_id": "...", "proveedor_id": "...", "status": "rechazada"}`

#### `GET /api/v1/propuestas/mis-propuestas`
- **Headers:** `Authorization: Bearer <token>` (proveedor)
- **Response 200:** `[PropuestaResponse]` del proveedor autenticado

---

### Módulo: Admin — Prefijo `/api/v1/admin` (todo requiere rol admin)

#### `GET /api/v1/admin/stats`
- **Response 200:**
```json
{
  "usuarios": {"total": 100, "proveedores": 40, "clientes": 60},
  "servicios_activos": 150,
  "contrataciones": {"total": 500, "este_mes": 45},
  "volumen_transaccionado_mes": 1250000.0,
  "contrataciones_por_mes": [
    {"mes": "2026-01", "total": 40},
    {"mes": "2026-02", "total": 55}
  ],
  "top_categorias": [{"nombre": "Plomeria", "total": 30}],
  "top_proveedores": [{"nombre": "Carlos Munoz", "rating": 4.9, "total_contratos": 12}]
}
```

#### `GET /api/v1/admin/usuarios`
- **Query:** `?skip=0&limit=50&rol=proveedor&email=algo`
- **Response 200:**
```json
{
  "total": 100,
  "skip": 0,
  "limit": 50,
  "data": [{"id": "...", "email": "...", ...}]
}
```

#### `POST /api/v1/admin/usuarios`
- **Request:**
```json
{
  "email": "nuevo@ejemplo.cl",
  "password": "Pass123",
  "nombre": "Nuevo",
  "apellido": "Usuario",
  "rol": "cliente",
  "telefono": "+569..."
}
```
- **Response 201:** Usuario creado con `is_verified: true`

#### `PATCH /api/v1/admin/usuarios/{id}/toggle-active`
- **Response 200:** `{"id": "...", "is_active": false}`

#### `PUT /api/v1/admin/usuarios/{id}`
- **Request:** Campos opcionales: `email`, `nombre`, `apellido`, `telefono`, `rol`, `is_active`
- **Response 200:** Usuario actualizado

#### `GET /api/v1/admin/servicios`
- **Query:** `?skip=0&limit=50&status=activo`
- **Response:** `{"total": N, "data": [ServicioResponse enriched]}`

#### `GET /api/v1/admin/pagos`
- **Query:** `?skip=0&limit=50&status=aprobado`
- **Response:**
```json
{
  "total": 50,
  "volumen_total_aprobado": 2500000.0,
  "data": [
    {
      "id": "...",
      "contratacion_id": "...",
      "monto": 25000.0,
      "fee_plataforma": 2500.0,
      "monto_neto": 22500.0,
      "gateway": "mercadopago",
      "status": "aprobado",
      "created_at": "2026-06-17T12:00:00Z"
    }
  ]
}
```

---

### Módulo: Disputas — Prefijo `/api/v1/disputas`

#### `POST /api/v1/disputas/contratacion/{contratacion_id}`
- **Headers:** `Authorization: Bearer <token>` (participante)
- **Request (body):**
```json
{
  "motivo": "El proveedor no completo el trabajo",
  "evidencias": ["https://foto.com/prueba1.jpg"]
}
```
- **Response 201:**
```json
{
  "id": "...",
  "contratacion_id": "...",
  "abridor_id": "...",
  "motivo": "El proveedor no completo el trabajo",
  "evidencias": ["https://foto.com/prueba1.jpg"],
  "status": "ABIERTA",
  "resolucion": null,
  "created_at": "2026-06-17T12:00:00Z"
}
```

#### `GET /api/v1/disputas/admin` (admin)
- **Query:** `?status=abierta`
- **Response:** `{"total": N, "data": [DisputaResponse]}`

#### `PATCH /api/v1/disputas/admin/{disputa_id}/resolver` (admin)
- **Query:** `?accion=liberar` (o `reembolsar`)
- **Request (body):** `{"resolucion": "El proveedor cumplio, se libera el pago"}`
- **Response 200:** `{"id": "...", "estado": "resuelta", "accion": "liberar"}`

---

### Módulo: Bugs — Prefijo `/api/v1/bugs`

#### `POST /api/v1/bugs`
- **Headers:** `Authorization: Bearer <token>`
- **Request:**
```json
{
  "titulo": "Error al cargar servicios",
  "descripcion": "No se muestran los servicios cercanos",
  "area": "funcion"
}
```
- **Response 201:**
```json
{
  "id": "...",
  "usuario_id": "...",
  "titulo": "Error al cargar servicios",
  "descripcion": "No se muestran los servicios cercanos",
  "area": "funcion",
  "status": "abierto",
  "created_at": "2026-06-17T12:00:00Z",
  "resolved_at": null
}
```

#### `GET /api/v1/bugs/mis-reportes`
- **Headers:** `Authorization: Bearer <token>`
- **Response 200:** `[BugReportResponse]`

#### `GET /api/v1/admin/bugs` (admin)
- **Query:** `?status=abierto`
- **Response:** `{"total": N, "data": [BugReportResponse]}`

#### `PATCH /api/v1/admin/bugs/{bug_id}?status=en_proceso` (admin)
- **Response 200:** `{"id": "...", "status": "en_proceso"}`

---

## 3. Tabla Resumen de Endpoints

| Modulo | Endpoint | Metodo | Request Payload (Resumen) | Requiere Auth |
|--------|----------|--------|---------------------------|--------------|
| **Health** | `/health` | GET | — | No |
| **Auth** | `/api/v1/auth/register` | POST | `{email, password, nombre, apellido, telefono?, rol?}` + `?ref=` | No |
| | `/api/v1/auth/login` | POST | `{email, password}` | No |
| | `/api/v1/auth/me` | GET | — | Si (cualquier rol) |
| | `/api/v1/auth/verify-email` | GET | `?token=` | No |
| | `/api/v1/auth/forgot-password` | POST | `{email}` | No |
| | `/api/v1/auth/reset-password` | POST | `{token, new_password}` | No |
| **Usuarios** | `/api/v1/usuarios/{id}` | GET | — | No |
| | `/api/v1/usuarios/me` | PUT | `{nombre?, apellido?, telefono?, bio?, habilidades?, avatar_url?}` | Si |
| | `/api/v1/usuarios/me/ubicacion` | PATCH | `{lat, lng}` | Si |
| | `/api/v1/usuarios/me/referidos` | GET | — | Si |
| **Categorias** | `/api/v1/categorias` | GET | — | No |
| | `/api/v1/categorias/{slug}` | GET | — | No |
| **Servicios** | `/api/v1/servicios` | POST | `{categoria_id, titulo, descripcion, precio_min?, precio_max?, radio_cobertura_km?, direccion_texto?, fotos?}` | Si (proveedor/admin) |
| | `/api/v1/servicios` | GET | `?categoria_id=&proveedor_id=&skip=&limit=` | No |
| | `/api/v1/servicios/buscar` | GET | `?lat=&lng=&radio_km=&categoria_id=&skip=&limit=` | No |
| | `/api/v1/servicios/{id}` | GET | — | No |
| | `/api/v1/servicios/{id}` | PUT | `{categoria_id?, titulo?, descripcion?, ...}` | Si (propietario) |
| | `/api/v1/servicios/{id}/destacar` | POST | — | Si (propietario) |
| | `/api/v1/servicios/{id}/pausar` | PATCH | — | Si (propietario) |
| | `/api/v1/servicios/{id}` | DELETE | — | Si (propietario) |
| **Contrataciones** | `/api/v1/contrataciones` | POST | `{servicio_id, monto_acordado?, mensaje_solicitud?, fecha_programada?}` | Si (cliente) |
| | `/api/v1/contrataciones` | GET | — | Si |
| | `/api/v1/contrataciones/{id}` | GET | — | Si (participante) |
| | `/api/v1/contrataciones/{id}/aceptar` | PATCH | — | Si (proveedor) |
| | `/api/v1/contrataciones/{id}/rechazar` | PATCH | — | Si (proveedor) |
| | `/api/v1/contrataciones/{id}/finalizar` | PATCH | — | Si (participante) |
| | `/api/v1/contrataciones/{id}/resena` | POST | `{puntuacion, comentario?}` | Si (participante) |
| | `/api/v1/contrataciones/usuario/{id}/resenas` | GET | — | No |
| **Resenas** | `/api/v1/resenas/{contratacion_id}` | POST | `{puntuacion, comentario?}` | Si (solo cliente) |
| | `/api/v1/resenas/usuario/{id}` | GET | — | No |
| **Chat** | `/api/v1/chat/ws/{contratacion_id}` | WS | `?token=` — mensajes: `{"contenido": "..."}` | Si (via query param) |
| | `/api/v1/chat/{id}/mensajes` | POST | `{contenido}` | Si (participante) |
| | `/api/v1/chat/{id}/mensajes` | GET | `?skip=&limit=` | Si (participante) |
| | `/api/v1/chat/conversaciones` | GET | — | Si |
| **Pagos** | `/api/v1/pagos/crear` | POST | `?contratacion_id=` | Si (cliente) |
| | `/api/v1/pagos/webhooks/pagos` | POST | Body raw de MP | No |
| | `/api/v1/pagos/{contratacion_id}/estado` | GET | — | Si (participante) |
| **Suscripciones** | `/api/v1/suscripciones/crear` | POST | `{plan_slug}` | Si (proveedor) |
| | `/api/v1/suscripciones/me` | GET | — | Si (proveedor) |
| **Upload** | `/api/v1/upload/avatar` | POST | `file=@avatar.jpg` (multipart) | Si |
| | `/api/v1/upload/servicio/{id}` | POST | `file=@foto.jpg` (multipart) | Si (propietario) |
| | `/api/v1/upload/{public_id}` | DELETE | — | Si |
| **Proveedores** | `/api/v1/proveedores/top` | GET | `?limit=` | No |
| **Oportunidades** | `/api/v1/oportunidades` | GET | `?limit=` | No |
| **Propuestas** | `/api/v1/solicitudes/{sol_id}/propuestas` | POST | `{descripcion, precio, tiempo_estimado?}` | Si (proveedor) |
| | `/api/v1/solicitudes/{sol_id}/propuestas` | GET | — | Si (cliente/admin) |
| | `/api/v1/solicitudes/{sol_id}/propuestas/{prop_id}/aceptar` | PATCH | — | Si (cliente) |
| | `/api/v1/solicitudes/{sol_id}/propuestas/{prop_id}/rechazar` | PATCH | — | Si (cliente) |
| | `/api/v1/propuestas/mis-propuestas` | GET | — | Si (proveedor) |
| **Admin** | `/api/v1/admin/stats` | GET | — | Si (admin) |
| | `/api/v1/admin/usuarios` | GET | `?skip=&limit=&rol=&email=` | Si (admin) |
| | `/api/v1/admin/usuarios` | POST | `{email, password, nombre, apellido, rol?, telefono?}` | Si (admin) |
| | `/api/v1/admin/usuarios/{id}/toggle-active` | PATCH | — | Si (admin) |
| | `/api/v1/admin/usuarios/{id}` | PUT | `{email?, nombre?, ..., is_active?}` | Si (admin) |
| | `/api/v1/admin/servicios` | GET | `?skip=&limit=&status=` | Si (admin) |
| | `/api/v1/admin/pagos` | GET | `?skip=&limit=&status=` | Si (admin) |
| **Disputas** | `/api/v1/disputas/contratacion/{id}` | POST | `{motivo, evidencias?}` | Si (participante) |
| | `/api/v1/disputas/admin` | GET | `?status=` | Si (admin) |
| | `/api/v1/disputas/admin/{id}/resolver` | PATCH | `{resolucion}` + `?accion=liberar|reembolsar` | Si (admin) |
| **Bugs** | `/api/v1/bugs` | POST | `{titulo, descripcion, area?}` | Si |
| | `/api/v1/bugs/mis-reportes` | GET | — | Si |
| | `/api/v1/admin/bugs` | GET | `?status=` | Si (admin) |
| | `/api/v1/admin/bugs/{bug_id}` | PATCH | `?status=` | Si (admin) |

---

## 4. Mejoras Criticas Requeridas en el Frontend (Flutter)

### 4.1 Manejo del Token y Headers

El backend espera **exclusivamente** `Authorization: Bearer <token>` en el header HTTP.

**Interceptor obligatorio en ApiClient:**
```dart
class ApiClient {
  String? _token;

  Future<void> init() async {
    _token = await storage.read('access_token');
  }

  void setToken(String token) {
    _token = token;
    storage.write('access_token', token);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    _handleAuthErrors(response.statusCode);
    return response;
  }

  void _handleAuthErrors(int status) {
    if (status == 401) {
      _token = null;
      storage.delete('access_token');
    }
  }
}
```

**Errores a corregir en el frontend actual:**
1. `ApiClient.init()` nunca es llamado — el token se carga via getter en lugar de inicializacion explicita.
2. La mayoria de screens capturan `Exception` generica, tragando `AuthException`. Deben relanzar o no capturar `AuthException`.
3. `onUnauthorized` global esta configurado pero no se ejecuta porque las excepciones se capturan antes.

### 4.2 Tipado Estricto y Null Safety

Basado en los esquemas Pydantic, estos campos **siempre pueden ser `null`** y deben declararse con `?` en Dart:

| Campo | Tipo en Dart | Contexto |
|-------|-------------|----------|
| `telefono` | `String?` | Usuario, RegistroRequest |
| `avatar_url` | `String?` | Usuario, ProveedorResumen |
| `bio` | `String?` | Usuario |
| `habilidades` | `String?` (texto plano o JSON string) | Usuario |
| `codigo_referido` | `String?` | UsuarioResponse |
| `updated_at` | `DateTime?` | UsuarioResponse |
| `precio_min` | `double?` | Servicio |
| `precio_max` | `double?` | Servicio |
| `direccion_texto` | `String?` | Servicio |
| `distancia` | `double?` | ServicioResponse (busqueda) |
| `proveedor_nombre` | `String?` | ServicioResponse (enriched) |
| `proveedor_rating` | `double?` | ServicioResponse (enriched) |
| `categoria_nombre` | `String?` | ServicioResponse (enriched) |
| `servicio_id` | `String?` | Contratacion |
| `propuesta_id` | `String?` | Contratacion |
| `monto_acordado` | `double?` | Contratacion |
| `mensaje_solicitud` | `String?` | Contratacion |
| `fecha_programada` | `DateTime?` | Contratacion |
| `cliente_nombre` | `String?` | Contratacion enriched |
| `servicio_titulo` | `String?` | Contratacion enriched |
| `comentario` | `String?` | Resena |
| `preference_id` | `String?` | Pago |
| `plan_slug` | `String?` | Suscripcion |
| `descripcion` | `String?` | Plan, Categoria |
| `icono` | `String?` | Categoria |
| `beneficios` | `List<String>?` | Plan |
| `evidencias` | `List<String>?` | Disputa |
| `resolucion` | `String?` | Disputa |
| `fecha_fin` / `fecha_vencimiento` | `DateTime?` | Suscripcion |
| `resolved_at` | `DateTime?` | Disputa, BugReport |

**Regla de oro:** Todo campo cuyo tipo Pydantic sea `type | None` DEBE ser `Type?` en Dart.

### 4.3 Manejo de Errores (422 Unprocessable Entity)

FastAPI usa un **exception handler global** en `main.py` que transforma errores a un formato uniforme:

```json
// Error 422 de validacion (RequestValidationError):
{"detail": "categoria_id: Value error, El precio no puede ser negativo"}

// Error 4xx generico (HTTPException lanzada desde ruta):
{"detail": "El email ya esta registrado"}

// Error 500:
{"detail": "Error interno del servidor"}
```

**En Flutter:**
```dart
class ApiException implements Exception {
  final int statusCode;
  final String detail;

  ApiException(this.statusCode, this.detail);

  @override
  String toString() => '[$statusCode] $detail';
}

void _handleResponse(http.Response response) {
  if (response.statusCode >= 400) {
    final body = jsonDecode(response.body);
    final detail = body['detail'] ?? 'Error desconocido';
    throw ApiException(response.statusCode, detail as String);
  }
}
```

**Errores especificos a mapear:**
| Codigo | Causa | Accion en Flutter |
|--------|-------|------------------|
| 400 | Validacion de negocio (rol invalido, monto invalido, estado no valido) | Mostrar `detail` en un snackbar |
| 401 | Token invalido/expirado | Limpiar token, redirigir a `/login` |
| 403 | Rol insuficiente | Mostrar "No tienes permisos" |
| 404 | Recurso no encontrado | Mostrar `detail` |
| 409 | Conflicto (email duplicado, resena ya existe) | Mostrar `detail` |
| 422 | Error de validacion Pydantic (formato de datos incorrecto) | Mostrar `detail` con el campo especifico |
| 429 | Rate limit excedido (100 req/min) | Esperar y reintentar |
| 500 | Error interno del servidor | Mostrar mensaje generico |

### 4.4 WebSockets — Requisitos de Conexion

**Conexion:**
```dart
final wsUrl = Uri.parse('wss://api.trabajoya.cl/api/v1/chat/ws/$contratacionId')
    .replace(queryParameters: {'token': token});
final channel = WebSocketChannel.connect(wsUrl);
```

**Autenticacion:** El servidor valida el token en el query param. Si es invalido, cierra con:
- `4001`: Token invalido
- `4003`: No eres participante
- `4004`: Contratacion no encontrada

**Manejo de reconexion:**
```dart
class ChatWebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int MAX_RETRIES = 10;

  void connect(String contratacionId, String token) {
    _channel?.sink.close();
    final uri = Uri.parse('$wsBase/chat/ws/$contratacionId')
        .replace(queryParameters: {'token': token});
    _channel = WebSocketChannel.connect(uri);
    _reconnectAttempts = 0;

    _channel!.stream.listen(
      (message) => _onMessage(jsonDecode(message)),
      onError: (error) => _scheduleReconnect(contratacionId, token),
      onDone: () => _scheduleReconnect(contratacionId, token),
    );
  }

  void _scheduleReconnect(String contratacionId, String token) {
    if (_reconnectAttempts >= MAX_RETRIES) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: min(pow(2, _reconnectAttempts).toInt(), 30));
    _reconnectTimer = Timer(delay, () => connect(contratacionId, token));
  }

  void send(String contenido) {
    _channel?.sink.add(jsonEncode({'contenido': contenido}));
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
  }
}
```

**Nota importante:** El `ConnectionManager` del backend mantiene conexiones en memoria. Si el servidor se reinicia o el usuario se desconecta, **los mensajes enviados durante la desconexion no se reenvian**. El frontend debe:
1. Usar REST (`POST /chat/{id}/mensajes`) como fallback si WebSocket falla.
2. Sincronizar mensajes perdidos via `GET /chat/{id}/mensajes` al reconectar.

### 4.5 Fechas y Geo-datos

**Parseo de fechas ISO 8601:**
```dart
DateTime _parseDate(String iso) => DateTime.parse(iso);

class Contratacion {
  final DateTime? fechaProgramada;
  final DateTime createdAt;

  Contratacion.fromJson(Map<String, dynamic> json)
    : fechaProgramada = json['fecha_programada'] != null
        ? DateTime.parse(json['fecha_programada'] as String)
        : null,
      createdAt = DateTime.parse(json['created_at'] as String);
}
```

**Envio de fechas al backend:**
```dart
body: jsonEncode({
  'servicio_id': servicioId,
  'fecha_programada': fechaProgramada?.toUtc().toIso8601String(),
});
```

**Busqueda geoespacial (`GET /servicios/buscar`):**
```dart
Future<List<Servicio>> buscarServicios({
  required double lat,
  required double lng,
  double radioKm = 10,
  String? categoriaId,
}) async {
  final query = {
    'lat': lat.toString(),
    'lng': lng.toString(),
    'radio_km': radioKm.toString(),
    if (categoriaId != null) 'categoria_id': categoriaId,
  };
  final response = await api.get('/servicios/buscar', query: query);
  return (jsonDecode(response.body) as List)
      .map((j) => Servicio.fromJson(j))
      .toList();
}
```

---

## 5. Credenciales Mock (Frontend — mockMode = true)

Cuando `mockMode = true` en `lib/core/constants.dart`, el `MockApi` en `mock_data.dart` intercepta todas las llamadas. El login **no valida contrasena**, solo matchea por email:

| Email contiene | Usuario mock que se asigna | Rol |
|---------------|---------------------------|-----|
| `admin` | `admin@trabajoya.cl` | admin |
| `carlos` o `proveedor` | `carlos@correo.com` | proveedor |
| `ana` | `ana@correo.com` | proveedor |
| cualquier otro | `maria@correo.com` | cliente |

**Usuarios mock completos para debugging:**

| Campo | Maria (cliente) | Carlos (proveedor) | Ana (proveedor 2) | Admin |
|-------|----------------|-------------------|-------------------|-------|
| Email | `maria@correo.com` | `carlos@correo.com` | `ana@correo.com` | `admin@trabajoya.cl` |
| ID | `mock-cliente-1` | `mock-proveedor-1` | `mock-proveedor-2` | `mock-admin-1` |
| Rol | cliente | proveedor | proveedor | admin |
| Bio | "Busco servicios de calidad para mi hogar" | "Gasfiter profesional" | "Electricista certificada SEC" | null |
| Rating | 4.5 | 4.8 | 4.2 | 0.0 |
| Codigo referido | `MARIA01` | `CARLOS01` | `ANA001` | null |
| Referidos | 2 | 5 | 1 | 0 |

**Credenciales reales (PostgreSQL — seed data):**

| Rol | Email | Contrasena |
|-----|-------|-----------|
| Admin | `admin@trabajoya.cl` | `admin123` |
| Cliente | `cliente1@trabajoya.cl` | `password123` |
| Proveedor | `proveedor1@trabajoya.cl` | `password123` |
