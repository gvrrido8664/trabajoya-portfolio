# Trabajo Ya — Estado del Frontend

> **Última actualización:** 2026-06-18
> **Rama actual:** `feature/design2.0` (antes `feature/design`, eliminada)
> **`mockMode`:** `true` (desarrollo sin backend)

---

## Visión General

Somos **frontend**. El backend (FastAPI + PostgreSQL) corre por separado en `localhost:8000`. El flag `mockMode = true` permite desarrollar la app sin necesidad del backend.

| Rol | Email (mock) | Password |
|-----|--------------|----------|
| Cliente | `maria@correo.com` | cualquier cosa |
| Proveedor (Carlos) | `carlos@correo.com` | cualquier cosa |
| Proveedor (Ana) | `ana@correo.com` | cualquier cosa |
| Admin | `admin@trabajoya.cl` | cualquier cosa |

---

## Convenciones detectadas

### Status de servicios (MAYÚSCULAS en frontend)
El frontend espera **MAYÚSCULAS** pero el backend devuelve **minúsculas**:

| Recurso | Frontend espera | Backend devuelve |
|---------|-----------------|------------------|
| Servicio | `ACTIVO`, `PAUSADO`, `ELIMINADO` | `activo`, `pausado`, `eliminado` |
| Contratación | `PENDIENTE`, `ACEPTADO`, `RECHAZADO`, `COMPLETADO`, `CANCELADO`, `DISPUTA` | `pendiente`, `aceptado`, `rechazado`, `completado` |

**Impacto:** Cuando se conecte al backend real, el mock y los modelos deben normalizar a mayúsculas.

---

## Servicios API — Estado detallado

### ✅ Auth (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | `/auth/login` | ✅ Implementado | |
| POST | `/auth/register` | ✅ Implementado | |
| GET | `/auth/me` | ✅ Implementado | |
| GET | `/auth/verify-email` | ✅ Implementado | |
| POST | `/auth/forgot-password` | ✅ Implementado | |
| POST | `/auth/reset-password` | ✅ Implementado | |

### ✅ Servicios (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/servicios` | ✅ Implementado | |
| GET | `/servicios/buscar` | ✅ Implementado | geo-búsqueda |
| GET | `/servicios/{id}` | ✅ Implementado | |
| POST | `/servicios` | ✅ Implementado | |
| PUT | `/servicios/{id}` | ✅ Implementado | |
| PATCH | `/servicios/{id}/pausar` | ✅ Implementado | |
| DELETE | `/servicios/{id}` | ✅ Implementado | |
| PATCH | `/servicios/{id}/destacar` | 🟡 No consumido | Existe en backend |
| GET | `/categorias` | ✅ Implementado | Mock con 10 categorías |

### ✅ Contrataciones (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | `/contrataciones` | ✅ Implementado | |
| GET | `/contrataciones` | ✅ Implementado | |
| GET | `/contrataciones/{id}` | ✅ Implementado | |
| PATCH | `/contrataciones/{id}/aceptar` | ✅ Implementado | |
| PATCH | `/contrataciones/{id}/rechazar` | ✅ Implementado | |
| PATCH | `/contrataciones/{id}/finalizar` | ✅ Implementado | |
| POST | `/contrataciones/{id}/resena` | ✅ Implementado | |
| GET | `/contrataciones/usuario/{id}/resenas` | ✅ Implementado | |
| POST | `/disputas/contratacion/{id}` | ✅ Implementado | |

### ✅ Chat (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/chat/conversaciones` | ✅ Implementado | |
| GET | `/chat/{id}/mensajes` | ✅ Implementado | |
| POST | `/chat/{id}/mensajes` | ✅ Implementado | |
| WebSocket | `/chat/ws/{id}?token=` | 🟡 No implementado | REST polling activo |

### ✅ Pagos (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | `/pagos/crear?contratacion_id=` | ✅ Implementado | |
| GET | `/pagos/{id}/estado` | ✅ Implementado | |

