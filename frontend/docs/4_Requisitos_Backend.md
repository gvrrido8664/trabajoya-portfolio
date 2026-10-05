# Especificación de API Backend — TrabajoYa App

> **Versión:** 1.0  
> **Propósito:** Contrato estricto que el frontend Flutter espera consumir.  
> **Formato de comunicación:** JSON sobre HTTP REST.  

---

## 1. Configuración Global y Red (`lib/core/`)

### 1.1 Base URL

| Plataforma | URL |
|---|---|
| Web | `http://localhost:8000/api/v1` |
| Android Emulador | `http://10.0.2.2:8000/api/v1` |
| iOS / Desktop | `http://localhost:8000/api/v1` |

*Definido en `lib/core/constants.dart:5-11`*

### 1.2 Headers Esperados

| Header | Valor | Condición |
|---|---|---|
| `Content-Type` | `application/json` | Siempre |
| `Authorization` | `Bearer <token>` | Endpoints autenticados |

Los headers se ensamblan en `ApiClient._authHeaders()` (`lib/core/api_client.dart:76-85`).  
El token se almacena en `FlutterSecureStorage` (nativo) o `localStorage` (web) bajo la clave `auth_token`.

### 1.3 Manejo de Errores

El frontend espera la siguiente estructura para errores HTTP:

#### Errores 4xx / 5xx

```json
{
  "detail": "Mensaje descriptivo del error"
}
```

**Comportamiento del cliente (`lib/core/api_client.dart:97-119`):**

| Código | Excepción | Mensaje por defecto |
|---|---|---|
| `401` | `AuthException` | "Sesion expirada. Inicia sesion nuevamente." (además borra el token local) |
| `400`, `403`, `404`, `500` | `ApiException(statusCode, detail)` | Toma el campo `detail` del JSON. Si no existe, usa el body textual o "Error {statusCode}" |

**Regla IMPORTANTE:** El backend DEBE devolver siempre un campo `detail` (string) en las respuestas de error.  
El frontend espera acceder a `body['detail']` — si es un string lo muestra directamente, si es un objeto lo serializa con `.toString()`.

---

## 2. Diccionario de Modelos por Feature

Todos los modelos tienen `fromJson()` y `toJson()` en `lib/models/`.  
Los constructores aceptan tanto `snake_case` como `camelCase` para tolerancia.

### 2.1 Auth / Usuario (`lib/models/usuario.dart`)

```json
{
  "id": "string (obligatorio)",
  "email": "string (obligatorio)",
  "nombre": "string (obligatorio)",
  "apellido": "string (obligatorio)",
  "rol": "string (obligatorio) — valores: 'cliente' | 'proveedor' | 'admin'",
  "telefono": "string | null (opcional)",
  "avatar_url": "string | null (opcional)",
  "bio": "string | null (opcional)",
  "habilidades": "string | null (opcional)",
  "codigo_referido": "string | null (opcional)",
  "is_active": "bool (obligatorio)",
  "is_verified": "bool (obligatorio)",
  "email_verificado": "bool (default: false)",
  "avg_rating": "number (double, obligatorio)",
  "referidos_count": "int (obligatorio)",
  "created_at": "string ISO8601 (obligatorio)",
  "updated_at": "string ISO8601 | null (opcional)"
}
```

**Campos estrictamente obligatorios:** `id`, `email`, `nombre`, `apellido`, `rol`, `is_active`, `is_verified`, `avg_rating`, `referidos_count`, `created_at`.

### 2.2 Servicio (`lib/models/servicio.dart`)

```json
{
  "id": "string (obligatorio)",
  "proveedor_id": "string (obligatorio)",
  "categoria_id": "string (obligatorio)",
  "titulo": "string (obligatorio)",
  "descripcion": "string (obligatorio)",
  "status": "string (obligatorio) — valores: 'ACTIVO' | 'PAUSADO' | 'ELIMINADO'",
  "precio_min": "number | null (opcional)",
  "precio_max": "number | null (opcional)",
  "radio_cobertura_km": "int (default: 10)",
  "direccion_texto": "string | null (opcional)",
  "fotos": "string (JSON array) | null (opcional)",
  "distancia": "number | null (opcional) — solo para búsqueda geográfica",
  "proveedor_nombre": "string | null (opcional)",
  "proveedor_rating": "number | null (opcional)",
  "categoria_nombre": "string | null (opcional)",
  "created_at": "string ISO8601 (obligatorio)"
}
```

**Campos estrictamente obligatorios:** `id`, `proveedor_id`, `categoria_id`, `titulo`, `descripcion`, `status`, `radio_cobertura_km`, `created_at`.

