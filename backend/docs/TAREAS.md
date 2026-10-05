# Trabajo Ya — Estado del Proyecto

> Estado actual del proyecto (backend + frontend).
> Última actualización: 2026-06-17

---

## Rama actual

`feature/design` — desarrollo activo

---

## Frontend: mockMode

`mockMode = true` en `lib/core/constants.dart`. Todos los servicios consumen datos mock via `MockApi`.

**Credenciales mock:**
- Cliente: cualquier email sin "admin"/"carlos"/"ana" → `maria@correo.com`
- Proveedor: email contiene "carlos" o "proveedor"
- Admin: email contiene "admin"

Admin	admin@trabajoya.cl	admin123
Cliente	cliente1@trabajoya.cl	password123
Proveedor	proveedor1@trabajoya.cl	password123

---

## Arquitectura de rutas (Frontend)

### Públicas (sin auth)
| Ruta | Descripción |
|------|-------------|
| `/` | Landing page "Trabajo Ya" |
| `/login` | Login |
| `/register[?rol=cliente/proveedor]` | Registro con interruptor de rol |
| `/forgot-password` | Recuperar contraseña |
| `/verify-email?token=...` | Verificación de email |
| `/servicio/:id` | Detalle de servicio (público) |

### Cliente (auth requerida)
| Ruta | Screen |
|------|--------|
| `/cliente` → redirect `/cliente/buscar` | |
| `/cliente/buscar` | Marketplace |
| `/cliente/trabajos` | Mis contrataciones |
| `/cliente/chat` | Conversaciones |
| `/cliente/perfil` | Perfil del usuario |

### Proveedor (auth requerida)
| Ruta | Screen |
|------|--------|
| `/proveedor` → redirect `/proveedor/oportunidades` | |
| `/proveedor/oportunidades` | Solicitudes PENDIENTES |
| `/proveedor/servicios` | Mis servicios publicados |
| `/proveedor/solicitudes` | Solicitudes de contratación |
| `/proveedor/chat` | Conversaciones |
| `/proveedor/planes` | Planes y suscripciones |

### Admin (auth + rol=admin)
| Ruta | Screen |
|------|--------|
| `/admin` | Dashboard con métricas |
| `/admin/usuarios` | Gestión de usuarios |
| `/admin/servicios` | Gestión de servicios |
| `/admin/pagos` | Gestión de pagos |
| `/admin/disputas` | Gestión de disputas |

---

## Backend: Endpoints registrados (57 rutas, 16 routers)

| Router | Path prefix | Routes |
|--------|-------------|--------|
| auth | `/api/v1/auth` | POST register, POST login, GET me, GET verify-email, POST forgot-password, POST reset-password |
| usuarios | `/api/v1/usuarios` | GET `/{id}`, PUT /me, PATCH /me/ubicacion, GET /me/referidos |
| categorias | `/api/v1/categorias` | GET /, GET `/{slug}` |
| servicios | `/api/v1/servicios` | POST /, GET /, GET /buscar, GET `/{id}`, PUT `/{id}`, PATCH `/{id}/pausar`, DELETE `/{id}` |
| contrataciones | `/api/v1/contrataciones` | POST /, GET /, GET `/{id}`, PATCH `/{id}/aceptar`, PATCH `/{id}/rechazar`, PATCH `/{id}/finalizar`, POST `/{id}/resena` |
| resenas | `/api/v1/resenas` | POST /, GET /usuario/`{usuario_id}` |
| chat | `/api/v1/chat` | GET /conversaciones, GET /mensajes/`{contratacion_id}`, POST /mensajes/`{contratacion_id}`, WS /ws/`{contratacion_id}` |
| pagos | `/api/v1/pagos` | POST /crear, POST /webhooks/mercadopago, POST /webhooks/pagos, GET `/{contratacion_id}/estado` |
| suscripciones | `/api/v1/suscripciones` | POST /crear, GET /me |
| upload | `/api/v1/upload` | POST /avatar, POST /servicio/`{servicio_id}`, DELETE /`{public_id}` |
| proveedores | `/api/v1/proveedores` | GET /top |
| oportunidades | `/api/v1/oportunidades` | GET / |
| propuestas | `/api/v1/propuestas` | POST /, GET /recibidas, GET /enviadas, GET /mis-propuestas, GET `/{id}`, PATCH `/{id}/aceptar`, PATCH `/{id}/rechazar` |
| admin | `/api/v1/admin` | GET /stats, GET /usuarios, POST /usuarios, PATCH /usuarios/`{id}`/toggle-active, PUT /usuarios/`{id}`, GET /servicios, GET /pagos, GET /disputas, PATCH /disputas/`{id}`/resolver, GET /bugs, PATCH /bugs/`{bug_id}` |
| disputas | `/api/v1/disputas` | POST /contratacion/`{contratacion_id}`, GET /admin |
| bugs | `/api/v1/bugs` | POST /, GET /mis-reportes |