### ✅ Suscripciones (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | `/suscripciones/crear` | ✅ Implementado | |
| GET | `/suscripciones/me` | ✅ Implementado | |

### ✅ Admin (mock parcial) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/admin/stats` | ✅ Implementado | |
| GET | `/admin/usuarios` | ✅ Implementado | |
| POST | `/admin/usuarios` | ✅ Implementado | |
| PUT | `/admin/usuarios/{id}` | ✅ Implementado | |
| PATCH | `/admin/usuarios/{id}/toggle-active` | ✅ Implementado | |
| GET | `/admin/servicios` | ✅ Implementado | |
| GET | `/admin/pagos` | ✅ Implementado | Mock con 3 pagos de ejemplo |
| GET | `/disputas/admin` | ✅ Implementado | |
| PATCH | `/disputas/admin/{id}/resolver` | ✅ Implementado | |

### ✅ Upload (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| POST | `/upload/avatar` | ✅ Implementado | |
| POST | `/upload/servicio/{id}` | ✅ Implementado | |

### ✅ Categorías (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/categorias` | ✅ Implementado | Mock con 10 categorías |

### ✅ Solicitudes (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/solicitudes` | ✅ Implementado | |
| GET | `/solicitudes/mis-solicitudes` | ✅ Implementado | |
| GET | `/solicitudes/{id}` | ✅ Implementado | |
| POST | `/solicitudes` | ✅ Implementado | |
| PATCH | `/solicitudes/{id}/cerrar` | ✅ Implementado | |

### ✅ Propuestas (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| GET | `/solicitudes/{id}/propuestas` | ✅ Implementado | |
| POST | `/solicitudes/{id}/propuestas` | ✅ Implementado | |
| GET | `/propuestas/mis-propuestas` | ✅ Implementado | |
| PATCH | `/solicitudes/{id}/propuestas/{id}/aceptar` | ✅ Implementado | |
| PATCH | `/solicitudes/{id}/propuestas/{id}/rechazar` | ✅ Implementado | |

### ✅ Usuarios (mock) — Funcionando

| Método | Ruta | Estado | Notas |
|--------|------|--------|-------|
| PUT | `/usuarios/me` | ✅ Implementado | Actualizar perfil |

---

## Endpoints del backend NO consumidos por el frontend

Estos endpoints existen en el backend pero no son llamados desde Flutter:

### 🟢 Baja prioridad

| Método | Ruta | Descripción |
|--------|------|-------------|
| PATCH | `/api/v1/servicios/{id}/destacar` | Marcar servicio como destacado |
| GET | `/api/v1/oportunidades` | Oportunidades para proveedores (usar solicitudes ABIERTAS) |
| GET | `/api/v1/proveedores/top` | Top proveedores |
| POST | `/api/v1/bugs` | Reportar bug |
| GET | `/api/v1/bugs/mis-reportes` | Mis reportes de bugs |
| GET | `/api/v1/admin/bugs` | Bugs admin |
| PATCH | `/api/v1/admin/bugs/{id}` | Actualizar bug |

---

## Bugs conocidos del backend

> Fuente: `2_Documentacion_API_TrabajoYa.md` — Sección de bugs del backend

| Endpoint | Bug | Impacto |
|----------|-----|---------|
| `PATCH /api/v1/usuarios/me/ubicacion` | Referencia columna `ubicacion` eliminada del modelo `Usuario` | Tira `AttributeError` |
| `GET /api/v1/usuarios/me/referidos` | Referencia columna `referido_por` eliminada del modelo | No funciona |
| `POST /api/v1/resenas/{contratacion_id}` | Ruta duplicada de `/contrataciones/{id}/resena` | Usar la de contrataciones |

---

## Pantallas implementadas