### 2.3 Contratacion (`lib/models/contratacion.dart`)

```json
{
  "id": "string (obligatorio)",
  "cliente_id": "string (obligatorio)",
  "proveedor_id": "string (obligatorio)",
  "servicio_id": "string (obligatorio)",
  "status": "string (obligatorio) — valores: 'PENDIENTE' | 'ACEPTADO' | 'RECHAZADO' | 'COMPLETADO' | 'CANCELADO' | 'DISPUTA'",
  "monto_acordado": "number | null (opcional)",
  "mensaje_solicitud": "string | null (opcional)",
  "fecha_programada": "string ISO8601 | null (opcional)",
  "created_at": "string ISO8601 | null (opcional)",
  "updated_at": "string ISO8601 | null (opcional)",
  "servicio_titulo": "string | null (opcional)",
  "cliente_nombre": "string | null (opcional)",
  "proveedor_nombre": "string | null (opcional)"
}
```

**Campos estrictamente obligatorios:** `id`, `cliente_id`, `proveedor_id`, `servicio_id`, `status`.

### 2.4 Mensaje (`lib/models/mensaje.dart`)

```json
{
  "id": "string (obligatorio)",
  "contratacion_id": "string (obligatorio)",
  "emisor_id": "string (obligatorio)",
  "contenido": "string (obligatorio)",
  "leido": "bool (obligatorio)",
  "created_at": "string ISO8601 (obligatorio)"
}
```

**Todos los campos son obligatorios.**

### 2.5 Reseña (`lib/models/resena.dart`)

```json
{
  "id": "string (obligatorio)",
  "contratacion_id": "string (obligatorio)",
  "calificador_id": "string (obligatorio)",
  "calificado_id": "string (obligatorio)",
  "puntuacion": "int (obligatorio) — escala 1-5",
  "comentario": "string | null (opcional)",
  "created_at": "string ISO8601 (obligatorio)"
}
```

**Campos estrictamente obligatorios:** `id`, `contratacion_id`, `calificador_id`, `calificado_id`, `puntuacion`, `created_at`.

### 2.6 Categoria (`lib/models/categoria.dart`)

```json
{
  "id": "string (obligatorio)",
  "nombre": "string (obligatorio)",
  "slug": "string (obligatorio)",
  "icono": "string | null (opcional)",
  "descripcion": "string | null (opcional)",
  "parent_id": "string | null (opcional)"
}
```

**Campos estrictamente obligatorios:** `id`, `nombre`, `slug`.

---

## 3. Mapa de Endpoints REST

### 3.1 Autenticación (`lib/services/auth_service.dart`)

#### `POST /auth/login`
| Item | Detalle |
|---|---|
| Body | `{"email": "string", "password": "string"}` |
| Respuesta | `{"access_token": "string", "token_type": "bearer"}` |
| Nota | El frontend usa el token para llamar `GET /auth/me` inmediatamente |

#### `POST /auth/register`
| Item | Detalle |
|---|---|
| Body | `{"email": "string", "password": "string", "nombre": "string", "apellido": "string", "rol": "string", "telefono": "string | null (opcional)"}` |
| Query Params | `?ref=codigo_referido` (opcional) |
| Respuesta | `Usuario` (objeto completo) |

#### `GET /auth/me`
| Item | Detalle |
|---|---|
| Headers | `Authorization: Bearer <token>` |
| Respuesta | `Usuario` (objeto completo) |

#### `POST /auth/forgot-password`
| Item | Detalle |
|---|---|
| Body | `{"email": "string"}` |
| Respuesta | `{"message": "string"}` |

#### `POST /auth/reset-password`
| Item | Detalle |
|---|---|
| Body | `{"token": "string", "new_password": "string"}` |
| Respuesta | `{"message": "string"}` |

#### `GET /auth/verify-email`
| Item | Detalle |
|---|---|
| Query Params | `?token=string` |
| Respuesta | `{"message": "string"}` |

---

### 3.2 Servicios (`lib/services/servicios_service.dart`)

#### `GET /servicios`
| Item | Detalle |
|---|---|
| Query Params | `categoria_id?`, `proveedor_id?`, `skip?`, `limit?` |
| Respuesta | Lista plana `[Servicio, ...]` **o** `{"items": [Servicio, ...]}` (el frontend acepta ambos) |

#### `GET /servicios/buscar`
| Item | Detalle |
|---|---|
| Query Params | `lat` (double), `lng` (double), `radio_km?`, `categoria_id?`, `skip?`, `limit?` |
| Respuesta | Lista plana `[Servicio, ...]` **o** `{"items": [Servicio, ...]}` |