---

## Bugs críticos encontrados (🔴)

### Backend

1. **`PATCH /usuarios/me/ubicacion` reference a columna eliminada** (`app/api/routes_usuarios.py:87`)
   - El modelo `Usuario` ya no tiene columna `ubicacion`, pero el endpoint intenta `usuario.ubicacion = ...`
   - Causa `AttributeError` en runtime

2. **`GET /usuarios/me/referidos` reference a columna eliminada** (`app/api/routes_usuarios.py:107`)
   - Intenta filtrar por `Usuario.referido_por`, columna eliminada en refactor
   - Causa `AttributeError` en runtime

3. **Propuestas: dos routers desde el mismo archivo** (`app/api/routes_propuestas.py`)
   - `router = APIRouter()` y `propuestas_router = APIRouter()` coexisten
   - `propuestas_router` se registra como `/api/v1/propuestas` (contiene POST /, GET /recibidas, etc.)
   - `router` se registra como `/api/v1/propuestas` (contiene GET /mis-propuestas, GET `/{id}`, PATCH)
   - GET /mis-propuestas FUNCIONA (ambos routers escuchan en `/api/v1/propuestas`)
   - **Fix aplicado**: Fusionado en un solo router

4. **Reseñas: endpoint duplicado**
   - `POST /api/v1/resenas` en `routes_resenas.py`
   - `POST /api/v1/contrataciones/{contratacion_id}/resena` en `routes_contrataciones.py`
   - Ambas hacen lo mismo (crear reseña), pero el frontend usa solo la de contrataciones. La de resenas queda huérfana.

5. **No hay endpoint `GET /planes`** para listar planes de suscripción disponibles
   - El frontend en `ProveedorPlanesScreen` intenta cargar planes desde una URL no documentada
   - Posiblemente mockeado o roto

6. **JWT secret hardcodeado en `app/core/security.py`** con valor `"cambiar-esta-clave-secreta-en-produccion-por-una-larga-y-aleatoria"`

### Frontend

1. **RegisterScreen navega a `/login` en vez de auto-login** (`register_screen.dart`)
   - Tras registro exitoso, redirige a `/login` forzando al usuario a loguearse de nuevo
   - Debería llamar a `login()` automáticamente o redirigir según rol

2. **`AuthProvider.isCliente` defaults a `true` cuando `null`** (`auth_provider.dart`)
   - `isCliente ?? true` — si `null`, asume cliente
   - Debería ser `false` por defecto para no asumir

3. **Tres archivos `ResenaScreen` duplicados** en `lib/features/solicitudes/`, `lib/features/trabajos/`, `lib/features/contrataciones/`
   - Todos son archivos de respaldo/duplicados
   - **Fix aplicado**: Limpiados

4. **Dos archivos `SolicitarServicioScreen` duplicados** en `lib/features/solicitudes/`
   - **Fix aplicado**: Limpiados

5. **Dos archivos `PerfilScreen` duplicados** en `lib/features/perfil/`
   - **Fix aplicado**: Limpiados

6. **Dos archivos `PerfilAsScreen` duplicados** en `lib/features/perfil/`
   - **Fix aplicado**: Limpiados

7. **`PagoScreen` usa `web.window.open()` sin verificar plataforma** (`pago_screen.dart`)
   - En mobile/web, `web.window.open()` lanza excepción
   - Falta `if (kIsWeb) { ... } else { launchUrl(...) }`

