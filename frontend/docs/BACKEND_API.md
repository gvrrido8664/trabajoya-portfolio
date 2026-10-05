# TrabajoYa — Documentación Completa de la API Backend

## Índice
1. [Configuración y Conexión](#1-configuración-y-conexión)
2. [Autenticación](#2-autenticación-apiv1auth)
3. [Usuarios](#3-usuarios-apiv1usuarios)
4. [Categorías](#4-categorías-apiv1categorias)
5. [Servicios](#5-servicios-apiv1servicios)
6. [Solicitudes y Propuestas](#6-solicitudes-y-propuestas-apiv1solicitudes)
7. [Contrataciones](#7-contrataciones-apiv1contrataciones)
8. [Pagos — MercadoPago](#8-pagos-apiv1pagos)
9. [Suscripciones](#9-suscripciones-apiv1suscripciones)
10. [Upload de Archivos](#10-upload-apiv1upload)
11. [Chat (REST + WebSocket)](#11-chat-apiv1chat)
12. [Reseñas y Disputas](#12-reseñas-y-disputas)
13. [Proveedores y Oportunidades](#13-proveedores-y-oportunidades)
14. [Suscripciones — Planes](#14-suscripciones--planes)
15. [Admin](#15-admin-apiv1admin)
16. [Bugs](#16-bugs-apiv1bugs)
17. [Enumeraciones y Convenciones](#17-enumeraciones-y-convenciones)

---

## 1. Configuración y Conexión

### Base URL
| Plataforma | URL |
|---|---|
| Web / iOS / Windows | `http://localhost:8000/api/v1` |
| Android Emulator | `http://10.0.2.2:8000/api/v1` |
| Producción | Variable de entorno `API_BASE_URL` |

### Stack del Backend
- **Framework:** FastAPI (Python 3.11+)
- **Base de datos:** PostgreSQL 16 + extensión PostGIS
- **ORM:** SQLAlchemy 2.x (async)
- **Autenticación:** JWT Bearer (60 min de expiración)
- **Almacenamiento de archivos:** Cloudinary
- **Pagos:** MercadoPago (SDK Python)
- **Rate limiting:** slowapi — global 100 req/min, login 5 req/min
- **WebSocket:** Nativo FastAPI

### Headers Comunes
```
Content-Type: application/json
Authorization: Bearer <JWT_TOKEN>   ← en rutas protegidas
```

### Formato de Errores
Todos los errores devuelven:
```json
{ "detail": "Mensaje descriptivo del error" }
```
Errores de validación Pydantic (422):
```json
{ "detail": "campo -> mensaje de error" }
```

### Variables de Entorno Requeridas (Backend)
```env
DATABASE_URL=postgresql+asyncpg://demo:demo@127.0.0.1:55432/trabajoya_demo
JWT_SECRET_KEY=clave_secreta_jwt
MP_ACCESS_TOKEN=APP_USR-...          # MercadoPago
MP_WEBHOOK_SECRET=secreto_hmac       # MercadoPago webhook HMAC
MP_PUBLIC_KEY=APP_USR-...            # MercadoPago (clave pública)
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
RESEND_API_KEY=re_...                # Servicio de email (Resend.com)
FRONTEND_URL=http://localhost:3000   # Para links en emails
BACKEND_URL=http://localhost:8000    # URL pública del backend
CORS_ORIGINS=http://localhost:3000,http://localhost:5173
```

---

## 2. Autenticación `/api/v1/auth`

### POST `/auth/register`
Registra un nuevo usuario. No requiere token.

**Query Params (opcionales):**
- `ref` — código de referido de otro usuario

**Body:**
```json
{
  "email": "usuario@example.com",
  "password": "minimo6chars",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+56912345678",
  "rol": "cliente | proveedor",
  "codigo_referido": null
}
```

**Response 201:**
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": { "...UsuarioResponse..." }
}
```

**Errores:** `409` email duplicado · `400` rol inválido

---

### POST `/auth/login`
Rate limit: 5/min por IP.

**Body:**
```json
{ "email": "usuario@example.com", "password": "contraseña" }
```

**Response 200:**
```json
{ "access_token": "eyJhbGc...", "token_type": "bearer" }
```

**Errores:** `400` credenciales incorrectas · `403` cuenta desactivada

---

### GET `/auth/me`
🔒 Requiere token. Devuelve el usuario autenticado.

**Response 200:** UsuarioResponse (ver sección 15)

---

### PATCH `/auth/me`
🔒 Requiere token. Actualiza datos del perfil.

**Body (todos opcionales):**
```json
{ "nombre": "Juan", "apellido": "Pérez", "telefono": "+56912345678" }
```

**Response 200:** UsuarioResponse actualizado

---

### POST `/auth/change-password`
🔒 Requiere token.

**Body:**
```json
{ "current_password": "actual", "new_password": "nueva_min6" }
```

**Response 200:** `{ "message": "Contraseña actualizada exitosamente" }`

**Errores:** `400` contraseña actual incorrecta

---

### GET `/auth/verify-email`
**Query Params:** `token` — token enviado por email

**Response 200:** `{ "message": "Email verificado exitosamente" }`

**Errores:** `400` token inválido · `404` usuario no encontrado

---

### POST `/auth/forgot-password`
**Body:** `{ "email": "usuario@example.com" }`

**Response 200:** `{ "message": "Te enviamos un link para restablecer tu contraseña" }`

---

### POST `/auth/reset-password`
**Body:**
```json
{ "token": "reset_token_del_email", "new_password": "nueva_contraseña" }
```

**Response 200:** `{ "message": "Contraseña actualizada exitosamente" }`

---

### POST `/auth/resend-verification`
🔒 Requiere token.

**Response 200:** `{ "message": "Correo de verificación reenviado" }`

---

## 3. Usuarios `/api/v1/usuarios`

### GET `/usuarios/{usuario_id}`
Sin autenticación. Perfil público de cualquier usuario.

**Response 200:** UsuarioResponse

**Errores:** `404`

---

### PUT `/usuarios/me`
🔒 Requiere token. Actualización completa del perfil propio.

**Body (todos opcionales):**
```json
{
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+56912345678",
  "bio": "Plomero con 10 años de experiencia",
  "habilidades": "reparación, instalación, soldadura",
  "avatar_url": "https://..."
}
```

**Response 200:** UsuarioResponse

---

### PATCH `/usuarios/me/ubicacion`
🔒 Requiere token. Actualiza la geolocalización del usuario (necesaria para búsquedas geoespaciales).

**Body:**
```json
{ "lat": -33.4489, "lng": -70.6693 }
```

Validaciones: `lat` entre -90 y 90, `lng` entre -180 y 180.

**Response 200:** `{ "message": "Ubicación actualizada" }`

---

### GET `/usuarios/me/referidos`
🔒 Requiere token.

**Response 200:**
```json
{
  "mi_codigo": "AB12CD34",
  "total_referidos": 5,
  "referidos": [
    { "id": "uuid", "nombre": "Pedro", "apellido": "García", "is_verified": true, "created_at": "..." }
  ]
}
```

---

## 4. Categorías `/api/v1/categorias`

### GET `/categorias`
Sin autenticación. Listado completo de categorías.

**Response 200:**
```json
[
  { "id": "uuid", "nombre": "Gasfitería", "slug": "gasfiteria", "icono": "🔧", "descripcion": "..." }
]
```

---

### GET `/categorias/{slug}`
Sin autenticación.

**Response 200:** CategoriaResponse · **Errores:** `404`

---

## 5. Servicios `/api/v1/servicios`

### POST `/servicios`
🔒 Rol: **proveedor**. Crea un nuevo servicio.

**Body:**
```json
{
  "categoria_id": "uuid",
  "titulo": "Reparación de cañerías",
  "descripcion": "Reparación y mantenimiento...",
  "precio_min": 50.0,
  "precio_max": 200.0,
  "radio_cobertura_km": 10,
  "direccion_texto": "Providencia, Santiago"
}
```

Validaciones: `precio_min >= 0`, `precio_max >= 0`, `radio_cobertura_km > 0`

**Response 201:** ServicioResponse

---

### GET `/servicios`
Sin autenticación. Lista servicios con filtros opcionales.

**Query Params:**
- `categoria_id` — UUID categoría
- `proveedor_id` — UUID proveedor
- `skip` (default 0) · `limit` (default 20, máx 100)

**Response 200:** `[ServicioResponse]`

---

### GET `/servicios/buscar`
Sin autenticación. **Búsqueda geoespacial** con PostGIS.

**Query Params (requeridos):**
- `lat` — latitud del cliente
- `lng` — longitud del cliente

**Query Params (opcionales):**
- `radio_km` (default 10) — radio de búsqueda en km
- `categoria_id`
- `skip` / `limit`

**Response 200:** `[ServicioResponse]` — incluye campo `distancia` en km, ordenado por cercanía

**Nota:** El radio se calcula con `ST_DWithin` de PostGIS usando la ubicación configurada en el servicio (no la del proveedor). La distancia se obtiene con `ST_Distance` y se devuelve en km.

---

### GET `/servicios/{servicio_id}`
Sin autenticación.

**Response 200:** ServicioResponse · **Errores:** `404`

---

### PUT `/servicios/{servicio_id}`
🔒 Rol: **proveedor** (dueño del servicio).

**Body:** Mismos campos que POST, todos opcionales.

**Response 200:** ServicioResponse actualizado

**Errores:** `403` no es dueño · `404`

---

### POST `/servicios/{servicio_id}/destacar`
🔒 Rol: **proveedor** (dueño). Toggle — alterna destacado/no destacado.

**Response 200:** `{ "es_destacado": true }`

---

### PATCH `/servicios/{servicio_id}/pausar`
🔒 Rol: **proveedor** (dueño). Toggle — alterna ACTIVO/PAUSADO.

**Response 200:** `{ "status": "PAUSADO" }`

---

### DELETE `/servicios/{servicio_id}`
🔒 Rol: **proveedor** (dueño). Soft-delete (status → ELIMINADO).

**Response 204** (sin body)

**Errores:** `403` · `404`

---

## 6. Solicitudes y Propuestas `/api/v1/solicitudes`

### POST `/solicitudes`
🔒 Rol: **cliente**. Publica una solicitud de servicio.

**Body:**
```json
{
  "titulo": "Necesito reparación de cañería",
  "descripcion": "Hay un escape de agua en la cocina...",
  "categoria_id": "uuid",
  "presupuesto_max": 300.0,
  "ubicacion_texto": "Providencia, Santiago"
}
```

**Response 201:** SolicitudResponse

---

### GET `/solicitudes`
Sin autenticación. Lista solicitudes abiertas.

**Query Params:** `categoria_id`, `skip`, `limit`

**Response 200:**
```json
{
  "total": 15,
  "limit": 20,
  "offset": 0,
  "items": [{ "...SolicitudResponse..." }]
}
```

---

### GET `/solicitudes/mis-solicitudes`
🔒 Rol: **cliente**.

**Response 200:** `[SolicitudResponse]`

---

### GET `/solicitudes/{solicitud_id}`
Sin autenticación.

**Response 200:** SolicitudResponse · **Errores:** `404`

---

### PATCH `/solicitudes/{solicitud_id}/cerrar`
🔒 Rol: **cliente** (dueño).

**Response 200:** `{ "status": "CERRADA" }`

**Errores:** `403` · `400` ya cerrada

---

### POST `/solicitudes/{solicitud_id}/propuestas`
🔒 Rol: **proveedor**. Envía una propuesta para una solicitud.

**Body:**
```json
{
  "descripcion": "Puedo reparar esto en 2 horas...",
  "precio": 150.0,
  "tiempo_estimado": "2 horas"
}
```

**Response 201:** PropuestaResponse

**Errores:** `403` no es proveedor · `404` solicitud · `400` solicitud cerrada · `409` propuesta duplicada

---

### GET `/solicitudes/{solicitud_id}/propuestas`
🔒 Rol: **cliente** (dueño de la solicitud).

**Response 200:** `[PropuestaResponse]`

---

### PATCH `/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/aceptar`
🔒 Rol: **cliente** (dueño). Acepta una propuesta.

**Efecto colateral:**
- Crea una **Contratación** en estado `ACEPTADO`
- Cierra la solicitud (`CERRADA`)
- Rechaza automáticamente las demás propuestas

**Response 200:** PropuestaResponse con `contratacion_id` incluido

---

### PATCH `/solicitudes/{solicitud_id}/propuestas/{propuesta_id}/rechazar`
🔒 Rol: **cliente** (dueño).

**Response 200:** PropuestaResponse con status `RECHAZADA`

---

### GET `/propuestas/mis-propuestas`
🔒 Rol: **proveedor**.

**Query Params:** `skip`, `limit`

**Response 200:** `[PropuestaResponse]`

---

## 7. Contrataciones `/api/v1/contrataciones`

### POST `/contrataciones`
🔒 Rol: **cliente**. Contratación directa (sin solicitud previa).

**Body:**
```json
{
  "servicio_id": "uuid",
  "monto_acordado": 150.0,
  "mensaje_solicitud": "¿Puedes venir mañana a las 14:00?",
  "fecha_programada": "2026-06-25T14:00:00"
}
```

**Response 201:** ContratacionResponse

**Errores:** `403` · `404` servicio inactivo · `400` autoprestación

---

### GET `/contrataciones`
🔒 Requiere token. Devuelve todas las contrataciones del usuario autenticado (como cliente o proveedor).

**Query Params:** `skip`, `limit`

**Response 200:**
```json
{
  "total": 10,
  "limit": 20,
  "offset": 0,
  "items": [
    {
      "id": "uuid",
      "cliente_id": "uuid",
      "proveedor_id": "uuid",
      "servicio_id": "uuid",
      "propuesta_id": null,
      "status": "ACEPTADO",
      "monto_acordado": 150.0,
      "mensaje_solicitud": "...",
      "fecha_programada": "2026-06-25T14:00:00",
      "cliente_nombre": "Juan Pérez",
      "proveedor_nombre": "Pedro García",
      "servicio_titulo": "Reparación de cañería",
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

---

### GET `/contrataciones/{contratacion_id}`
🔒 Solo participantes (cliente o proveedor de esa contratación).

**Response 200:** ContratacionResponse · **Errores:** `404` · `403`

---

### PATCH `/contrataciones/{contratacion_id}/aceptar`
🔒 Rol: **proveedor** (participante). Acepta la contratación.

Estado requerido: `PENDIENTE`

**Response 200:** `{ "status": "ACEPTADO" }`

**Errores:** `400` ya respondida

---

### PATCH `/contrataciones/{contratacion_id}/rechazar`
🔒 Rol: **proveedor** (participante).

Estado requerido: `PENDIENTE`

**Response 200:** `{ "status": "RECHAZADO" }`

---

### PATCH `/contrataciones/{contratacion_id}/finalizar`
🔒 Cualquier participante. Marca como completada.

Estado requerido: `ACEPTADO`

**Response 200:** `{ "status": "COMPLETADO" }`

**Errores:** `400` estado no válido

---

### PATCH `/contrataciones/{contratacion_id}/cancelar`
🔒 Cualquier participante.

Estado requerido: `PENDIENTE` o `ACEPTADO`

**Response 200:** `{ "status": "CANCELADO" }`

**Errores:** `403` · `400` estado no permite cancelación

---

### POST `/contrataciones/{contratacion_id}/resena`
🔒 Cualquier participante. Solo si status = `COMPLETADO`.

**Body:**
```json
{ "puntuacion": 5, "comentario": "Trabajo excelente" }
```

Validación: `puntuacion` entre 1 y 5.

**Response 201:** ResenaResponse

**Errores:** `400` estado incorrecto · `409` reseña duplicada

---

### GET `/contrataciones/usuario/{usuario_id}/resenas`
Sin autenticación.

**Response 200:** `[ResenaResponse]`

---

## 8. Pagos `/api/v1/pagos`

Integración con **MercadoPago** para pagos de garantía.

### POST `/pagos/crear`
🔒 Rol: **cliente**.

**Query Params:** `contratacion_id` (requerido)

Crea una preferencia de pago en MercadoPago. La contratación debe estar en estado `ACEPTADO`.

**Response 200:**
```json
{
  "id": "pref_12345",
  "init_point": "https://www.mercadopago.cl/checkout/v1/redirect?...",
  "sandbox_init_point": "https://sandbox.mercadopago.cl/checkout/...",
  "preference_id": "pref_12345",
  "external_reference": "uuid_de_contratacion",
  "status": "pending"
}
```

El frontend redirige al usuario a `init_point` (producción) o `sandbox_init_point` (testing).

**Errores:** `404` · `403` no es cliente · `400` estado incorrecto · `400` monto inválido

---

### POST `/pagos/webhooks/pagos`
**Sin autenticación.** Webhook llamado automáticamente por MercadoPago.

**Headers obligatorios:**
- `X-Signature` — Firma HMAC SHA256 calculada por MercadoPago

El backend valida la firma contra `MP_WEBHOOK_SECRET` antes de procesar.

**Body (enviado por MercadoPago):**
```json
{ "data": { "id": "payment_id_de_mercadopago" } }
```

**Lógica interna:**
1. Valida firma HMAC
2. Consulta el pago en la API de MercadoPago
3. Si `status == "approved"` → actualiza `Pago.status = APROBADO`
4. Idempotente — si ya fue procesado, responde 200 sin re-procesar

**Response 200:** `{ "status": "procesado" }`

**URL a configurar en MercadoPago Dashboard:** `https://tu-dominio.com/api/v1/pagos/webhooks/pagos`

---

### GET `/pagos/{contratacion_id}/estado`
🔒 Solo participantes de la contratación.

**Response 200:**
```json
{
  "status": "APROBADO",
  "monto": 150000.0,
  "fee_plataforma": 15000.0,
  "monto_neto": 135000.0
}
```

Fee de plataforma = 10% del monto.

**Errores:** `404` sin pago registrado · `403`

---

## 9. Suscripciones `/api/v1/suscripciones`

### POST `/suscripciones/crear`
🔒 Rol: **proveedor**. Inicia el proceso de suscripción vía MercadoPago.

**Body:**
```json
{ "plan_slug": "premium" }
```

**Response 200:** Igual a PagoPreferenceResponse (`init_point`, `sandbox_init_point`, etc.)

Redirigir al proveedor al `init_point` devuelto.

**Errores:** `404` plan no encontrado

---

### POST `/suscripciones/cancelar`
🔒 Rol: **proveedor**. Cancela la suscripción activa.

Sin body.

**Response 200:** `{ "message": "Suscripción cancelada exitosamente" }`

**Errores:** `404` sin suscripción activa

---

### GET `/suscripciones/me`
🔒 Rol: **proveedor**. Estado de la suscripción activa.

**Response 200 (sin suscripción):**
```json
{ "tiene_suscripcion": false, "plan_slug": null }
```

**Response 200 (con suscripción):**
```json
{
  "tiene_suscripcion": true,
  "plan_slug": "premium",
  "status": "ACTIVO",
  "fecha_inicio": "2026-06-18T10:30:00+00:00",
  "fecha_fin": "2026-07-18T10:30:00+00:00"
}
```

---

## 10. Upload `/api/v1/upload`

Todos los uploads son `multipart/form-data`. Los archivos se almacenan en **Cloudinary**.

### POST `/upload/avatar`
🔒 Requiere token. Sube y reemplaza el avatar del usuario autenticado.

**Form Data:**
- `file` (binary) — Imagen JPEG/PNG/WebP, máx **5 MB**

**Response 200:**
```json
{ "url": "https://res.cloudinary.com/..." }
```

Actualiza automáticamente `usuario.avatar_url`.

---

### POST `/upload/servicio/{servicio_id}`
🔒 Rol: **proveedor** (dueño del servicio). Añade una foto al servicio.

**Form Data:**
- `file` (binary) — Imagen, máx **10 MB**

**Límite:** máximo 5 fotos por servicio.

**Response 200:**
```json
{
  "url": "https://res.cloudinary.com/...",
  "fotos": ["https://url_foto_1", "https://url_foto_2"]
}
```

**Errores:** `404` · `403` · `400` máximo 5 fotos alcanzado

---

### DELETE `/upload/{public_id}`
🔒 Requiere token. Elimina un archivo de Cloudinary.

`public_id` ejemplos: `usuarios/uuid/avatar`, `servicios/uuid/foto_0`

**Validación de ownership:**
- Avatar: `public_id` debe empezar con `usuarios/{current_user_id}/`
- Foto de servicio: el usuario debe ser dueño del servicio

**Response 200:** `{ "message": "Archivo eliminado" }`

---

## 11. Chat `/api/v1/chat`

Sistema de mensajería en tiempo real por WebSocket con fallback REST.

### WebSocket `ws://host/api/v1/chat/ws/{contratacion_id}`

El token JWT se pasa como query param (limitación del protocolo WebSocket):
```
ws://localhost:8000/api/v1/chat/ws/{contratacion_id}?token=eyJhbGc...
```

Solo pueden conectarse el cliente y proveedor de esa contratación.

**Enviar mensaje (cliente → servidor):**
```json
{ "contenido": "¿Puedes venir mañana a las 14:00?" }
```

**Recibir mensaje (servidor → cliente):**
```json
{
  "id": "uuid",
  "contratacion_id": "uuid",
  "emisor_id": "uuid",
  "contenido": "¿Puedes venir mañana a las 14:00?",
  "leido": false,
  "created_at": "2026-06-18T10:30:00+00:00"
}
```

**Códigos de cierre WebSocket:**
- `4001` — Token inválido o expirado
- `4003` — No autorizado (no es participante)
- `4004` — Contratación no encontrada

---

### POST `/chat/{contratacion_id}/mensajes`
🔒 Solo participantes. Alternativa REST.

**Body:** `{ "contenido": "Hola, ¿cómo estás?" }`

**Response 201:** MensajeResponse

---

### GET `/chat/{contratacion_id}/mensajes`
🔒 Solo participantes. Historial paginado.

**Query Params:** `skip` (default 0) · `limit` (default 50, máx 200)

**Response 200:** `[MensajeResponse]` — ordenado DESC por fecha

**Errores:** `404` · `403`

---

### GET `/chat/conversaciones`
🔒 Requiere token. Vista tipo "inbox".

**Query Params:** `skip`, `limit`

**Response 200:**
```json
{
  "total": 5,
  "limit": 20,
  "offset": 0,
  "items": [
    {
      "contratacion_id": "uuid",
      "otro_usuario_id": "uuid",
      "otro_usuario_nombre": "Juan Pérez",
      "ultimo_mensaje": "Mañana a las 14:00",
      "ultimo_mensaje_fecha": "2026-06-18T10:30:00+00:00",
      "mensajes_no_leidos": 3,
      "status_contratacion": "ACEPTADO"
    }
  ]
}
```

---

## 12. Reseñas y Disputas

### POST `/resenas/{contratacion_id}`
🔒 Rol: **cliente**.

**Body:** `{ "puntuacion": 5, "comentario": "Excelente" }`

**Response 201:** ResenaResponse

---

### GET `/resenas/usuario/{usuario_id}`
Sin autenticación.

**Response 200:** `[ResenaResponse]`

---

### POST `/disputas/contratacion/{contratacion_id}`
🔒 Cualquier participante. Abre una disputa.

**Body:**
```json
{
  "motivo": "El servicio no fue completado correctamente",
  "evidencias": ["https://foto1.jpg", "https://foto2.jpg"]
}
```

**Response 201:**
```json
{
  "id": "uuid",
  "contratacion_id": "uuid",
  "abridor_id": "uuid",
  "motivo": "...",
  "evidencias": ["..."],
  "status": "ABIERTA",
  "resolucion": null,
  "created_at": "..."
}
```

**Errores:** `404` · `403` · `400` estado inválido · `409` disputa ya existente

---

### GET `/disputas/admin`
🔒 Rol: **admin**.

**Query Params:** `status` (opcional)

**Response 200:** `{ "total": N, "data": [...] }`

---

### PATCH `/disputas/admin/{disputa_id}/resolver`
🔒 Rol: **admin**.

**Query Params:** `accion` — `"reembolsar"` | `"liberar"`

**Body:** `{ "resolucion": "Descripción de la resolución" }`

**Response 200:** `{ "id": "uuid", "estado": "RESUELTA", "accion": "reembolsar" }`

---

## 13. Proveedores y Oportunidades

### GET `/proveedores/top`
Sin autenticación. Devuelve los proveedores mejor calificados.

**Query Params:** `limit` (default 10, máx 50)

**Response 200:**
```json
[
  {
    "id": "uuid",
    "nombre": "Juan Pérez",
    "avatar_url": "https://...",
    "avg_rating": 4.9,
    "bio": "Plomero con 10 años de experiencia",
    "total_contratos": 52
  }
]
```

Solo incluye proveedores activos con `avg_rating > 0`, ordenados por rating descendente.

---

### GET `/oportunidades`
Sin autenticación. Lista contrataciones en estado `PENDIENTE` (oportunidades para proveedores).

**Query Params:** `limit` (default 20, máx 100)

**Response 200:**
```json
[
  {
    "contratacion_id": "uuid",
    "servicio_id": "uuid",
    "cliente_id": "uuid",
    "cliente_nombre": "María González",
    "monto_acordado": 150.0,
    "mensaje_solicitud": "¿Puedes venir mañana?",
    "fecha_programada": "2026-06-25T14:00:00",
    "created_at": "..."
  }
]
```

---

## 14. Suscripciones — Planes

### GET `/suscripciones/planes`
Sin autenticación. Lista todos los planes de suscripción disponibles.

**Response 200:**
```json
[
  {
    "id": "uuid",
    "nombre": "Premium",
    "slug": "premium",
    "descripcion": "Acceso completo a todas las funciones",
    "beneficios": ["Servicios ilimitados", "Destacado en búsquedas", "Soporte prioritario"],
    "precio_mensual": 9990.0
  }
]
```

Ordenado por `precio_mensual` ascendente.

---

## 15. Admin `/api/v1/admin`

Todos requieren rol **admin**.

### GET `/admin/stats`

**Response 200:**
```json
{
  "usuarios": { "total": 150, "proveedores": 45, "clientes": 105 },
  "servicios_activos": 89,
  "contrataciones": { "total": 234, "este_mes": 45 },
  "volumen_transaccionado_mes": 5234500.50,
  "contrataciones_por_mes": [{ "mes": "2026-01", "total": 38 }],
  "top_categorias": [{ "nombre": "Gasfitería", "total": 23 }],
  "top_proveedores": [{ "nombre": "Juan Pérez", "rating": 4.9, "total_contratos": 52 }]
}
```

---

### GET `/admin/usuarios`
**Query Params:** `skip`, `limit` (máx 200), `rol`, `email` (búsqueda parcial)

**Response 200:** `{ "total": N, "skip": 0, "limit": 50, "data": [...UsuarioResponse] }`

---

### POST `/admin/usuarios`
Crea usuario directamente (sin email de verificación).

**Body:** `{ "email", "password", "nombre", "apellido", "rol", "telefono" }`

**Response 201:** UsuarioResponse

---

### PUT `/admin/usuarios/{usuario_id}`
Actualización completa de cualquier usuario.

**Body:** `{ "email", "nombre", "apellido", "telefono", "rol", "is_active" }`

**Response 200:** UsuarioResponse

---

### PATCH `/admin/usuarios/{usuario_id}/toggle-active`

**Response 200:** `{ "id": "uuid", "is_active": false }`

---

### GET `/admin/servicios`
**Query Params:** `skip`, `limit`, `status` (`ACTIVO` | `PAUSADO` | `ELIMINADO`)

**Response 200:** `{ "total": N, "data": [...ServicioResponse] }`

---

### GET `/admin/suscripciones`
**Query Params:** `skip`, `limit` (máx 200)

**Response 200:**
```json
{
  "total": 12,
  "data": [
    {
      "id": "uuid",
      "usuario_id": "uuid",
      "plan_id": "uuid",
      "plan_nombre": "Premium",
      "status": "ACTIVA",
      "fecha_inicio": "...",
      "fecha_vencimiento": "...",
      "created_at": "..."
    }
  ]
}
```

---

### POST `/admin/suscripciones/{suscripcion_id}/cancelar`
Sin body. Cancela cualquier suscripción.

**Response 200:** `{ "message": "Suscripción cancelada exitosamente" }`

**Errores:** `404`

---

### GET `/admin/buscar`
Búsqueda global de usuarios y servicios.

**Query Params:** `q` (requerido, mín 1 caracter) — busca en email, nombre, apellido, título y descripción

**Response 200:**
```json
{
  "usuarios": [
    { "id": "uuid", "email": "...", "nombre": "Juan", "apellido": "Pérez", "rol": "cliente" }
  ],
  "servicios": [
    { "id": "uuid", "titulo": "Reparación de cañerías", "status": "ACTIVO" }
  ]
}
```

---

### GET `/admin/pagos`
**Query Params:** `skip`, `limit`, `status`

**Response 200:**
```json
{
  "total": 234,
  "volumen_total_aprobado": 5234500.50,
  "data": [
    {
      "id": "uuid",
      "contratacion_id": "uuid",
      "monto": 150000.0,
      "fee_plataforma": 15000.0,
      "monto_neto": 135000.0,
      "gateway": "mercadopago",
      "status": "APROBADO",
      "created_at": "..."
    }
  ]
}
```

---

## 16. Bugs `/api/v1/bugs`

### POST `/bugs`
🔒 Requiere token.

**Body:**
```json
{
  "titulo": "Avatar no se sube",
  "descripcion": "Al subir imagen WebP obtengo error 400",
  "area": "upload"
}
```

**Areas válidas:** `"upload"` · `"chat"` · `"pagos"` · `"otro"`

**Response 201:** BugReportResponse

---

### GET `/bugs/mis-reportes`
🔒 Requiere token.

**Response 200:** `[BugReportResponse]`

---

### GET `/admin/bugs`
🔒 Rol: **admin**.

**Query Params:** `status` (opcional)

**Response 200:** `{ "total": N, "data": [...BugReportResponse] }`

---

### PATCH `/admin/bugs/{bug_id}`
🔒 Rol: **admin**.

**Query Params:** `status` (ej: `"resuelto"`)

**Response 200:** `{ "id": "uuid", "status": "RESUELTO" }`

---

## 17. Enumeraciones y Convenciones

### Enumeraciones de Estado
```
RolUsuario:         "cliente" | "proveedor" | "admin"       ← siempre minúscula
EstadoServicio:     "ACTIVO" | "PAUSADO" | "ELIMINADO"
StatusSolicitud:    "ABIERTA" | "CERRADA"
StatusPropuesta:    "PENDIENTE" | "ACEPTADA" | "RECHAZADA" | "CANCELADA"
EstadoContratacion: "PENDIENTE" | "ACEPTADO" | "RECHAZADO" | "COMPLETADO" | "CANCELADO" | "DISPUTA"
EstadoPago:         "PENDIENTE" | "APROBADO" | "RECHAZADO" | "CANCELADO"
EstadoDisputa:      "ABIERTA" | "RESUELTA"
EstadoSuscripcion:  "ACTIVA" | "CANCELADA" | "VENCIDA"
EstadoBug:          "ABIERTO" | "EN_PROCESO" | "RESUELTO"
AreaBug:            "DISENO" | "FUNCION" | "LOGICA" | "OTRO"
```

### UsuarioResponse (schema completo)
```json
{
  "id": "uuid",
  "email": "usuario@example.com",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+56912345678",
  "rol": "cliente",
  "avatar_url": null,
  "bio": null,
  "habilidades": null,
  "is_active": true,
  "is_verified": false,
  "avg_rating": 0.0,
  "referidos_count": 0,
  "codigo_referido": "AB12CD34",
  "email_verificado": false,
  "created_at": "2026-06-18T10:30:00+00:00",
  "updated_at": "2026-06-18T10:30:00+00:00"
}
```

### ServicioResponse (schema completo)
```json
{
  "id": "uuid",
  "proveedor_id": "uuid",
  "proveedor_nombre": "Juan Pérez",
  "proveedor_rating": 4.8,
  "categoria_id": "uuid",
  "categoria_nombre": "Gasfitería",
  "titulo": "Reparación de cañerías",
  "descripcion": "...",
  "precio_min": 50.0,
  "precio_max": 200.0,
  "radio_cobertura_km": 10,
  "direccion_texto": "Santiago",
  "fotos": ["https://..."],
  "es_destacado": false,
  "status": "ACTIVO",
  "distancia": 1.2,
  "created_at": "...",
  "updated_at": "..."
}
```

### Paginación
Parámetros universales: `skip` (offset, default 0) y `limit` (default 20, máx 100).

Respuesta envuelta: `{ "total", "limit", "offset", "items": [...] }`

Endpoints que devuelven arrays directos (sin envolver): categorías, mis-solicitudes, mis-propuestas, reseñas.

### Timestamps
Formato ISO 8601 con timezone: `"2026-06-18T10:30:00+00:00"`

### Rate Limiting
- **Global:** 100 requests/min por IP → `HTTP 429`
- **Login:** 5 requests/min por IP → `HTTP 429`

### Autenticación JWT
- Header: `Authorization: Bearer <token>`
- Expiración: **60 minutos**
- No existe endpoint de refresh — el cliente debe re-autenticar con `/auth/login`
- WebSocket: token como query param `?token=<JWT>` (los WebSockets no soportan headers personalizados)