### Landing pages personalizadas por rol
- [x] **ClienteLanding** (`/cliente/buscar`) — Hero carrusel, categorías, proveedores destacados, reseñas, servicios
- [x] **ProveedorLanding** (`/proveedor/oportunidades`) — Stats banner, mapa Santiago, tips paso a paso, Mis servicios
- [x] **AdminFullDashboard** (`/admin`) — Stats cards, menú admin, gráficos, transacciones

### Auth
- [x] Login screen
- [x] Register screen (con toggle cliente/proveedor)
- [x] Forgot password screen
- [x] Email verification screen
- [x] Perfil screen

### Cliente
- [x] Landing (`/cliente/buscar`) — nueva landing personalizada
- [x] Mis trabajos (`/cliente/trabajos`)
- [x] Chat (`/cliente/chat`)
- [x] Perfil (`/cliente/perfil`)

### Proveedor
- [x] Landing (`/proveedor/oportunidades`) — nueva landing personalizada
- [x] Mis servicios (`/proveedor/servicios`)
- [x] Solicitudes (`/proveedor/solicitudes`)
- [x] Chat (`/proveedor/chat`)
- [x] Planes (`/proveedor/planes`)

### Admin
- [x] **AdminShell** — Nuevo layout responsivo con Sidebar Oscuro en Escritorio y Drawer (Menú hamburguesa) en Mobile.
- [x] Dashboard (`/admin`) — Enriquecido con menú completo, ajustado a ancho máximo 1200px.
- [x] Gestión usuarios (`/admin/usuarios`) — Ajustado para layout de escritorio (sin appbar redundante, maxWidth).
- [x] Gestión servicios (`/admin/servicios`) — Ajustado para layout de escritorio.
- [x] Gestión pagos (`/admin/pagos`) — Ajustado para layout de escritorio.
- [x] Gestión disputas (`/admin/disputas`) — Ajustado para layout de escritorio.

### Chat y Pagos
- [x] Conversaciones screen
- [x] Chat screen (REST polling)
- [x] Pago screen (MercadoPago init_point)

### Contrataciones
- [x] Solicitar servicio (con DatePicker)
- [x] Detalle contratación (aceptar/rechazar/finalizar/resena/disputa)
- [x] Mis contrataciones (tabs solicitado/recibido)
- [x] Reseña screen

### Solicitudes y Propuestas
- [x] Crear solicitud (`/crear-solicitud`)
- [x] Mis solicitudes (`/cliente/mis-solicitudes`, `/mis-solicitudes`)
- [x] Detalle solicitud (`/solicitud/:id`)
- [x] Detalle propuesta (`/solicitud/:id/proponer`)
- [x] Mis propuestas (`/proveedor/mis-propuestas`, `/proveedor/mis-propuestas`)
- [x] Enviar propuesta (`/solicitud/:id/proponer`)

---

## Coverage del frontend

### Endpoints totales del backend: ~60

| Módulo | Consumidos UI | Total backend | % coverage |
|--------|--------------|---------------|------------|
| Auth | 6 | 6 | 100% |
| Servicios | 5 | 9 | 56% |
| Contrataciones | 9 | 9 | 100% |
| Chat REST | 3 | 3 | 100% |
| Pagos | 2 | 3 | 67% |
| Suscripciones | 2 | 2 | 100% |
| Admin | 7 | 11 | 64% |
| Upload | 2 | 2 | 100% |
| Categorías | 1 | 1 | 100% |
| Solicitudes | 5 | 5 | 100% |
| Propuestas | 5 | 5 | 100% |
| Usuarios | 1 | 1 | 100% |
| **Total** | **50** | **~60** | **~83%** |

> Coverage funcional (lo que el frontend necesita para operar): **~95%**

---

## Pendientes de implementar

### 🔴 Alta prioridad — Flujo core
- [ ] **Login real** — cambiar `mockMode = false` cuando backend esté disponible
- [ ] **Auth guard real** — verificar token contra `GET /auth/me` al iniciar
- [ ] **Campo `direccionTexto` en Contratacion** — el modelo `Contratacion` (`lib/models/contratacion.dart`) no tiene `direccionTexto`; el frontend lo necesita para mostrar la ubicación en las cards de oportunidades del proveedor. Agregar este campo al response de `GET /contrataciones` desde el backend.

