# Referencia de API — TrabajoYa (contrato para el frontend)

> Documento de integración generado leyendo el **código actual** de `trabajoya-api`
> (verificado contra los archivos, no de memoria). Refleja el backend **ya endurecido**:
> JWT de 60 min, CORS restringido, rate-limit en login, ownership en uploads y webhook de
> pagos con validación de firma.
>
> Cada endpoint indica: **método + ruta completa**, **auth/rol**, **params**, **body** y
> **respuesta**. El formato de error es **siempre** `{"detail": "mensaje"}`.

---

## 1. Fundamentos

| Dato | Valor |
|---|---|
| Base URL (local) | `http://localhost:8000` |
| Prefijo de API | `/api/v1` ([config.py:8](app/core/config.py#L8)) |
| Health check | `GET /health` → `{"status": "ok"}` (sin prefijo) |
| Auth | JWT Bearer en header `Authorization: Bearer <token>` |
| Formato de fechas | ISO 8601 con timezone |
| IDs | UUID v4 |

**Cómo correr el backend:**
```bash
# Docker (recomendado) — levanta API + PostgreSQL/PostGIS + Redis
docker-compose up

# o directo con uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

> El backend **no arranca** si faltan `DATABASE_URL` o `JWT_SECRET_KEY` en `.env`
> (no tienen default), ni si `CORS_ORIGINS=["*"]` (abortado en el lifespan,
> [main.py:40-47](app/main.py#L40-L47)). El front de dev debe servirse desde
> `http://localhost:3000` o agregar su origen a `CORS_ORIGINS`.

---

## 2. Autenticación

### Flujo
1. `POST /api/v1/auth/register` o `POST /api/v1/auth/login` → obtenés `access_token`.
2. Mandás el token en **todas** las llamadas protegidas: `Authorization: Bearer <token>`.
3. El token **expira a los 60 minutos** ([config.py:16](app/core/config.py#L16)). **No hay
   refresh token**: cuando recibas `401`, redirigí a login.

### `POST /api/v1/auth/register` — Registro
Auth: No. Status: `201`. Query opcional: `ref` (código de referido).
```jsonc
// Body (RegistroRequest)
{
  "email": "ana@example.com",   // requerido
  "password": "secreta123",      // requerido
  "nombre": "Ana",               // requerido
  "apellido": "Pérez",           // requerido
  "telefono": "+56912345678",    // opcional
  "rol": "cliente",              // "cliente" | "proveedor" (default "cliente")
  "codigo_referido": null         // opcional
}
```
```jsonc
// 201 (RegistroResponse) — incluye token + user
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": {
    "id": "uuid", "email": "ana@example.com", "nombre": "Ana", "apellido": "Pérez",
    "telefono": "+56912345678", "rol": "cliente", "avatar_url": null, "bio": null,
    "habilidades": null, "is_active": true, "is_verified": false, "avg_rating": 0.0,
    "referidos_count": 0, "codigo_referido": "AB12CD34", "email_verificado": false,
    "created_at": "2026-06-18T10:30:00+00:00", "updated_at": null
  }
}
```
Errores: `409` "El email ya está registrado" · `400` "Rol inválido. Debe ser 'cliente' o 'proveedor'".
> Tras registrarse se envía un email de verificación. El usuario queda `is_verified=false`
> pero **ya recibe token** y puede operar.

### `POST /api/v1/auth/login` — Login
Auth: No. **Rate limit: 5/minuto por IP** ([routes_auth.py:85](app/api/routes_auth.py#L85)).
```jsonc
// Body (LoginRequest)
{ "email": "ana@example.com", "password": "secreta123" }
```
```jsonc
// 200 (Token)
{ "access_token": "eyJhbGc...", "token_type": "bearer" }
```
Errores: `400` "Email o contraseña incorrectos" · `403` "Cuenta desactivada".

### `GET /api/v1/auth/me` — Usuario autenticado
Auth: Sí. Devuelve `UsuarioResponse` (mismo objeto `user` de arriba).
Errores: `401` "Token inválido" / "Token inválido o expirado" / "Usuario no encontrado o inactivo".

### Otros de auth
| Método | Ruta | Body | Respuesta |
|---|---|---|---|
| GET | `/api/v1/auth/verify-email?token=...` | — | `{"message": "Email verificado exitosamente"}` |
| POST | `/api/v1/auth/forgot-password` | `{"email"}` | `{"message": "Si el email existe, recibirás un link..."}` (siempre 200) |
| POST | `/api/v1/auth/reset-password` | `{"token","new_password"}` | `{"message": "Contraseña actualizada exitosamente"}` |

---

## 3. Convenciones globales

- **Errores:** siempre `{"detail": "..."}`. Validación (`422`) también, con el campo:
  `{"detail": "body -> email: value is not a valid email address"}`
  ([main.py:71-77](app/main.py#L71-L77)).
- **Rate limiting:** 100/min por IP global; 5/min en login. Al exceder → `429`.
- **Paginación:** query `skip` (default 0) y `limit` (default 20, máx 100). Los listados
  nuevos devuelven `{"total", "limit", "offset", "data": [...]}`; algunos listados simples
  devuelven un array directo (se indica por endpoint).
- **Status:** los valores de estado se devuelven en **MAYÚSCULA** (`ACTIVO`, `ACEPTADO`…),
  salvo `rol` que va en minúscula (`cliente`/`proveedor`/`admin`).

### Enums
```python
RolUsuario        = cliente | proveedor | admin          # minúscula
EstadoServicio    = ACTIVO | PAUSADO | ELIMINADO
StatusSolicitud   = ABIERTA | CERRADA
StatusPropuesta   = PENDIENTE | ACEPTADA | RECHAZADA | CANCELADA
EstadoContratacion= PENDIENTE | ACEPTADO | RECHAZADO | COMPLETADO | CANCELADO | DISPUTA
EstadoPago        = PENDIENTE | APROBADO | RECHAZADO | CANCELADO
EstadoDisputa     = ABIERTA | RESUELTA
```

---

## 4. Endpoints por recurso

### 4.1 Usuarios — `/api/v1/usuarios`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| GET | `/usuarios/{usuario_id}` | No | Perfil público. `404` si no existe/inactivo |
| PUT | `/usuarios/me` | Sí | Body `UsuarioUpdate` (todos opcionales: nombre, apellido, telefono, bio, habilidades, avatar_url) → `UsuarioResponse` |
| PATCH | `/usuarios/me/ubicacion` | Sí | Body `{"lat": -90..90, "lng": -180..180}` → `{"message":"Ubicación actualizada"}` |
| GET | `/usuarios/me/referidos` | Sí | `{"mi_codigo", "total_referidos", "referidos": [...]}` |

### 4.2 Categorías — `/api/v1/categorias`
| Método | Ruta | Auth | Respuesta |
|---|---|---|---|
| GET | `/categorias` | No | `[{id, nombre, slug, icono, descripcion}]` |
| GET | `/categorias/{slug}` | No | `CategoriaResponse` · `404` si no existe |

### 4.3 Servicios — `/api/v1/servicios`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/servicios` | Proveedor | Body `ServicioCreate` → `201` |
| GET | `/servicios` | No | Query: `categoria_id?`, `proveedor_id?`, `skip`, `limit`. Array de servicios enriquecidos |
| GET | `/servicios/buscar` | No | Query: `lat*`, `lng*`, `radio_km=10`, `categoria_id?`, `skip`, `limit`. Búsqueda geo PostGIS, incluye `distancia` |
| GET | `/servicios/{id}` | No | Servicio enriquecido · `404` |
| PUT | `/servicios/{id}` | Proveedor dueño | Body `ServicioUpdate` → `ServicioResponse` · `403` si ajeno |
| POST | `/servicios/{id}/destacar` | Proveedor dueño | Toggle → `{"es_destacado": bool}` |
| PATCH | `/servicios/{id}/pausar` | Proveedor dueño | Toggle → `{"status": "PAUSADO"|"ACTIVO"}` |
| DELETE | `/servicios/{id}` | Proveedor dueño | Soft-delete → `204` |

```jsonc
// ServicioCreate
{
  "categoria_id": "uuid",          // requerido
  "titulo": "Reparación de cañerías", // requerido
  "descripcion": "...",            // requerido
  "precio_min": 50.0,              // opcional, >= 0
  "precio_max": 200.0,             // opcional, >= 0
  "radio_cobertura_km": 10,        // default 10, > 0
  "direccion_texto": "Santiago",   // opcional
  "fotos": ["url1"]                // opcional
}
```
```jsonc
// Servicio enriquecido (respuesta)
{
  "id":"uuid","proveedor_id":"uuid","proveedor_nombre":"Juan P.","proveedor_rating":4.8,
  "categoria_id":"uuid","categoria_nombre":"Gasfitería","titulo":"...","descripcion":"...",
  "precio_min":50.0,"precio_max":200.0,"radio_cobertura_km":10,"direccion_texto":"Santiago",
  "fotos":["url1"],"es_destacado":false,"status":"ACTIVO","distancia":1.2,
  "created_at":"...","updated_at":"..."
}
```

### 4.4 Solicitudes — `/api/v1/solicitudes`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/solicitudes` | Cliente | Body `SolicitudCreate` → `201` (objeto solicitud) |
| GET | `/solicitudes` | No | Query `categoria_id?`, `skip`, `limit` → `{total, limit, offset, data}` |
| GET | `/solicitudes/mis-solicitudes` | Sí | Array de las propias (abiertas y cerradas) |
| GET | `/solicitudes/{id}` | No | `SolicitudResponse` · `404` |
| PATCH | `/solicitudes/{id}/cerrar` | Cliente dueño | → `{"status":"CERRADA"}` |

```jsonc
// SolicitudCreate
{ "titulo":"...", "descripcion":"...", "categoria_id": null, "presupuesto_max": 300.0, "ubicacion_texto":"Providencia" }
```

### 4.5 Propuestas — `/api/v1/...`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/solicitudes/{solicitud_id}/propuestas` | Proveedor | Body `{descripcion, precio, tiempo_estimado}` → `201`. `409` si ya propuso |
| GET | `/solicitudes/{solicitud_id}/propuestas` | Cliente dueño | Array `PropuestaResponse` |
| PATCH | `/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/aceptar` | Cliente dueño | **Crea contratación** (status ACEPTADO), cierra solicitud, rechaza el resto. Devuelve propuesta + `contratacion_id` |
| PATCH | `/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/rechazar` | Cliente dueño | → propuesta con `status:"RECHAZADA"` |
| GET | `/propuestas/mis-propuestas` | Proveedor | Array de las propias |

### 4.6 Contrataciones — `/api/v1/contrataciones`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/contrataciones` | Cliente | Body `ContratacionCreate` → `201`. `400` si es tu propio servicio |
| GET | `/contrataciones` | Sí | Query `skip`, `limit` → `{total, limit, offset, data}` (las del usuario, como cliente o proveedor) |
| GET | `/contrataciones/{id}` | Participante | Objeto enriquecido (cliente_nombre, proveedor_nombre, servicio_titulo) |
| PATCH | `/contrataciones/{id}/aceptar` | Proveedor | → `{"status":"ACEPTADO"}` |
| PATCH | `/contrataciones/{id}/rechazar` | Proveedor | → `{"status":"RECHAZADO"}` |
| PATCH | `/contrataciones/{id}/finalizar` | Participante | → `{"status":"COMPLETADO"}`. Si es contratación directa (con `servicio_id`) **exige pago aprobado** |
| POST | `/contrataciones/{id}/resena` | Participante | Body `{puntuacion:1..5, comentario?}` → `201`. Requiere status COMPLETADO. `409` si ya reseñada |
| GET | `/contrataciones/usuario/{usuario_id}/resenas` | No | Array de reseñas recibidas |

```jsonc
// ContratacionCreate
{ "servicio_id":"uuid", "monto_acordado": 50000.0, "mensaje_solicitud":"...", "fecha_programada":"2026-06-25T14:00:00" }
```

### 4.7 Reseñas — `/api/v1/resenas`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/resenas/{contratacion_id}` | Cliente | Body `{puntuacion:1..5, comentario?}` → `201` (equivalente a `/contrataciones/{id}/resena`) |
| GET | `/resenas/usuario/{usuario_id}` | No | Array de reseñas del usuario |

### 4.8 Disputas — `/api/v1/disputas`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/disputas/contratacion/{contratacion_id}` | Participante | Body `{motivo, evidencias?}` → `201`. `409` si ya hay disputa |
| GET | `/disputas/admin` | Admin | Query `status?` → `{total, data}` |
| PATCH | `/disputas/admin/{disputa_id}/resolver` | Admin | Query `accion="reembolsar"|"liberar"`, body `{resolucion}` → `{id, estado:"RESUELTA", accion}` |

### 4.9 Pagos — `/api/v1/pagos`  (ver §6 para el flujo completo)
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/pagos/crear` | Cliente | Query `contratacion_id`. Devuelve preferencia MercadoPago con `init_point` |
| POST | `/pagos/webhooks/pagos` | No (HMAC) | Webhook de MercadoPago. **El front no lo llama** |
| GET | `/pagos/{contratacion_id}/estado` | Participante | `{status, monto, fee_plataforma(10%), monto_neto}` |

### 4.10 Suscripciones — `/api/v1/suscripciones`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/suscripciones/crear` | Proveedor | Body `{plan_slug}` → preferencia MercadoPago |
| GET | `/suscripciones/me` | Proveedor | `{tiene_suscripcion, plan_slug, status, fecha_inicio, fecha_fin}` |

### 4.11 Upload — `/api/v1/upload`  (multipart/form-data, campo `file`)
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/upload/avatar` | Sí | JPEG/PNG/WebP, máx **5 MB** → `{"url"}` (actualiza tu avatar) |
| POST | `/upload/servicio/{servicio_id}` | Proveedor dueño | máx **10 MB**, **máx 5 fotos** → `{"url", "fotos":[...]}` |
| DELETE | `/upload/{public_id}` | Dueño | Valida ownership real → `{"message":"Archivo eliminado"}` |

### 4.12 Proveedores / Oportunidades (públicos)
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| GET | `/proveedores/top` | No | Query `limit=10` (1-50). Top por rating (activos, rating>0) |
| GET | `/oportunidades` | No | Query `limit=20` (1-100). Contrataciones PENDIENTES (para proveedores) |

### 4.13 Bugs — `/api/v1/bugs`
| Método | Ruta | Auth | Notas |
|---|---|---|---|
| POST | `/bugs` | Sí | Body `{titulo, descripcion, area}` → `201` |
| GET | `/bugs/mis-reportes` | Sí | Array de los propios |
| GET | `/admin/bugs` | Admin | Query `status?` → `{total, data}` |
| PATCH | `/admin/bugs/{bug_id}` | Admin | Query `status` → `{id, status}` |

### 4.14 Admin — `/api/v1/admin` (todos requieren rol `admin`)
| Método | Ruta | Notas |
|---|---|---|
| GET | `/admin/stats` | Dashboard: usuarios, servicios_activos, contrataciones, volumen, top categorías/proveedores |
| GET | `/admin/usuarios` | Query `skip`, `limit`(1-200), `rol?`, `email?` → `{total, skip, limit, data}` |
| POST | `/admin/usuarios` | Crea usuario (`is_verified=true`) → `201` |
| PUT | `/admin/usuarios/{id}` | Edita usuario |
| PATCH | `/admin/usuarios/{id}/toggle-active` | → `{id, is_active}` |
| GET | `/admin/servicios` | Query `skip`, `limit`, `status?` → `{total, data}` |
| GET | `/admin/pagos` | Query `skip`, `limit`, `status?` → `{total, volumen_total_aprobado, data}` |

---

## 5. Chat por WebSocket

**Conexión:** `ws://localhost:8000/api/v1/chat/ws/{contratacion_id}?token=<JWT>`
(el token va como **query param**, no como header).

```javascript
const ws = new WebSocket(
  `ws://localhost:8000/api/v1/chat/ws/${contratacionId}?token=${accessToken}`
);

// Enviar
ws.send(JSON.stringify({ contenido: "Hola, ¿cuándo puedes venir?" }));

// Recibir (mismo formato para echo al emisor y push al receptor)
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  // { id, contratacion_id, emisor_id, contenido, leido, created_at }
};

// Cierres con código:
ws.onclose = (e) => {
  // 4001 = token inválido | 4003 = no autorizado | 4004 = contratación no encontrada
};
```

**Fallback / historial (REST):**
| Método | Ruta | Notas |
|---|---|---|
| POST | `/api/v1/chat/{contratacion_id}/mensajes` | Body `{contenido}` → `201` `MensajeResponse` |
| GET | `/api/v1/chat/{contratacion_id}/mensajes` | Query `skip`, `limit`(1-200, def 50). Orden DESC |
| GET | `/api/v1/chat/conversaciones` | Query `skip`, `limit` → `{total, limit, offset, data}` (estilo WhatsApp: `otro_usuario_nombre`, `ultimo_mensaje`, `mensajes_no_leidos`, `status_contratacion`) |

> Para el badge de no leídos del front, usá `mensajes_no_leidos` de
> `/chat/conversaciones`.

---

## 6. Flujo de pago (MercadoPago)

1. La contratación debe estar en estado **ACEPTADO**.
2. `POST /api/v1/pagos/crear?contratacion_id=<id>` → devuelve la preferencia:
   ```jsonc
   { "id":"pref_id", "init_point":"https://www.mercadopago.cl/checkout/...",
     "sandbox_init_point":"https://...", "preference_id":"pref_id",
     "external_reference":"<contratacion_id>", "status":"pending" }
   ```
3. El front abre `init_point` (checkout de MercadoPago). Moneda: **CLP**.
4. MercadoPago llama al webhook del backend (con firma HMAC). Al aprobarse, el backend crea
   el `Pago` (APROBADO) y marca la contratación como COMPLETADO.
5. El front consulta `GET /api/v1/pagos/{contratacion_id}/estado`:
   ```jsonc
   { "status":"APROBADO", "monto":50000.0, "fee_plataforma":5000.0, "monto_neto":45000.0 }
   ```
   La comisión de plataforma es **10%**.

> Nota de backend (no afecta al front): hay un posible desajuste entre la `notification_url`
> que arma `payment_service` y la ruta real del webhook `/pagos/webhooks/pagos`. Conviene
> alinearlos antes de probar pagos reales.

---

## 7. Notas para el frontend Flutter

- **Cliente HTTP:** centralizá `baseUrl = http://localhost:8000/api/v1` (o `BACKEND_URL`)
  y un interceptor que agregue `Authorization: Bearer <token>`.
- **Manejo de 401:** el token vive 60 min y **no hay refresh**. Ante cualquier `401`, limpiá
  sesión y mandá a login.
- **Errores:** parseá siempre `response.data["detail"]` para mostrar el mensaje (vale también
  para `422`).
- **Roles:** el `rol` viene en el `user` del login/registro y en `/auth/me`. Usalo para rutear
  a shell cliente/proveedor/admin.
- **Upload:** `multipart/form-data`, campo `file`; respetá límites (5 MB avatar / 10 MB foto,
  JPEG/PNG/WebP, máx 5 fotos por servicio).
- **Geo:** para `/servicios/buscar` mandá `lat`/`lng` del dispositivo; el backend devuelve
  `distancia` en km.
- **CORS:** en web, serví el front desde `http://localhost:3000` o agregá tu origen a
  `CORS_ORIGINS` del backend (no se permite `*`).
- **WebSocket:** el token va en la query (`?token=`), no en header; manejá los códigos de
  cierre 4001/4003/4004 para distinguir token inválido / sin permiso / contratación inexistente.

---

*Documento verificado contra el código de `trabajoya-api` al 2026-06-18. Si cambian schemas
o rutas, regenerar desde el código (es la fuente de verdad). El backend también expone
**Swagger** en `http://localhost:8000/docs` para probar en vivo.*