#### `GET /servicios/{id}`
| Item | Detalle |
|---|---|
| Respuesta | `Servicio` (objeto único) |

#### `POST /servicios`
| Item | Detalle |
|---|---|
| Body | `{"categoria_id": "string", "titulo": "string", "descripcion": "string", "precio_min": number?, "precio_max": number?, "radio_cobertura_km": int?, "direccion_texto": string?}` |
| Respuesta | `Servicio` (objeto creado) |

#### `PUT /servicios/{id}`
| Item | Detalle |
|---|---|
| Body | `{"categoria_id"?, "titulo"?, "descripcion"?, "precio_min"?, "precio_max"?, "radio_cobertura_km"?, "direccion_texto"?}` |
| Respuesta | `Servicio` (actualizado) |

#### `PATCH /servicios/{id}/pausar`
| Item | Detalle |
|---|---|
| Respuesta | `{"status": "ACTIVO" | "PAUSADO"}` (toggle) |

#### `DELETE /servicios/{id}`
| Item | Detalle |
|---|---|
| Respuesta | `null` (body vacío) |

---

### 3.3 Categorías (`lib/features/servicios/providers/servicios_provider.dart`)

#### `GET /categorias`
| Item | Detalle |
|---|---|
| Respuesta | Lista plana `[Categoria, ...]` **o** `{"items": [Categoria, ...]}` |

---

### 3.4 Contrataciones (`lib/services/contrataciones_service.dart`)

#### `POST /contrataciones`
| Item | Detalle |
|---|---|
| Body | `{"servicio_id": "string (obligatorio)", "monto_acordado": number?, "mensaje_solicitud": string?, "fecha_programada": "ISO8601"?}` |
| Respuesta | `Contratacion` (objeto creado) |

#### `GET /contrataciones`
| Item | Detalle |
|---|---|
| Respuesta | Lista plana `[Contratacion, ...]` **o** `{"items": [Contratacion, ...]}` |

#### `GET /contrataciones/{id}`
| Item | Detalle |
|---|---|
| Respuesta | `Contratacion` (objeto único) |

#### `PATCH /contrataciones/{id}/aceptar`
| Item | Detalle |
|---|---|
| Respuesta | `null` (body vacío) |

#### `PATCH /contrataciones/{id}/rechazar`
| Item | Detalle |
|---|---|
| Respuesta | `null` (body vacío) |

#### `PATCH /contrataciones/{id}/finalizar`
| Item | Detalle |
|---|---|
| Respuesta | `null` (body vacío) |

---

### 3.5 Reseñas (`lib/services/contrataciones_service.dart`)

#### `POST /contrataciones/{contratacion_id}/resena`
| Item | Detalle |
|---|---|
| Body | `{"contratacion_id": "string", "puntuacion": int, "comentario": string?}` |
| Respuesta | `Resena` (objeto creado) |

#### `GET /contrataciones/usuario/{usuario_id}/resenas`
| Item | Detalle |
|---|---|
| Respuesta | Lista plana `[Resena, ...]` **o** `{"items": [Resena, ...]}` |

---

### 3.6 Disputas (`lib/services/contrataciones_service.dart`)

#### `POST /disputas/contratacion/{contratacion_id}`
| Item | Detalle |
|---|---|
| Body | `{"motivo": "string (obligatorio)", "evidencias": ["string", ...]?}` |
| Respuesta | `{"id": "string", "contratacion_id": "string", "abridor_id": "string", "motivo": "string", "evidencias": ..., "status": "abierta", "resolucion": null, "created_at": "ISO8601"}` |

---

### 3.7 Chat (`lib/services/chat_service.dart` + `lib/features/chat/screens/chat_screen.dart`)

#### `GET /chat/conversaciones`
| Item | Detalle |
|---|---|
| Respuesta | Lista plana o `{"items": [...]}`. Cada item: |
| | `{"contratacion_id": "string", "otro_usuario_nombre": "string", "ultimo_mensaje": "string", "ultimo_mensaje_fecha": "ISO8601", "mensajes_no_leidos": int}` |

#### `GET /chat/{contratacion_id}/mensajes`
| Item | Detalle |
|---|---|
| Query Params | `skip?`, `limit?` |
| Respuesta | Lista plana `[Mensaje, ...]` **o** `{"items": [Mensaje, ...]}` |