8. **`MisPropuestasScreen` cards no tappable**
   - Las cards de propuestas no tienen `onTap` ni `onLongPress` ni `InkWell`
   - No se puede navegar al detalle

9. **`ApiClient.init()` nunca se llama** (`api_client.dart`)
   - El método `init()` existe pero nunca es invocado desde `main()` o `splash_screen`
   - El token solo se carga vía getter `token` (que llama `_loadToken()`)
   - El flag `_initialized` siempre queda `false` → depende de getter

10. **La mayoría de screens capturan `Exception` genérica incluyendo `AuthException`**
    - `catch (e) { ... }` traga errores de auth, impidiendo que `onUnauthorized` lo detecte
    - El `onUnauthorized` global está configurado pero no se ejecuta si la excepción se captura antes

---

## Bugs de media prioridad (🟡)

### Frontend

1. **SearchBar y CategoryChips en landing son no-op**: El banner de búsqueda y los chips de categoría en la Landing Screen parecen decorativos (no hay navegación)

2. **Sin avatar upload UI**: El endpoint `POST /upload/avatar` existe, pero no hay UI para subir avatar desde el perfil

3. **No hay pantalla ResetPassword**: El endpoint `POST /auth/reset-password` existe pero no tiene UI asociada

4. **Falta nav-back en múltiples pantallas detalle**: DetalleContratacionScreen, DetalleServicioScreen, OportunidadesScreen no tienen botón de retroceso

5. **MisPropuestasScreen no refresca tras mutaciones**: Aceptar/rechazar no recarga la lista automáticamente

6. **Admin no puede gestionar servicios/pagos individualmente**: Solo lista, sin acciones de edición/eliminación desde admin

### Backend

1. **No hay paginación metadata estandarizada**: Algunos endpoints devuelven `{"total": N, "data": [...]}`, otros devuelven arrays planos

2. **Webhook de pagos tiene dos rutas**: `/webhooks/mercadopago` y `/webhooks/pagos` — confuso

3. **`GET /admin/pagos` no tiene mock asociado** en el frontend

---

## Missing features (backend)

| Feature | Endpoint necesario | Estado |
|---------|-------------------|--------|
| Listar planes | `GET /planes` | ❌ No existe |
| Admin: aprobar/reembolsar pago | `PATCH /admin/pagos/{id}` | ❌ No existe |
| Admin: toggle destacado servicio | `PATCH /admin/servicios/{id}/destacar` | ❌ No existe |
| Estadísticas proveedor | `GET /proveedores/stats` | ❌ No existe |
| Chat WebSocket funcional | WS implementado pero sin frontend que lo consuma | ⚠️ Existe backend |
| Upload imágenes real (Cloudinary) | Backend listo, frontend no lo usa | ⚠️ Parcial |

---

## Missing features (frontend)

| Feature | Estado |
|---------|--------|
| Avatar upload UI | ❌ |
| Reset password screen | ❌ |
| Chat WebSocket (en vez de REST poll) | ❌ |
| Payment status polling periódico | ❌ |
| Filtro geográfico real (lat/lng) | ❌ (mock no filtra) |
| Disputas seguimiento (usuario no-admin) | ❌ |
| Notificaciones push | ❌ |
| Tests unitarios/widget | ❌ |

---

## Últimas correcciones aplicadas en esta sesión

| Fix | Archivos |
|-----|----------|
| Backend: `aceptar_propuesta` retorna `ContratacionResponse` (incluye `propuesta_id`) | `app/api/routes_propuestas.py` |
| Frontend: Eliminar `ResenaScreen` duplicado | `lib/features/solicitudes/resena_screen.dart` |
| Frontend: Eliminar `SolicitarServicioScreen` duplicado | `lib/features/solicitudes/solicitar_servicio_screen.dart` |
| Frontend: Eliminar `PerfilScreen` duplicado | `lib/features/perfil/perfil_screen_from_oportunidades.dart` |
| Frontend: Eliminar `PerfilAsScreen` duplicado | `lib/features/perfil/perfil_as_screen.dart` |