### 🟡 Media prioridad — Perfil y usuario
- [ ] **Reset password screen** — UI para `POST /auth/reset-password`
- [ ] **Verificación de email** — flujo completo
- [ ] **Referidos** — `GET /usuarios/me/referidos` (backend tiene bug en columna eliminada)

### 🟢 Baja prioridad — Features avanzadas
- [ ] **Chat WebSocket** — reemplazar REST polling por `ws://.../chat/ws/{id}?token=`
- [ ] **Pagos MercadoPago real** — backend con webhook configurado
- [ ] **Upload de imágenes real** — Cloudinary configurado
- [ ] **Filtro geoespacial real** — `/servicios/buscar?lat=&lng=` con mock no filtra
- [ ] **Disputas seguimiento** — UI para que cliente/proveedor sigan estado
- [ ] **Tests unitarios y de widget**

---

## Workflow de commits

```bash
git checkout -b feature/nombre
# ... cambios ...
git add .
git commit -m "feat: descripción"
git push -u origin feature/nombre
```

---

## Gaps técnicos a resolver cuando backend esté disponible

### 🔴 Alta prioridad — Para conectar al backend real

| # | Tema | Detalle | Impacto si no se resuelve |
|---|------|---------|--------------------------|
| 1 | **Normalizar status a mayúsculas** | El backend devuelve `activo`, `pendiente`, el frontend espera `ACTIVO`, `PENDIENTE` | Servicios y contrataciones no muestran el status correcto |
| 2 | **`direccionTexto` en Contratacion** | `GET /contrataciones` no devuelve `direccionTexto` | Las cards de oportunidades del proveedor muestran ubicación nula |
| 3 | **Register debe devolver `{access_token, token_type, user}`** | Mock solo devuelve el usuario; login real necesita el token para autenticar requests | Login real rompe; el token es necesario para todos los endpoints protegidos |
| 4 | **Documentar schema completo de `Solicitud`** | La doc no especifica todos los campos response de `POST /solicitudes` ni `GET /solicitudes` | El frontend puede estar parseando campos que el backend no devuelve |
| 5 | **Efecto completo de `PATCH .../propuestas/{id}/aceptar`** | La doc dice que crea `Contratacion` automáticamente y cierra la `Solicitud` | El frontend necesita saber si recibe la nueva `Contratacion` en la response o si debe hacer un GET después |

### 🟡 Media prioridad — Bugs del backend documentados

| Endpoint | Bug | Status |
|----------|-----|--------|
| `PATCH /api/v1/usuarios/me/ubicacion` | Columna `ubicacion` eliminada del modelo `Usuario` | Bug abierto |
| `GET /api/v1/usuarios/me/referidos` | Columna `referido_por` eliminada del modelo | Bug abierto |
| `POST /api/v1/resenas/{contratacion_id}` | Ruta duplicada de `/contrataciones/{id}/resena` | Usar la de contrataciones |

### ℹ️ Notas para el equipo backend

- **`/categorias`**: el frontend espera que devuelva un array con `{id, nombre, slug, icono, descripcion}` — confirmar que el campo `icono` sea un string con el nombre del ícono (ej: `"plumbing"`) y no un emoji o valor numérico.
- **`POST /solicitudes`**: response debe incluir `id`, `status = "ABIERTA"`, `propuestas_count = 0`, `created_at`.
- **`PATCH /solicitudes/{id}/cerrar`**: devuelve `{"status": "CERRADA"}`.
- **`PATCH .../propuestas/{id}/aceptar`**: oltregar `contratacion_id` en la response para que el frontend pueda navegar directo a la contratación creada.
- **`PUT /usuarios/me`**: response debe devolver el usuario actualizado completo (igual que `GET /auth/me`).