#### `POST /chat/{contratacion_id}/mensajes`
| Item | Detalle |
|---|---|
| Body | `{"contenido": "string"}` |
| Respuesta | `Mensaje` (objeto creado) |

---

### 3.8 Pagos (`lib/services/pagos_service.dart`)

#### `POST /pagos/crear?contratacion_id={id}`
| Item | Detalle |
|---|---|
| Query Params | `contratacion_id` (obligatorio, sin body) |
| Respuesta | `{"id": "string", "init_point": "url MP", "sandbox_init_point": "url MP sandbox", "external_reference": "string", "status": "pending"}` |

#### `GET /pagos/{contratacion_id}/estado`
| Item | Detalle |
|---|---|
| Respuesta | `{"status": "aprobado" | "pendiente" | "rechazado" | "liberado", "monto": number, "fee_plataforma": number, "monto_neto": number}` |

---

### 3.9 Suscripciones (`lib/services/suscripciones_service.dart`)

#### `POST /suscripciones/crear`
| Item | Detalle |
|---|---|
| Body | `{"plan_slug": "string"}` |
| Respuesta | `{"id": "string", "init_point": "url MP", "status": "pending"}` |

#### `GET /suscripciones/me`
| Item | Detalle |
|---|---|
| Respuesta | `{"tiene_suscripcion": bool, "plan_slug": "string", "status": "activa" | "cancelada" | "pendiente", "fecha_inicio": "ISO8601", "fecha_fin": "ISO8601"}` |

---

### 3.10 Perfil (`lib/features/perfil/providers/perfil_provider.dart`)

#### `PUT /usuarios/me`
| Item | Detalle |
|---|---|
| Body | `{"nombre"?, "apellido"?, "telefono"?, "bio"?, "habilidades"?}` |
| Respuesta | `Usuario` (objeto actualizado) |

---

### 3.11 Admin (`lib/services/admin_service.dart`)

#### `GET /admin/stats`
| Item | Detalle |
|---|---|
| Respuesta | `{"usuarios": {"total": int, "clientes": int, "proveedores": int, "admins": int}, "servicios_activos": int, "contrataciones": {"total": int, "este_mes": int}, "volumen_transaccionado_mes": number, "contrataciones_por_mes": [{"mes": "YYYY-MM", "total": int}, ...], "top_proveedores": [{"nombre": "string", "rating": number, "total_contratos": int}, ...], "top_categorias": [{"nombre": "string", "total": int}, ...]}` |

#### `GET /admin/usuarios`
| Item | Detalle |
|---|---|
| Query Params | `rol?`, `email?`, `skip?`, `limit?` |
| Respuesta | `{"data": [Usuario, ...], "total": int}` |

#### `POST /admin/usuarios`
| Item | Detalle |
|---|---|
| Body | Campos de `Usuario` (según `Usuario.fromJson`) |
| Respuesta | `Usuario` (objeto creado, con `id` asignado) |

#### `PUT /admin/usuarios/{id}`
| Item | Detalle |
|---|---|
| Body | Campos editables de `Usuario` |
| Respuesta | `Usuario` (actualizado) |

#### `PATCH /admin/usuarios/{id}/toggle-active`
| Item | Detalle |
|---|---|
| Respuesta | `{"id": "string", "is_active": bool}` |

#### `GET /admin/servicios`
| Item | Detalle |
|---|---|
| Query Params | `status?`, `skip?`, `limit?` |
| Respuesta | `{"data": [Servicio, ...], "total": int}` |

#### `GET /admin/pagos`
| Item | Detalle |
|---|---|
| Query Params | `status?`, `skip?`, `limit?` |
| Respuesta | `{"data": [{"id", "contratacion_id", "monto", "fee_plataforma", "monto_neto", "status", "gateway", "created_at"}, ...], "total": int}` |

#### `GET /disputas/admin`
| Item | Detalle |
|---|---|
| Query Params | `status?` |
| Respuesta | `{"data": [{"id", "contratacion_id", "motivo", "status", "created_at"}, ...], "total": int}` |

#### `PATCH /disputas/admin/{disputa_id}/resolver?accion={accion}`
| Item | Detalle |
|---|---|
| Query Params | `accion` (ej: "liberar", "reembolsar") |
| Body | `{"resolucion": "string"}` |
| Respuesta | `{"estado": "resuelta"}` |

---

### 3.12 Uploads (`lib/services/upload_service.dart`)

#### `POST /upload/avatar`
| Item | Detalle |
|---|---|
| Content-Type | `multipart/form-data` |
| Fields | `file` (archivo) |
| Respuesta | `{"url": "string"}` |

