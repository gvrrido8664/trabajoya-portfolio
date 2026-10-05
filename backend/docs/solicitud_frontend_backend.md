# Solicitud de Endpoints — TrabajoYa Frontend

Necesitamos que implementen los siguientes endpoints para conectar el frontend. Base URL: `/api/v1`. Autenticación: `Bearer token` en headers.

---

## 1. AUTENTICACIÓN `/auth`

| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| `POST` | `/auth/login` | `{email, password}` | `{access_token, token_type, user}` |
| `POST` | `/auth/register` | `{email, password, nombre, apellido, rol, telefono?, codigo_referido?}` | `Usuario` |
| `GET` | `/auth/me` | — | `Usuario` |
| `GET` | `/auth/verify-email?token=x` | — | `null` |
| `POST` | `/auth/forgot-password` | Query: `email` | `null` |
| `POST` | `/auth/reset-password` | Query: `token`, `new_password` | `null` |

### Modelo Usuario

```json
{
  "id": "string",
  "email": "string",
  "nombre": "string",
  "apellido": "string",
  "rol": "cliente | proveedor | admin",
  "telefono": "string?",
  "avatar_url": "string?",
  "bio": "string?",
  "habilidades": "string?",
  "is_active": true,
  "is_verified": true,
  "avg_rating": 0.0,
  "referidos_count": 0,
  "codigo_referido": "string?",
  "created_at": "ISO8601"
}
```

### Notas

- `rol`: `cliente` (busca servicios), `proveedor` (ofrece servicios), `admin`
- `codigo_referido`: código que el usuario puede usar al registrarse para obtener beneficios
- `access_token`: JWT o similar, se envía en `Authorization: Bearer <token>`

---

## 2. SERVICIOS `/servicios`

| Método | Endpoint | Body / Params | Respuesta |
|--------|----------|---------------|-----------|
| `GET` | `/servicios` | Query: `categoria_id?, search?, lat?, lng?, radio_km?` | `[Servicio]` |
| `GET` | `/servicios/:id` | — | `Servicio` |
| `POST` | `/servicios` | `{titulo, descripcion, categoria_id, precio_min?, precio_max?, radio_cobertura_km, direccion_texto?, fotos?}` | `Servicio` |
| `PUT` | `/servicios/:id` | Mismo body que POST | `Servicio` |
| `PATCH` | `/servicios/:id/pausar` | — | `Servicio` |
| `DELETE` | `/servicios/:id` | — | `null` |

### Modelo Servicio

```json
{
  "id": "string",
  "proveedor_id": "string",
  "categoria_id": "string",
  "titulo": "string",
  "descripcion": "string",
  "status": "activo | pausado | eliminado",
  "precio_min": 10000,
  "precio_max": 50000,
  "radio_cobertura_km": 10,
  "direccion_texto": "string?",
  "fotos": ["url1", "url2"],
  "distancia": 3.2,
  "proveedor_nombre": "string",
  "proveedor_rating": 4.5,
  "categoria_nombre": "string",
  "created_at": "ISO8601"
}
```

### Notas

- `GET /servicios` con `lat`, `lng`, `radio_km` debe ordenar por distancia y agregar campo `distancia`
- Solo `proveedor` puede crear/editar/eliminar sus propios servicios
- `status`: `activo` (visible), `pausado` (oculto pero existe), `eliminado` (borrado lógico)
- `fotos`: array de URLs de imágenes del servicio

---

## 3. CATEGORIAS `/categorias`

| Método | Endpoint | Respuesta |
|--------|----------|-----------|
| `GET` | `/categorias` | `[{id, nombre, slug, icono?, descripcion?}]` |

### Modelo Categoria

```json
{
  "id": "string",
  "nombre": "string",
  "slug": "string",
  "icono": "string?",
  "descripcion": "string?"
}
```

---

## 4. CONTRATACIONES `/contrataciones`

| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| `POST` | `/contrataciones` | `{servicio_id, monto_acordado?, mensaje_solicitud?, fecha_programada?}` | `Contratacion` |
| `GET` | `/contrataciones` | — | `[Contratacion]` |
| `GET` | `/contrataciones/:id` | — | `Contratacion` |
| `PATCH` | `/contrataciones/:id/aceptar` | — | `Contratacion` |
| `PATCH` | `/contrataciones/:id/rechazar` | — | `Contratacion` |
| `PATCH` | `/contrataciones/:id/finalizar` | — | `Contratacion` |
| `POST` | `/resenas` | `{contratacion_id, puntuacion, comentario?}` | `Resena` |
| `GET` | `/resenas/usuario/:usuarioId` | — | `[Resena]` |
| `POST` | `/disputas` | `{contratacion_id, motivo}` | `Disputa` |

### Modelo Contratacion

```json
{
  "id": "string",
  "cliente_id": "string",
  "proveedor_id": "string",
  "servicio_id": "string",
  "status": "pendiente | aceptado | rechazado | completado | cancelado | disputa",
  "monto_acordado": 30000,
  "mensaje_solicitud": "string?",
  "fecha_programada": "ISO8601?",
  "servicio_titulo": "string",
  "cliente_nombre": "string",
  "proveedor_nombre": "string",
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

### Modelo Resena

```json
{
  "id": "string",
  "contratacion_id": "string",
  "calificador_id": "string",
  "calificado_id": "string",
  "puntuacion": 1-5,
  "comentario": "string?",
  "created_at": "ISO8601"
}
```

### Notas — Máquina de estados

```
pendiente → proveedor acepta o rechaza
aceptado  → proveedor finaliza cuando termina el trabajo
completado → cliente paga → cliente deja reseña
rechazado / cancelado → terminal
disputa   → admin resuelve
```

- Solo `cliente` puede crear contrataciones y abrir disputas
- Solo `proveedor` puede aceptar, rechazar y finalizar
- Solo `cliente` puede dejar reseñas (y solo sobre contrataciones completadas)

---

## 5. CHAT `/chat`

| Método | Endpoint | Respuesta |
|--------|----------|-----------|
| `GET` | `/chat/conversaciones` | `[{contratacion_id, otro_usuario, ultimo_mensaje, leido, updated_at}]` |
| `GET` | `/chat/mensajes/:contratacionId` | `[Mensaje]` |
| `POST` | `/chat/mensajes/:contratacionId` | `{contenido}` | `Mensaje` |

### Modelo Mensaje

```json
{
  "id": "string",
  "contratacion_id": "string",
  "emisor_id": "string",
  "contenido": "string",
  "leido": false,
  "created_at": "ISO8601"
}
```

### Modelo Conversacion

```json
{
  "contratacion_id": "string",
  "servicio_titulo": "string",
  "otro_usuario": {
    "id": "string",
    "nombre": "string",
    "avatar_url": "string?"
  },
  "ultimo_mensaje": "string",
  "leido": true,
  "updated_at": "ISO8601"
}
```

### Notas

- Chat asociado a una contratación (no existe chat independiente)
- Para tiempo real: sugerimos WebSocket en `/ws/chat/:contratacionId`
- Si no hay WebSocket: polling cada 5 segundos en `GET /chat/mensajes/:contratacionId`
- Marcar mensajes como `leido=true` al consultarlos

---

## 6. PAGOS `/pagos`

| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| `POST` | `/pagos` | `{contratacion_id}` | `{init_point, preference_id, monto}` |
| `GET` | `/pagos/:contratacionId` | — | `{status, monto, fecha, preference_id}` |

### Notas

- `POST /pagos` crea la preferencia de MercadoPago y devuelve `init_point` (URL de checkout)
- El frontend abre `init_point` en WebView o navegador
- `status`: `pendiente`, `aprobado`, `rechazado`, `cancelado`
- El backend debe escuchar el webhook de MercadoPago para actualizar el estado

---

## 7. SUSCRIPCIONES `/suscripciones`

| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| `POST` | `/suscripciones` | `{plan_id}` | `Suscripcion` |
| `GET` | `/suscripciones/me` | — | `Suscripcion` |

### Modelo Suscripcion

```json
{
  "id": "string",
  "usuario_id": "string",
  "plan_id": "string",
  "plan_nombre": "string",
  "status": "activa | cancelada | vencida",
  "fecha_inicio": "ISO8601",
  "fecha_vencimiento": "ISO8601",
  "precio_mensual": 9990
}
```

### Modelo Plan

```json
{
  "id": "string",
  "nombre": "string",
  "precio_mensual": 9990,
  "descripcion": "string",
  "beneficios": ["string1", "string2"]
}
```

---

## 8. ADMIN `/admin`

Todas las rutas requieren `rol: admin`.

| Método | Endpoint | Body / Params | Respuesta |
|--------|----------|---------------|-----------|
| `GET` | `/admin/stats` | — | `{total_users, active_services, monthly_contracts, volume_clp, chart_data}` |
| `GET` | `/admin/usuarios` | Query: `rol?, is_active?` | `[Usuario]` |
| `POST` | `/admin/usuarios` | `{email, nombre, apellido, rol, telefono?, password?}` | `Usuario` |
| `PUT` | `/admin/usuarios/:id` | `{email, nombre, apellido, rol, telefono?}` | `Usuario` |
| `PATCH` | `/admin/usuarios/:id/toggle-active` | — | `Usuario` |
| `GET` | `/admin/servicios` | Query: `status?` | `[Servicio]` |
| `GET` | `/admin/pagos` | Query: `status?` | `[Pago]` |
| `GET` | `/admin/disputas` | — | `[Disputa]` |
| `PATCH` | `/admin/disputas/:id/resolve` | `{resolucion, action}` | `Disputa` |

### Modelo Stats

```json
{
  "total_users": 150,
  "active_services": 89,
  "monthly_contracts": 42,
  "volume_clp": 1250000,
  "chart_contracts_mensuales": [
    {"mes": "2025-01", "cantidad": 12, "monto": 450000},
    {"mes": "2025-02", "cantidad": 18, "monto": 620000}
  ],
  "top_proveedores": [
    {"id": "string", "nombre": "string", "contrataciones": 15, "rating": 4.8}
  ],
  "top_categorias": [
    {"id": "string", "nombre": "string", "contrataciones": 22}
  ]
}
```

### Modelo Disputa

```json
{
  "id": "string",
  "contratacion_id": "string",
  "abierta_por_id": "string",
  "motivo": "string",
  "status": "abierta | resuelta",
  "resolucion": "string?",
  "action_tomada": "string?",
  "created_at": "ISO8601",
  "resolved_at": "ISO8601?"
}
```

---

## Resumen de endpoints públicos (sin auth)

| Método | Endpoint |
|--------|----------|
| `POST` | `/auth/login` |
| `POST` | `/auth/register` |
| `GET` | `/auth/verify-email` |
| `POST` | `/auth/forgot-password` |
| `GET` | `/servicios` |
| `GET` | `/servicios/:id` |
| `GET` | `/categorias` |

---

## Códigos de error esperados

| Status | Significado | Body |
|--------|-------------|------|
| `400` | Bad request / validación | `{detail: "mensaje de error"}` |
| `401` | No autenticado / token inválido | `{detail: "No autenticado"}` |
| `403` | Sin permisos para esta acción | `{detail: "No tienes permiso"}` |
| `404` | Recurso no encontrado | `{detail: "No encontrado"}` |
| `500` | Error interno del servidor | `{detail: "Error interno"}` |

---

## Notas de implementación

1. **Auth**: usar JWT con expiración. Devolver `401` cuando expire.
2. **Geolocalización**: en `GET /servicios`, si se envían `lat`, `lng`, `radio_km`, calcular distancia y agregar campo `distancia` a cada resultado.
3. **Chat real-time**: lo ideal es WebSocket (`/ws/chat/:contratacionId`). Si no es posible, el frontend hará polling cada 5s.
4. **MercadoPago**: el backend debe crear la preferencia y devolver `init_point`. También necesita un endpoint/ webhook para recibir notificaciones de pago.
5. **Soft delete**: `DELETE /servicios/:id` debe ser borrado lógico (`status: eliminado`), no físico.
6. **Validación de Ownership**: al editar/eliminar un servicio, verificar que `proveedor_id` sea el usuario autenticado.