#### `POST /upload/servicio/{servicio_id}`
| Item | Detalle |
|---|---|
| Content-Type | `multipart/form-data` |
| Fields | `file` (archivo) |
| Respuesta | `{"url": "string"}` |

---

## 4. WebSockets y Tiempo Real (Chat)

### Estado Actual

**No existe implementación de WebSocket en el frontend.** El chat funciona únicamente mediante REST:

1. `GET /chat/conversaciones` — listado de conversaciones (polling manual al abrir la pantalla)
2. `GET /chat/{contratacion_id}/mensajes` — carga de mensajes (polling manual)
3. `POST /chat/{contratacion_id}/mensajes` — envío de mensaje

### Recomendación para WebSocket

Para mensajes en tiempo real, implementar:

```
ws://host:8000/ws/chat/{contratacion_id}?token={jwt_token}
```

#### JSON de subida (cliente → servidor)
```json
{
  "contenido": "string"
}
```

#### JSON de bajada (servidor → cliente)
```json
{
  "id": "string",
  "contratacion_id": "string",
  "emisor_id": "string",
  "contenido": "string",
  "leido": false,
  "created_at": "ISO8601 string"
}
```

Estructura idéntica al modelo `Mensaje` (`lib/models/mensaje.dart`).

---

## 5. Convenciones Generales

### 5.1 Formato de Fechas
Todas las fechas se envían/reciben como strings en formato ISO8601:
```
2026-06-17T15:30:00.000
```

### 5.2 Paginación
El frontend es tolerante a múltiples formatos:

| Formato | Dónde se usa |
|---|---|
| Lista plana `[item, ...]` | `/servicios`, `/servicios/buscar`, `/contrataciones`, `/chat/conversaciones`, `/chat/{id}/mensajes`, `/categorias` |
| `{"items": [item, ...]}` | Fallback genérico en servicios |
| `{"data": [item, ...], "total": int}` | Endpoints de admin (`/admin/usuarios`, `/admin/servicios`, `/admin/pagos`, `/admin/disputas`) |

**Se recomienda estandarizar en:** `{"data": [item, ...], "total": int, "skip": int, "limit": int}` para todos los endpoints listables.

### 5.3 Manejo de mayúsculas en `status`
El frontend espera valores en **MAYÚSCULAS**:
- `Servicio.status`: `ACTIVO`, `PAUSADO`, `ELIMINADO`
- `Contratacion.status`: `PENDIENTE`, `ACEPTADO`, `RECHAZADO`, `COMPLETADO`, `CANCELADO`, `DISPUTA`

### 5.4 Códigos de error HTTP
| Código | Significado | Manejo del frontend |
|---|---|---|
| `200` | OK | Procesa respuesta |
| `201` | Creado | Procesa respuesta |
| `204` | Sin contenido | Retorna `null` |
| `400` | Bad Request | Muestra `detail` como error |
| `401` | No autorizado | Redirige a login, borra token |
| `403` | Prohibido | Muestra `detail` como error |
| `404` | No encontrado | Muestra `detail` como error |
| `422` | Validation Error | Muestra `detail` como error |
| `500` | Error interno | Muestra `detail` |

---

## 6. Observaciones Técnicas

### 6.1 Llamadas directas a `ApiClient` (sin service layer)
Varias partes del frontend llaman directamente a `ApiClient` sin pasar por los servicios:
- `GET /categorias` — llamado desde `ServiciosProvider.cargarCategorias()` y `CrearEditarServicioScreen._cargarCategorias()` (duplicado)
- `PUT /usuarios/me` — llamado desde `PerfilProvider.updateProfile()`
- `POST /chat/{id}/mensajes` — llamado directamente desde `ChatScreen._sendMessage()`

### 6.2 Tolerancia de casos (`snake_case` vs `camelCase`)
Los métodos `fromJson` de los modelos aceptan ambos formatos para todos los campos compuestos. El backend puede usar `snake_case` consistentemente.

### 6.3 Token de autenticación
- Se almacena localmente bajo la clave `auth_token`
- El login devuelve `{"access_token": "...", "token_type": "bearer"}`
- El endpoint `POST /register` NO devuelve token — el usuario debe loguearse después del registro
- El endpoint `POST /register` puede aceptar `?ref=codigo_referido` como query param

### 6.4 Mock mode
- La constante `mockMode = false` en `lib/core/constants.dart` está desactivada en producción
- Cuando está activa, `ApiClient` desvía todas las llamadas a `MockApi.handle()` en `lib/core/mock_data.dart` con delays simulados (210-500ms)
