# TrabajoYa API — Documentación Técnica

> **Versión:** 1.0.0 — **Stack:** FastAPI + PostgreSQL/PostGIS + async — **Propósito:** Marketplace de servicios domésticos

---

## Índice

1. [Visión General](#1-visión-general)
2. [Instalación y Configuración](#2-instalación-y-configuración)
3. [Estructura del Proyecto](#3-estructura-del-proyecto)
4. [Autenticación](#4-autenticación)
5. [Referencia de Endpoints](#5-referencia-de-endpoints)
   - [Health Check](#51-health-check)
   - [Auth](#52-auth)
   - [Usuarios](#53-usuarios)
   - [Categorías](#54-categorías)
   - [Servicios](#55-servicios)
   - [Contrataciones](#56-contrataciones)
   - [Chat](#57-chat)
   - [Pagos](#58-pagos)
   - [Suscripciones](#59-suscripciones)
   - [Upload](#510-upload)
   - [Admin](#511-admin)
   - [Disputas](#512-disputas)
6. [Modelos de Datos](#6-modelos-de-datos)
7. [WebSocket Chat](#7-websocket-chat)
8. [Servicios Externos](#8-servicios-externos)
9. [Flujos de Estado](#9-flujos-de-estado)
10. [Tests y CI/CD](#10-tests-y-cicd)

---

## 1. Visión General

**TrabajoYa API** es un backend marketplace que conecta **clientes** que necesitan servicios domésticos con **proveedores** que los ofrecen. La plataforma gestiona desde la publicación y búsqueda geográfica de servicios hasta la contratación, pago en garantía, chat en tiempo real y resolución de disputas.

### Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Framework | **FastAPI 0.137.0** (async, OpenAPI automático) |
| ASGI Server | **Uvicorn 0.49.0** |
| Base de Datos | **PostgreSQL 16 + PostGIS 3.4** |
| ORM | **SQLAlchemy 2.0.50** (async con asyncpg) |
| Migraciones | **Alembic 1.18.4** |
| Validación | **Pydantic 2.13.4** |
| Autenticación | **JWT** (python-jose 3.5.0) + **bcrypt 4.2.1** |
| Rate Limiting | **SlowAPI** (100 req/min por defecto) |
| Logging | **structlog** (consola coloreada en dev, JSON en prod) |
| Pagos | **MercadoPago** (Checkout Pro vía API REST) |
| Archivos | **Cloudinary** (imágenes con transformaciones) |
| Email | **Resend** (transaccional, 100 emails/día gratis) |
| Notificaciones Push | **Firebase Cloud Messaging** |
| Geocodificación | **Nominatim** (OpenStreetMap) |
| Tiempo Real | **WebSockets** (Starlette) |
| Contenedores | **Docker + Docker Compose** |
| CI/CD | **GitHub Actions** |

### Arquitectura

```
                    ┌─────────────┐
                    │   Frontend   │
                    │  (Flutter)   │
                    └──────┬──────┘
                           │ HTTP / WS
                    ┌──────▼──────┐
                    │  FastAPI App │
                    │  (uvicorn)   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼─────┐ ┌───▼────┐ ┌────▼─────┐
       │ PostgreSQL  │ │ Redis  │ │Cloudinary│
       │  + PostGIS  │ │(cache) │ │(images)  │
       └────────────┘ └────────┘ └──────────┘
```

---

## 2. Instalación y Configuración

### 2.1 Requisitos

- **Docker** + **Docker Compose** (recomendado)
- O: Python 3.12+ y PostgreSQL 16+ con PostGIS

### 2.2 Variables de Entorno

```bash
# ============================================
# TrabajoYa API — Variables de Entorno
# Copiar a .env y completar con valores reales
# ============================================

# App
APP_NAME=TrabajoYa API
DEBUG=true
API_V1_PREFIX=/api/v1

# Base de Datos PostgreSQL + PostGIS
DATABASE_URL=postgresql+asyncpg://demo:demo@127.0.0.1:55432/trabajoya_demo

# JWT
JWT_SECRET_KEY=cambiar-esta-clave-secreta-en-produccion-por-una-larga-y-aleatoria
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7 días

# CORS (en producción, reemplazar * con el dominio del frontend)
CORS_ORIGINS=["*"]

# MercadoPago
MP_ACCESS_TOKEN=TEST-xxxxxxxxxxxxxxxxxxxx
MP_PUBLIC_KEY=TEST-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
MP_WEBHOOK_SECRET=tu-secreto-para-verificar-webhooks

# Firebase Cloud Messaging
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json

# Email Transaccional (Resend)
RESEND_API_KEY=re_xxxxxxxxxxxx

# Cloudinary (imágenes)
CLOUDINARY_CLOUD_NAME=tu-cloud-name
CLOUDINARY_API_KEY=xxxxxxxxxxxxxxx
CLOUDINARY_API_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxx

# URL del Frontend (para links en emails)
FRONTEND_URL=http://localhost:3000

# Geocoding (Nominatim / self-hosted)
GEOCODING_API_URL=https://nominatim.openstreetmap.org
```

### 2.3 Ejecución con Docker (recomendado)

```bash
# 1. Clonar y entrar al directorio
git clone <repo> && cd trabajoya-api

# 2. Copiar y configurar variables de entorno
cp .env.example .env

# 3. Levantar servicios
docker compose up -d

# 4. Ejecutar migraciones
docker compose exec api alembic upgrade head

# 5. (Opcional) Poblar con datos de prueba
docker compose exec api python -m app.seed

# 6. Abrir http://localhost:8000/docs (Swagger UI)
#    o http://localhost:8000/redoc (ReDoc)
```

### 2.4 Ejecución Local (sin Docker)

```bash
# 1. Crear y activar entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
.\venv\Scripts\Activate.ps1  # Windows

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar .env (apuntar DATABASE_URL a tu PostgreSQL local)

# 4. Ejecutar migraciones
alembic upgrade head

# 5. Iniciar servidor de desarrollo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2.5 Seed Data (Datos de Prueba)

El script `app/seed.py` crea:
- **20 categorías** (Plomería, Electricidad, Gasfitería, etc.)
- **15 proveedores** con servicios geo-posicionados en Santiago
- **10 clientes** (5 referidos por proveedores aleatorios)
- **1 admin**
- **15 contrataciones** de ejemplo

Credenciales de prueba:

| Rol | Email | Contraseña |
|-----|-------|-----------|
| Admin | `admin@trabajoya.cl` | `admin123` |
| Cliente | `cliente1@trabajoya.cl` | `password123` |
| Proveedor | `proveedor1@trabajoya.cl` | `password123` |

---

## 3. Estructura del Proyecto

```
trabajoya-api/
│
├── .env                    # Variables de entorno (no versionar)
├── .env.example            # Template de variables de entorno
├── .gitignore
├── .github/workflows/ci.yml
├── Dockerfile              # Imagen Docker
├── docker-compose.yml      # Servicios: api + db (postgis) + redis
├── alembic.ini             # Configuración de Alembic
├── requirements.txt        # Dependencias Python
├── pytest.ini              # Configuración de tests
│
├── app/                    # ★ Código fuente principal
│   ├── main.py             # Entrypoint FastAPI (app, middlewares, routers)
│   ├── database.py         # Engine async SQLAlchemy + sesión
│   ├── seed.py             # Poblador de base de datos
│   │
│   ├── core/               # Configuración y seguridad
│   │   ├── config.py       # Settings vía Pydantic (variables de entorno)
│   │   └── security.py     # JWT, bcrypt (hash/verify password)
│   │
│   ├── models/             # Modelos SQLAlchemy (ORM)
│   │   ├── base.py         # BaseModel (UUID PK + timestamps)
│   │   ├── usuario.py      # Usuario + RolUsuario enum
│   │   ├── categoria.py    # Categoria (jerarquía)
│   │   ├── servicio.py     # Servicio + EstadoServicio enum
│   │   ├── contratacion.py # Contratacion + EstadoContratacion enum
│   │   ├── mensaje.py      # Mensaje (chat)
│   │   ├── resena.py       # Reseña
│   │   ├── pago.py         # Pago + EstadoPago enum
│   │   ├── plan.py         # Plan de suscripción
│   │   ├── suscripcion.py  # Suscripcion + EstadoSuscripcion enum
│   │   └── disputa.py      # Disputa + EstadoDisputa enum
│   │
│   ├── schemas/            # Schemas Pydantic (request/response)
│   │   ├── auth.py         # RegistroRequest, LoginRequest, Token, UsuarioResponse
│   │   ├── usuario.py      # UsuarioUpdate, UbicacionUpdate, ProveedorResumen
│   │   ├── categoria.py    # CategoriaResponse
│   │   ├── servicio.py     # ServicioCreate, ServicioUpdate, ServicioResponse, BusquedaServicioParams
│   │   ├── contratacion.py # ContratacionCreate, ContratacionResponse, ResenaCreate, ResenaResponse
│   │   └── chat.py         # MensajeResponse, MensajeEnviar, ConversacionResumen
│   │
│   ├── api/                # ★ Handlers (rutas / controladores)
│   │   ├── dependencies.py # Dependencias: get_current_user, get_current_provider, get_current_admin
│   │   ├── routes_auth.py           # Registro, login, verificación email, reset password
│   │   ├── routes_usuarios.py       # Perfil público, actualización, ubicación, referidos
│   │   ├── routes_categorias.py     # Listar categorías (jerarquía)
│   │   ├── routes_servicios.py      # CRUD servicios + búsqueda geográfica
│   │   ├── routes_contrataciones.py # Solicitud, aceptar/rechazar, finalizar, reseñas
│   │   ├── routes_chat.py           # Chat REST + WebSocket
│   │   ├── routes_pagos.py          # Crear preferencia MP, webhook, estado
│   │   ├── routes_suscripciones.py  # Suscripción a planes premium
│   │   ├── routes_upload.py         # Subida de avatares y fotos de servicio
│   │   ├── routes_admin.py          # Dashboard, gestión de usuarios/servicios/pagos
│   │   └── routes_disputas.py       # Apertura y resolución de disputas
│   │
│   ├── services/           # Lógica de negocio (servicios externos)
│   │   ├── email_service.py        # Resend (email transaccional)
│   │   ├── payment_service.py      # MercadoPago (preferencias, webhooks, liberación)
│   │   ├── upload_service.py       # Cloudinary (imágenes)
│   │   ├── geo_service.py         # PostGIS helpers (radio search)
│   │   └── notification_service.py # Firebase Cloud Messaging (push)
│   │
│   └── chat/               # WebSocket manager
│       └── connection_manager.py   # ConnectionManager (conexiones activas)
│
├── migrations/             # Migraciones Alembic
│   ├── env.py              # Config async
│   ├── script.py.mako      # Template
│   └── versions/
│       ├── 182533923411_init.py    # Schema inicial (8 tablas)
│       └── e672bf5cf4af_disputas_y_referidos.py  # Disputas + referidos
│
└── tests/                  # Suite de tests
    ├── conftest.py         # Fixtures: db_session, client, auth_headers
    ├── test_auth.py        # 9 tests (registro, login, me, forgot-password)
    ├── test_servicios.py   # 12 tests (CRUD, geo-search, validaciones)
    └── test_contrataciones.py  # 12 tests (contratación + disputas)
```

---

## 4. Autenticación

### 4.1 Esquema

La API utiliza **JWT (JSON Web Tokens)** con el esquema `Bearer`. El token se obtiene al hacer login y debe enviarse en el header `Authorization` de todas las rutas protegidas.

### 4.2 Flujo Completo

```
1. POST /api/v1/auth/register   → Crea usuario + envía email de verificación
2. GET  /api/v1/auth/verify-email?token=... → Verifica email
3. POST /api/v1/auth/login       → Obtiene JWT (access_token)
4. GET  /api/v1/auth/me          → Perfil del usuario autenticado (requiere Bearer token)
```

### 4.3 Características del Token

| Propiedad | Valor |
|---|---|
| Algoritmo | HS256 |
| Expiración | 7 días (configurable via `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`) |
| Payload | `{"sub": "<user_id>", "exp": <timestamp>}` |
| Header requerido | `Authorization: Bearer <token>` |

### 4.4 Jerarquía de Roles

| Rol | Descripción |
|---|---|
| `cliente` | Solicita y contrata servicios |
| `proveedor` | Publica servicios y acepta contrataciones |
| `admin` | Acceso a dashboard y gestión completa del sistema |

### 4.5 Dependencias de Autorización

| Dependencia | Permite |
|---|---|
| `get_current_user` | Cualquier usuario autenticado (activo) |
| `get_current_provider` | Solo `proveedor` o `admin` |
| `get_current_admin` | Solo `admin` |

---

## 5. Referencia de Endpoints

### 5.1 Health Check

#### `GET /health`

Verifica que la API esté operativa.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "ok"
}
```
</details>

---

### 5.2 Auth

Prefijo: `/api/v1/auth`

---

#### `POST /api/v1/auth/register`

Registra un nuevo usuario. Envía email de verificación. Soporta sistema de referidos.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `ref` | `string` | Opcional. Código de referido de 8 caracteres |
| Body | — | `RegistroRequest` | Ver ejemplo abajo |

</details>

<details>
<summary>Request Body</summary>

```json
{
  "email": "juan@ejemplo.cl",
  "password": "MiPassword123",
  "nombre": "Juan",
  "apellido": "Pérez",
  "telefono": "+56912345678",
  "rol": "cliente"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "3e8a7c1b-2d4f-4a6b-8c9d-0e1f2a3b4c5d",
  "email": "juan@ejemplo.cl",
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
  "codigo_referido": "A7XK9M2P",
  "referidos_count": 0,
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `409 Conflict` | `{"detail": "El email ya está registrado"}` |
| `400 Bad Request` | `{"detail": "Rol inválido. Debe ser 'cliente' o 'proveedor'"}` |

</details>

---

#### `POST /api/v1/auth/login`

Inicia sesión y devuelve un JWT.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | — | `LoginRequest` | Email + contraseña |

</details>

<details>
<summary>Request Body</summary>

```json
{
  "email": "juan@ejemplo.cl",
  "password": "MiPassword123"
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzZThhN2MxYi0yZDRmLTRhNmItOGM5ZC0wZTFmMmEzYjRjNWQiLCJleHAiOjE3MjY0Mzg0MDB9.abc123...",
  "token_type": "bearer"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Email o contraseña incorrectos"}` |
| `403 Forbidden` | `{"detail": "Cuenta desactivada"}` |

</details>

---

#### `GET /api/v1/auth/me`

Devuelve el perfil del usuario autenticado.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "3e8a7c1b-2d4f-4a6b-8c9d-0e1f2a3b4c5d",
  "email": "juan@ejemplo.cl",
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
  "codigo_referido": "A7XK9M2P",
  "referidos_count": 0,
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `401 Unauthorized` | `{"detail": "Token inválido o expirado"}` |

</details>

---

#### `GET /api/v1/auth/verify-email`

Verifica la dirección de email mediante el token enviado por correo.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `token` | `string` | Token JWT de verificación (24h de validez) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Email verificado exitosamente"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Token inválido o expirado"}` |
| `404 Not Found` | `{"detail": "Usuario no encontrado"}` |

</details>

---

#### `POST /api/v1/auth/forgot-password`

Envía un link de restablecimiento de contraseña al email. **Siempre responde 200** para evitar enumeración de usuarios.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `email` | `string` | Email del usuario |

</details>

<details>
<summary>Request Body</summary>

```json
{
  "email": "juan@ejemplo.cl"
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Si el email existe, recibirás un link para restablecer tu contraseña"
}
```
</details>

---

#### `POST /api/v1/auth/reset-password`

Cambia la contraseña usando el token de reseteo.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `token` | `string` | Token JWT de reseteo (1h de validez) |
| Body | `new_password` | `string` | Nueva contraseña |

</details>

<details>
<summary>Request Body</summary>

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "new_password": "MiNuevaPassword456"
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Contraseña actualizada exitosamente"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Token inválido o expirado"}` |
| `404 Not Found` | `{"detail": "Usuario no encontrado"}` |

</details>

---

### 5.3 Usuarios

Prefijo: `/api/v1/usuarios`

---

#### `GET /api/v1/usuarios/{usuario_id}`

Obtiene el perfil público de un usuario por su UUID.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "3e8a7c1b-2d4f-4a6b-8c9d-0e1f2a3b4c5d",
  "email": "proveedor1@trabajoya.cl",
  "nombre": "Carlos",
  "apellido": "Muñoz",
  "telefono": "+56912345678",
  "rol": "proveedor",
  "avatar_url": "https://res.cloudinary.com/...",
  "bio": "Soy Carlos, ofrezco servicios de calidad...",
  "habilidades": "[\"Plomería\", \"Electricidad\"]",
  "is_active": true,
  "is_verified": true,
  "avg_rating": 4.5,
  "codigo_referido": "A7XK9M2P",
  "referidos_count": 3,
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `404 Not Found` | `{"detail": "Usuario no encontrado"}` |

</details>

---

#### `PUT /api/v1/usuarios/me`

Actualiza el perfil del usuario autenticado.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "nombre": "Carlos",
  "apellido": "Muñoz",
  "telefono": "+56987654321",
  "bio": "Experto en plomería con 10 años de experiencia",
  "habilidades": "[\"Plomería\", \"Gasfitería\"]",
  "avatar_url": "https://res.cloudinary.com/..."
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "3e8a7c1b-2d4f-4a6b-8c9d-0e1f2a3b4c5d",
  "email": "proveedor1@trabajoya.cl",
  "nombre": "Carlos",
  "apellido": "Muñoz",
  "telefono": "+56987654321",
  "rol": "proveedor",
  "avatar_url": "https://res.cloudinary.com/...",
  "bio": "Experto en plomería con 10 años de experiencia",
  "habilidades": "[\"Plomería\", \"Gasfitería\"]",
  "is_active": true,
  "is_verified": true,
  "avg_rating": 4.5,
  "codigo_referido": "A7XK9M2P",
  "referidos_count": 3,
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

---

#### `PATCH /api/v1/usuarios/me/ubicacion`

Actualiza la ubicación del usuario autenticado (coordenadas geográficas).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "lat": -33.4489,
  "lng": -70.6693
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Ubicación actualizada"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `422 Unprocessable` | `{"detail": [{"msg": "Latitud debe estar entre -90 y 90"}]}` |

</details>

---

#### `GET /api/v1/usuarios/me/referidos`

Obtiene estadísticas del programa de referidos del usuario autenticado.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "mi_codigo": "A7XK9M2P",
  "total_referidos": 3,
  "referidos": [
    {
      "id": "4f9b8c2d-3e5f-4a7b-9c0d-1e2f3a4b5c6d",
      "nombre": "Andrea",
      "apellido": "Herrera",
      "email_verificado": true,
      "created_at": "2026-06-15T10:00:00Z"
    }
  ]
}
```
</details>

---

### 5.4 Categorías

Prefijo: `/api/v1/categorias`

---

#### `GET /api/v1/categorias`

Lista las categorías raíz (sin `parent_id`). Opcionalmente filtra por subcategorías.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `parent_id` | `string` | UUID de la categoría padre (opcional) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "a1b2c3d4-...",
    "nombre": "Plomería",
    "slug": "plomeria",
    "icono": "🔧",
    "descripcion": "Reparación e instalación de tuberías...",
    "parent_id": null
  },
  {
    "id": "b2c3d4e5-...",
    "nombre": "Electricidad",
    "slug": "electricidad",
    "icono": "⚡",
    "descripcion": "Instalaciones eléctricas...",
    "parent_id": null
  }
]
```
</details>

---

#### `GET /api/v1/categorias/{slug}`

Obtiene una categoría por su slug.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "a1b2c3d4-...",
  "nombre": "Plomería",
  "slug": "plomeria",
  "icono": "🔧",
  "descripcion": "Reparación e instalación de tuberías...",
  "parent_id": null
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `404 Not Found` | `{"detail": "Categoría no encontrada"}` |

</details>

---

### 5.5 Servicios

Prefijo: `/api/v1/servicios`

---

#### `POST /api/v1/servicios`

Crea un nuevo servicio (requiere rol `proveedor` o `admin`).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomería a domicilio",
  "descripcion": "Reparación de llaves, tuberías y calefont con garantía",
  "precio_min": 15000,
  "precio_max": 80000,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Región Metropolitana",
  "fotos": "[\"https://res.cloudinary.com/...\", \"https://res.cloudinary.com/...\"]"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "proveedor_id": "3e8a7c1b-...",
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomería a domicilio",
  "descripcion": "Reparación de llaves, tuberías y calefont con garantía",
  "precio_min": 15000.0,
  "precio_max": 80000.0,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Región Metropolitana",
  "fotos": "[\"https://res.cloudinary.com/...\"]",
  "status": "activo",
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "Se requiere rol de proveedor"}` |
| `422 Unprocessable` | Precio negativo o radio <= 0 |

</details>

---

#### `GET /api/v1/servicios`

Lista servicios activos. Filtrable por categoría y proveedor. Excluye servicios `ELIMINADO`.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `categoria_id` | `string` | UUID de categoría (opcional) |
| Query | `proveedor_id` | `string` | UUID de proveedor (opcional) |
| Query | `skip` | `int` | Paginación (default: 0) |
| Query | `limit` | `int` | Máx. 100 (default: 20) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "c3d4e5f6-...",
    "proveedor_id": "3e8a7c1b-...",
    "proveedor_nombre": "Carlos Muñoz",
    "proveedor_rating": 4.5,
    "categoria_id": "a1b2c3d4-...",
    "titulo": "Plomería a domicilio",
    "descripcion": "Reparación de llaves, tuberías...",
    "precio_min": 15000.0,
    "precio_max": 80000.0,
    "radio_cobertura_km": 15,
    "direccion_texto": "Santiago, Región Metropolitana",
    "fotos": "[\"https://...\"]",
    "status": "activo",
    "created_at": "2026-06-16T12:00:00Z",
    "updated_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

#### `GET /api/v1/servicios/buscar`

Búsqueda geoespacial: encuentra servicios activos dentro de un radio (en km) desde un punto geográfico. Resultados ordenados por distancia.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `lat` | `float` | **Requerido.** Latitud (-90 a 90) |
| Query | `lng` | `float` | **Requerido.** Longitud (-180 a 180) |
| Query | `radio_km` | `float` | Radio en km (default: 10, debe ser > 0) |
| Query | `categoria_id` | `string` | UUID de categoría (opcional) |
| Query | `skip` | `int` | Paginación (default: 0) |
| Query | `limit` | `int` | Máx. 100 (default: 20) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "c3d4e5f6-...",
    "proveedor_id": "3e8a7c1b-...",
    "proveedor_nombre": "Carlos Muñoz",
    "proveedor_rating": 4.5,
    "categoria_id": "a1b2c3d4-...",
    "titulo": "Plomería a domicilio",
    "descripcion": "Reparación de llaves...",
    "precio_min": 15000.0,
    "precio_max": 80000.0,
    "radio_cobertura_km": 15,
    "direccion_texto": "Santiago, Región Metropolitana",
    "fotos": "[\"https://...\"]",
    "status": "activo",
    "created_at": "2026-06-16T12:00:00Z",
    "updated_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

#### `GET /api/v1/servicios/{servicio_id}`

Obtiene detalle de un servicio por UUID (excluye `ELIMINADO`).

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "proveedor_id": "3e8a7c1b-...",
  "proveedor_nombre": "Carlos Muñoz",
  "proveedor_rating": 4.5,
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomería a domicilio",
  "descripcion": "Reparación de llaves, tuberías...",
  "precio_min": 15000.0,
  "precio_max": 80000.0,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Región Metropolitana",
  "fotos": "[\"https://...\"]",
  "status": "activo",
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `404 Not Found` | `{"detail": "Servicio no encontrado"}` |

</details>

---

#### `PUT /api/v1/servicios/{servicio_id}`

Actualiza un servicio (solo el proveedor propietario).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "titulo": "Plomería express zona oriente",
  "precio_min": 20000,
  "precio_max": 100000,
  "radio_cobertura_km": 20
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "proveedor_id": "3e8a7c1b-...",
  "categoria_id": "a1b2c3d4-...",
  "titulo": "Plomería express zona oriente",
  "descripcion": "Reparación de llaves, tuberías...",
  "precio_min": 20000.0,
  "precio_max": 100000.0,
  "radio_cobertura_km": 20,
  "direccion_texto": "Santiago, Región Metropolitana",
  "fotos": "[\"https://...\"]",
  "status": "activo",
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "No puedes editar un servicio ajeno"}` |
| `404 Not Found` | `{"detail": "Servicio no encontrado"}` |

</details>

---

#### `PATCH /api/v1/servicios/{servicio_id}/pausar`

Alterna el estado del servicio entre `activo` y `pausado` (solo el propietario).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "pausado"
}
```
</details>

---

#### `DELETE /api/v1/servicios/{servicio_id}`

Eliminación lógica: cambia el estado a `ELIMINADO` (solo el propietario).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Response <code>204 No Content</code></summary>

Sin cuerpo de respuesta.
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "No puedes eliminar un servicio ajeno"}` |

</details>

---

### 5.6 Contrataciones

Prefijo: `/api/v1/contrataciones`

---

#### `POST /api/v1/contrataciones`

Crea una solicitud de contratación (solo rol `cliente`). No se puede contratar el propio servicio.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "servicio_id": "c3d4e5f6-...",
  "monto_acordado": 45000,
  "mensaje_solicitud": "Hola, necesito arreglar una llave que gotea. ¿Tienes disponibilidad esta semana?",
  "fecha_programada": "2026-06-20T15:00:00Z"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "d4e5f6a7-...",
  "cliente_id": "4f9b8c2d-...",
  "proveedor_id": "3e8a7c1b-...",
  "servicio_id": "c3d4e5f6-...",
  "status": "pendiente",
  "monto_acordado": 45000.0,
  "mensaje_solicitud": "Hola, necesito arreglar una llave que gotea...",
  "fecha_programada": "2026-06-20T15:00:00Z",
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "Solo clientes pueden solicitar servicios"}` |
| `400 Bad Request` | `{"detail": "No puedes contratar tu propio servicio"}` |
| `404 Not Found` | `{"detail": "Servicio no encontrado o inactivo"}` |

</details>

---

#### `GET /api/v1/contrataciones`

Lista las contrataciones del usuario autenticado (como cliente o proveedor). Incluye nombres y título del servicio.

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "d4e5f6a7-...",
    "cliente_id": "4f9b8c2d-...",
    "proveedor_id": "3e8a7c1b-...",
    "servicio_id": "c3d4e5f6-...",
    "status": "pendiente",
    "monto_acordado": 45000.0,
    "mensaje_solicitud": "Hola, necesito arreglar una llave...",
    "fecha_programada": "2026-06-20T15:00:00Z",
    "cliente_nombre": "Andrea Herrera",
    "proveedor_nombre": "Carlos Muñoz",
    "servicio_titulo": "Plomería a domicilio",
    "created_at": "2026-06-16T12:00:00Z",
    "updated_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

#### `GET /api/v1/contrataciones/{contratacion_id}`

Obtiene detalle de una contratación (solo participantes).

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "d4e5f6a7-...",
  "cliente_id": "4f9b8c2d-...",
  "proveedor_id": "3e8a7c1b-...",
  "servicio_id": "c3d4e5f6-...",
  "status": "pendiente",
  "monto_acordado": 45000.0,
  "mensaje_solicitud": "Hola, necesito arreglar una llave...",
  "fecha_programada": "2026-06-20T15:00:00Z",
  "cliente_nombre": "Andrea Herrera",
  "proveedor_nombre": "Carlos Muñoz",
  "servicio_titulo": "Plomería a domicilio",
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "No tienes acceso a esta contratación"}` |
| `404 Not Found` | `{"detail": "Contratación no encontrada"}` |

</details>

---

#### `PATCH /api/v1/contrataciones/{contratacion_id}/aceptar`

El proveedor acepta una contratación pendiente.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token> (rol proveedor)
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "aceptado"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "La contratación ya fue respondida"}` |

</details>

---

#### `PATCH /api/v1/contrataciones/{contratacion_id}/rechazar`

El proveedor rechaza una contratación pendiente.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "rechazado"
}
```
</details>

---

#### `PATCH /api/v1/contrataciones/{contratacion_id}/finalizar`

Cualquiera de las partes marca la contratación como completada. Solo válido desde estados `ACEPTADO` o `EN_PROGRESO`.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "completado"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Estado no válido para finalizar"}` |

</details>

---

#### `POST /api/v1/contrataciones/{contratacion_id}/resena`

Deja una reseña sobre una contratación completada. Una reseña por contratación. Actualiza el `avg_rating` del usuario calificado.

<details>
<summary>Request Body</summary>

```json
{
  "puntuacion": 5,
  "comentario": "Excelente servicio, muy puntual y profesional"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "e5f6a7b8-...",
  "contratacion_id": "d4e5f6a7-...",
  "calificador_id": "4f9b8c2d-...",
  "calificado_id": "3e8a7c1b-...",
  "puntuacion": 5,
  "comentario": "Excelente servicio, muy puntual y profesional",
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Solo se puede reseñar una contratación completada"}` |
| `409 Conflict` | `{"detail": "Ya existe una reseña para esta contratación"}` |

</details>

---

#### `GET /api/v1/contrataciones/usuario/{usuario_id}/resenas`

Lista las reseñas recibidas por un usuario (público).

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "e5f6a7b8-...",
    "contratacion_id": "d4e5f6a7-...",
    "calificador_id": "4f9b8c2d-...",
    "calificado_id": "3e8a7c1b-...",
    "puntuacion": 5,
    "comentario": "Excelente servicio, muy puntual y profesional",
    "created_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

### 5.7 Chat

Prefijo: `/api/v1/chat`

---

#### `WebSocket /api/v1/chat/ws/{contratacion_id}?token=<jwt>`

Conexión WebSocket para chat en tiempo real. El token JWT se envía como query parameter.

<details>
<summary>Conexión</summary>

```
ws://localhost:8000/api/v1/chat/ws/d4e5f6a7-...?token=eyJhbGciOiJIUzI1NiIs...
```
</details>

<details>
<summary>Formato de mensaje (cliente → servidor)</summary>

```json
{
  "contenido": "Hola, ¿qué tal?"
}
```
</details>

<details>
<summary>Formato de mensaje (servidor → clientes)</summary>

```json
{
  "id": "f6a7b8c9-...",
  "contratacion_id": "d4e5f6a7-...",
  "emisor_id": "4f9b8c2d-...",
  "contenido": "Hola, ¿qué tal?",
  "leido": false,
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

<details>
<summary>Códigos de cierre</summary>

| Código | Significado |
|--------|-------------|
| `4001` | Token inválido/expirado |
| `4003` | No eres participante de esta contratación |
| `4004` | Contratación no encontrada |

</details>

---

#### `POST /api/v1/chat/{contratacion_id}/mensajes`

Envía un mensaje vía REST (alternativa al WebSocket).

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Request Body</summary>

```json
{
  "contenido": "Hola, ¿qué tal?"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "f6a7b8c9-...",
  "contratacion_id": "d4e5f6a7-...",
  "emisor_id": "4f9b8c2d-...",
  "contenido": "Hola, ¿qué tal?",
  "leido": false,
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

---

#### `GET /api/v1/chat/{contratacion_id}/mensajes`

Historial de mensajes de una contratación. Paginado, ordenado del más reciente al más antiguo.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `skip` | `int` | Paginación (default: 0) |
| Query | `limit` | `int` | Máx. 200 (default: 50) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "f6a7b8c9-...",
    "contratacion_id": "d4e5f6a7-...",
    "emisor_id": "4f9b8c2d-...",
    "contenido": "Hola, ¿qué tal?",
    "leido": false,
    "created_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

#### `GET /api/v1/chat/conversaciones`

Lista las conversaciones activas del usuario (deduplicadas por par de usuarios). Incluye vista previa del último mensaje, contador de no leídos y estado de la contratación.

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "contratacion_id": "d4e5f6a7-...",
    "otro_usuario_id": "3e8a7c1b-...",
    "otro_usuario_nombre": "Carlos Muñoz",
    "ultimo_mensaje": "Hola, ¿qué tal?",
    "ultimo_mensaje_fecha": "2026-06-16T12:00:00Z",
    "mensajes_no_leidos": 2,
    "status_contratacion": "aceptado"
  }
]
```
</details>

---

### 5.8 Pagos

Prefijo: `/api/v1/pagos`

---

#### `POST /api/v1/pagos/crear`

Crea una preferencia de pago en MercadoPago para una contratación aceptada. Solo el cliente puede iniciar el pago. Se requiere `contratacion_id` como query parameter.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token> (rol cliente)
```
</details>

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `contratacion_id` | `string` | UUID de la contratación aceptada |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "123456789-...",
  "init_point": "https://www.mercadopago.cl/checkout/v1/redirect?...",
  "sandbox_init_point": "https://sandbox.mercadopago.cl/checkout/v1/redirect?...",
  "external_reference": "d4e5f6a7-...",
  "status": "pending"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `403 Forbidden` | `{"detail": "Solo el cliente puede iniciar el pago"}` |
| `400 Bad Request` | `{"detail": "La contratación debe estar aceptada para pagar"}` |

</details>

---

#### `POST /api/v1/pagos/webhooks/pagos`

**Endpoint público** (sin autenticación). Webhook de MercadoPago para recibir notificaciones de pago. Procesa la aprobación y aplica la comisión del 10%.

<details>
<summary>Request Body (MercadoPago notification)</summary>

```json
{
  "action": "payment.created",
  "data": {
    "id": 1234567890
  }
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "procesado"
}
```
</details>

---

#### `GET /api/v1/pagos/{contratacion_id}/estado`

Consulta el estado del pago de una contratación.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "aprobado",
  "monto": 45000.0,
  "fee_plataforma": 4500.0,
  "monto_neto": 40500.0
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `404 Not Found` | `{"detail": "No hay pago registrado"}` |
| `403 Forbidden` | `{"detail": "No tienes acceso a este pago"}` |

</details>

---

### 5.9 Suscripciones

Prefijo: `/api/v1/suscripciones`

---

#### `POST /api/v1/suscripciones/crear`

Crea una suscripción a un plan premium (solo `proveedor`). Devuelve la preferencia de pago de MercadoPago.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token> (rol proveedor)
```
</details>

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `plan_slug` | `string` | Slug del plan (ej: "basico", "pro") |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "pref-12345...",
  "init_point": "https://www.mercadopago.cl/checkout/...",
  "status": "pending"
}
```
</details>

---

#### `GET /api/v1/suscripciones/me`

Consulta el estado de la suscripción actual del proveedor.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "tiene_suscripcion": true,
  "plan_slug": "a1b2c3d4-...",
  "status": "activa",
  "fecha_inicio": "2026-06-01T00:00:00Z",
  "fecha_fin": "2026-07-01T00:00:00Z"
}
```
</details>

---

### 5.10 Upload

Prefijo: `/api/v1/upload`

---

#### `POST /api/v1/upload/avatar`

Sube una imagen de avatar. **5 MB máx.** Formatos: JPEG, PNG, WebP. Genera thumbnail de 400×400 con enfoque facial.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```
</details>

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `file` | `file` | Archivo de imagen (multipart/form-data) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "url": "https://res.cloudinary.com/trabajoya/image/upload/v1/usuarios/3e8a7c1b.../avatar"
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Formato no permitido. Usa JPEG, PNG o WebP"}` |
| `400 Bad Request` | `{"detail": "El archivo excede el tamaño máximo de 5 MB"}` |

</details>

---

#### `POST /api/v1/upload/servicio/{servicio_id}`

Sube una foto de servicio. **10 MB máx.** Máx. 5 fotos por servicio. Redimensiona a 1200×800 como máximo.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "url": "https://res.cloudinary.com/.../servicios/c3d4e5f6.../foto_0.jpg",
  "fotos": [
    "https://res.cloudinary.com/.../foto_0.jpg",
    "https://res.cloudinary.com/.../foto_1.jpg"
  ]
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `400 Bad Request` | `{"detail": "Máximo 5 fotos por servicio"}` |

</details>

---

#### `DELETE /api/v1/upload/{public_id}`

Elimina un archivo subido mediante su `public_id` de Cloudinary.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Archivo eliminado"
}
```
</details>

---

### 5.11 Admin

Prefijo: `/api/v1/admin` — **Todas requieren rol `admin`**

---

#### `GET /api/v1/admin/stats`

Dashboard con métricas generales del sistema.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "usuarios": {
    "total": 26,
    "proveedores": 15,
    "clientes": 10
  },
  "servicios_activos": 25,
  "contrataciones": {
    "este_mes": 12,
    "completadas_total": 45
  },
  "volumen_transaccionado_mes": 1250000.00,
  "contrataciones_por_mes": [
    {"mes": "2026-01", "total": 8},
    {"mes": "2026-02", "total": 10},
    {"mes": "2026-03", "total": 15},
    {"mes": "2026-04", "total": 12},
    {"mes": "2026-05", "total": 14},
    {"mes": "2026-06", "total": 12}
  ],
  "top_categorias": [
    {"nombre": "Plomería", "total": 8},
    {"nombre": "Electricidad", "total": 6}
  ],
  "top_proveedores": [
    {"nombre": "Carlos Muñoz", "rating": 4.9, "total_contratos": 12}
  ]
}
```
</details>

---

#### `GET /api/v1/admin/usuarios`

Lista todos los usuarios. Filtrable por rol y email. Paginado.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `skip` | `int` | (default: 0) |
| Query | `limit` | `int` | Máx. 200 (default: 50) |
| Query | `rol` | `string` | `cliente`, `proveedor` o `admin` |
| Query | `email` | `string` | Búsqueda parcial por email |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "total": 26,
  "skip": 0,
  "limit": 50,
  "data": [
    {
      "id": "3e8a7c1b-...",
      "email": "proveedor1@trabajoya.cl",
      "nombre": "Carlos",
      "apellido": "Muñoz",
      "rol": "proveedor",
      "is_active": true,
      "email_verificado": true,
      "avg_rating": 4.5,
      "created_at": "2026-06-16T12:00:00Z"
    }
  ]
}
```
</details>

---

#### `POST /api/v1/admin/usuarios`

Crea un usuario (auto-verificado, bypass de email).

<details>
<summary>Request Body</summary>

```json
{
  "email": "nuevo@ejemplo.cl",
  "password": "Password123",
  "nombre": "Nuevo",
  "apellido": "Usuario",
  "rol": "proveedor",
  "telefono": "+56912345678"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "a1b2c3d4-...",
  "email": "nuevo@ejemplo.cl",
  "nombre": "Nuevo",
  "apellido": "Usuario",
  "rol": "proveedor",
  "is_active": true
}
```
</details>

---

#### `PATCH /api/v1/admin/usuarios/{usuario_id}/toggle-active`

Activa o desactiva un usuario (toggle).

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "3e8a7c1b-...",
  "is_active": false
}
```
</details>

---

#### `PUT /api/v1/admin/usuarios/{usuario_id}`

Actualiza cualquier campo de un usuario.

<details>
<summary>Request Body</summary>

```json
{
  "email": "actualizado@ejemplo.cl",
  "nombre": "Actualizado",
  "rol": "cliente",
  "is_active": true
}
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "3e8a7c1b-...",
  "email": "actualizado@ejemplo.cl",
  "nombre": "Actualizado",
  "apellido": "Muñoz",
  "telefono": "+56912345678",
  "rol": "cliente",
  "is_active": true,
  "email_verificado": true,
  "avg_rating": 4.5
}
```
</details>

---

#### `GET /api/v1/admin/servicios`

Lista todos los servicios (incluyendo eliminados). Filtrable por estado.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "total": 30,
  "data": [
    {
      "id": "c3d4e5f6-...",
      "titulo": "Plomería a domicilio",
      "proveedor_id": "3e8a7c1b-...",
      "categoria_id": "a1b2c3d4-...",
      "status": "activo",
      "precio_min": 15000.0,
      "precio_max": 80000.0,
      "created_at": "2026-06-16T12:00:00Z"
    }
  ]
}
```
</details>

---

#### `GET /api/v1/admin/pagos`

Lista todos los pagos. Incluye volumen total y fees acumulados.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "total": 20,
  "volumen_total_aprobado": 850000.00,
  "fees_totales": 85000.00,
  "data": [
    {
      "id": "b2c3d4e5-...",
      "contratacion_id": "d4e5f6a7-...",
      "monto": 45000.0,
      "fee_plataforma": 4500.0,
      "monto_neto": 40500.0,
      "status": "aprobado",
      "gateway": "mercadopago",
      "created_at": "2026-06-16T12:00:00Z"
    }
  ]
}
```
</details>

---

### 5.12 Disputas

Prefijo: `/api/v1/disputas`

---

#### `POST /api/v1/disputas/contratacion/{contratacion_id}`

Abre una disputa sobre una contratación. Solo los participantes. Estados válidos: `ACEPTADO`, `PAGADO_GARANTIA`, `EN_PROGRESO`. Una disputa por contratación.

<details>
<summary>Headers</summary>

```
Authorization: Bearer <token>
```
</details>

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `motivo` | `string` | **Requerido.** Descripción del problema |
| Body | `evidencias` | `string` | JSON con links a pruebas (opcional) |

</details>

<details>
<summary>Request Body</summary>

```json
{
  "motivo": "El proveedor no completó el trabajo acordado y no responde los mensajes",
  "evidencias": "[\"https://res.cloudinary.com/...\", \"https://ejemplo.cl/fotos/...\"]"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "status": "abierta",
  "motivo": "El proveedor no completó el trabajo acordado..."
}
```
</details>

<details>
<summary>Errores</summary>

| Código | Descripción |
|--------|-------------|
| `409 Conflict` | `{"detail": "Ya existe una disputa para esta contratación"}` |
| `400 Bad Request` | `{"detail": "No se puede abrir disputa en este estado"}` |

</details>

---

#### `GET /api/v1/disputas/admin`

Lista todas las disputas (solo admin). Filtrable por estado.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "total": 3,
  "data": [
    {
      "id": "c3d4e5f6-...",
      "contratacion_id": "d4e5f6a7-...",
      "abridor_id": "4f9b8c2d-...",
      "motivo": "El proveedor no completó el trabajo...",
      "evidencias": "[\"https://...\"]",
      "status": "abierta",
      "resolucion": null,
      "created_at": "2026-06-16T12:00:00Z"
    }
  ]
}
```
</details>

---

#### `PATCH /api/v1/disputas/admin/{disputa_id}/resolver`

Resuelve una disputa (solo admin). Acción: `reembolsar` (devuelve el dinero al cliente) o `liberar` (libera el pago al proveedor).

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Body | `resolucion` | `string` | Notas del admin sobre la resolución |
| Query | `accion` | `string` | `"reembolsar"` o `"liberar"` |

</details>

<details>
<summary>Request Body + Query</summary>

```json
{
  "resolucion": "Se libera el pago al proveedor por cumplimiento parcial"
}
```
```
?accion=liberar
```
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "status": "resuelta",
  "accion": "liberar"
}
```
</details>

---

## 6. Modelos de Datos

### 6.1 Diagrama de Entidad-Relación

```
usuarios (1) ─────< servicios (N)       ┌─ resenas (1:1 con contratacion)
usuarios (1) ─────< contrataciones (N) ──┤
usuarios (1) ─────< mensajes (N)          ├─ pagos (1:1 con contratacion)
usuarios (1) ─────< disputas (N)          └─ disputas (1:1 con contratacion)
usuarios (1) ─────> usuarios (N)   [referido_por / referidos]
categorias (1) ───< servicios (N)
planes (1) ───────< suscripciones (N)
usuarios (1) ─────< suscripciones (N)
```

### 6.2 Tabla: `usuarios`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK, `uuid4` | Identificador único |
| `email` | `VARCHAR(255)` | UNIQUE, NOT NULL, INDEX | Email del usuario |
| `password_hash` | `VARCHAR(255)` | NOT NULL | Hash bcrypt de la contraseña |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre |
| `apellido` | `VARCHAR(100)` | NOT NULL | Apellido |
| `telefono` | `VARCHAR(20)` | NULLABLE | Teléfono de contacto |
| `rol` | `ENUM` | NOT NULL, default `cliente` | `cliente`, `proveedor`, `admin` |
| `ubicacion` | `GEOGRAPHY(POINT, 4326)` | NULLABLE | Ubicación geográfica (PostGIS) |
| `avatar_url` | `VARCHAR(500)` | NULLABLE | URL del avatar en Cloudinary |
| `bio` | `TEXT` | NULLABLE | Biografía o descripción |
| `habilidades` | `TEXT` | NULLABLE | JSON array de habilidades |
| `is_active` | `BOOLEAN` | NOT NULL, default `true` | Si la cuenta está activa |
| `is_verified` | `BOOLEAN` | NOT NULL, default `false` | Si el usuario fue verificado por admin |
| `email_verificado` | `BOOLEAN` | NOT NULL, default `false` | Si el email fue verificado |
| `ultima_conexion` | `DATETIME(tz)` | NULLABLE | Timestamp de última conexión |
| `avg_rating` | `FLOAT` | NOT NULL, default `0.0` | Rating promedio (calculado de reseñas) |
| `codigo_referido` | `VARCHAR(20)` | UNIQUE, INDEX | Código único del programa de referidos |
| `referido_por` | `UUID` | FK → `usuarios.id`, NULLABLE | Usuario que refirió a este |
| `referidos_count` | `INTEGER` | NOT NULL, default `0` | Contador de referidos exitosos |
| `created_at` | `DATETIME(tz)` | NOT NULL, server_default `now()` | Fecha de creación |
| `updated_at` | `DATETIME(tz)` | NOT NULL, onupdate `now()` | Última actualización |

### 6.3 Tabla: `categorias`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre visible |
| `slug` | `VARCHAR(100)` | UNIQUE, NOT NULL, INDEX | Slug URL (ej: `plomeria`) |
| `icono` | `VARCHAR(50)` | NULLABLE | Emoji o icono |
| `descripcion` | `TEXT` | NULLABLE | Descripción de la categoría |
| `parent_id` | `UUID` | NULLABLE, INDEX | FK a sí misma (jerarquía) |

### 6.4 Tabla: `servicios`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Proveedor que ofrece el servicio |
| `categoria_id` | `UUID` | FK → `categorias.id`, NOT NULL, INDEX | Categoría del servicio |
| `titulo` | `VARCHAR(200)` | NOT NULL | Título del servicio |
| `descripcion` | `TEXT` | NOT NULL | Descripción detallada |
| `precio_min` | `FLOAT` | NULLABLE | Precio mínimo estimado |
| `precio_max` | `FLOAT` | NULLABLE | Precio máximo estimado |
| `ubicacion` | `GEOGRAPHY(POINT, 4326)` | NULLABLE | Ubicación del servicio (PostGIS) |
| `radio_cobertura_km` | `INTEGER` | NOT NULL, default `10` | Radio de cobertura en km |
| `direccion_texto` | `VARCHAR(500)` | NULLABLE | Dirección en texto legible |
| `status` | `ENUM` | NOT NULL, default `activo` | `activo`, `pausado`, `eliminado` |
| `fotos` | `TEXT` | NULLABLE | JSON array de URLs de fotos |

### 6.5 Tabla: `contrataciones`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `cliente_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Cliente que solicita |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Proveedor que ofrece |
| `servicio_id` | `UUID` | FK → `servicios.id`, NOT NULL, INDEX | Servicio contratado |
| `status` | `ENUM` | NOT NULL, default `pendiente` | Ver [flujo de estados](#91-contratación) |
| `monto_acordado` | `FLOAT` | NULLABLE | Monto acordado entre las partes |
| `mensaje_solicitud` | `TEXT` | NULLABLE | Mensaje inicial del cliente |
| `fecha_programada` | `DATETIME(tz)` | NULLABLE | Fecha programada para el servicio |

### 6.6 Tabla: `mensajes`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, NOT NULL, INDEX | Contratación asociada |
| `emisor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Quién envía el mensaje |
| `contenido` | `TEXT` | NOT NULL | Contenido del mensaje |
| `leido` | `BOOLEAN` | NOT NULL, default `false` | Si el mensaje fue leído |

### 6.7 Tabla: `pagos`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL, INDEX | Contratación asociada (1:1) |
| `cliente_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Pagador |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Cobrador |
| `monto` | `FLOAT` | NOT NULL | Monto total de la transacción |
| `fee_plataforma` | `FLOAT` | NOT NULL, default `0.0` | Comisión de la plataforma (10%) |
| `monto_neto` | `FLOAT` | NOT NULL, default `0.0` | Monto neto para el proveedor |
| `status` | `ENUM` | NOT NULL, default `pendiente` | Ver [flujo de estados](#92-pago) |
| `gateway` | `VARCHAR(50)` | NOT NULL, default `mercadopago` | Nombre del gateway |
| `gateway_payment_id` | `VARCHAR(255)` | NULLABLE | ID del pago en el gateway |
| `gateway_preference_id` | `VARCHAR(255)` | NULLABLE | ID de la preferencia en el gateway |

### 6.8 Tabla: `resenas`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL | Contratación asociada (1:1) |
| `calificador_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Quién califica |
| `calificado_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Quién recibe la calificación |
| `puntuacion` | `INTEGER` | NOT NULL | Puntuación (1–5) |
| `comentario` | `TEXT` | NULLABLE | Comentario de la reseña |

### 6.9 Tabla: `planes`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre del plan (ej: "Básico", "Pro") |
| `slug` | `VARCHAR(100)` | UNIQUE, NOT NULL | Slug URL |
| `precio_mensual` | `FLOAT` | NOT NULL | Precio mensual en CLP |
| `precio_anual` | `FLOAT` | NOT NULL | Precio anual en CLP |
| `features` | `VARCHAR(1000)` | NOT NULL | JSON array de características |

### 6.10 Tabla: `suscripciones`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Proveedor suscrito |
| `plan_id` | `UUID` | FK → `planes.id`, NOT NULL | Plan contratado |
| `status` | `ENUM` | NOT NULL, default `pendiente` | `activa`, `cancelada`, `expirada`, `pendiente` |
| `fecha_inicio` | `DATETIME(tz)` | NOT NULL | Inicio de la suscripción |
| `fecha_fin` | `DATETIME(tz)` | NULLABLE | Fin de la suscripción |
| `gateway_subscription_id` | `VARCHAR(255)` | NULLABLE | ID de suscripción en el gateway |
| `gateway_payment_id` | `VARCHAR(255)` | NULLABLE | ID de pago en el gateway |

### 6.11 Tabla: `disputas`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL | Contratación asociada (1:1) |
| `abridor_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Quién abre la disputa |
| `motivo` | `TEXT` | NOT NULL | Descripción del problema |
| `evidencias` | `TEXT` | NULLABLE | JSON array con enlaces a pruebas |
| `status` | `ENUM` | NOT NULL, default `abierta` | `abierta`, `en_revision`, `resuelta` |
| `resolucion` | `TEXT` | NULLABLE | Notas del admin al resolver |

---

## 7. WebSocket Chat

### 7.1 Conexión

```
ws://localhost:8000/api/v1/chat/ws/{contratacion_id}?token={jwt_token}
```

### 7.2 Autenticación

El token JWT se envía como **query parameter** (`token`). El servidor valida que:
1. El token sea válido y no esté expirado
2. El usuario autenticado sea participante de la contratación (`cliente_id` o `proveedor_id`)

### 7.3 Protocolo

| Dirección | Formato | Descripción |
|-----------|---------|-------------|
| Cliente → Servidor | `{"contenido": "texto"}` | Texto plano, se guarda en BD y reenvía |
| Servidor → Cliente emisor | `{"id":..., "emisor_id":..., "contenido":..., ...}` | Eco de confirmación |
| Servidor → Otro participante | `{"id":..., "emisor_id":..., "contenido":..., ...}` | Mensaje en tiempo real |

### 7.4 ConnectionManager

El `ConnectionManager` (`app/chat/connection_manager.py`) mantiene un diccionario `{user_id: [WebSocket, ...]}` que permite:
- Enviar mensajes a todas las conexiones activas de un usuario
- Broadcast global (con opción de excluir a un usuario)

---

## 8. Servicios Externos

### 8.1 MercadoPago (Pagos)

| Propiedad | Valor |
|-----------|-------|
| SDK | API REST via `httpx` (sin SDK oficial) |
| Comisión | **10%** (`fee_plataforma`) sobre el monto |
| Webhook | `POST /api/v1/pagos/webhooks/pagos` |
| Moneda | **CLP** (Peso chileno) |
| Modo | Sandbox/Producción según token |

**Flujo típico:**

```
1. Proveedor acepta contratación → estado ACEPTADO
2. Cliente crea preferencia → recibe init_point de MP
3. Cliente paga en checkout de MP → webhook notifica
4. Webhook procesa → contrato pasa a PAGADO_GARANTIA, se crea Pago APROBADO
5. Trabajo completado → admin resuelve disputa o se libera el pago
```

### 8.2 Cloudinary (Archivos)

| Propiedad | Valor |
|-----------|-------|
| Avatar máx | 5 MB, 400×400 thumb, face gravity |
| Foto servicio máx | 10 MB, 1200×800 limit |
| Formatos | JPEG, PNG, WebP |
| Máx fotos/servicio | 5 |

### 8.3 Resend (Email Transaccional)

| Propiedad | Valor |
|-----------|-------|
| Free tier | 100 emails/día |
| Remitente | `TrabajoYa <noreply@trabajoya.cl>` |
| Tipos | Verificación, bienvenida, reset password |
| Fallback | Si no hay API key, imprime en consola (dev) |

### 8.4 Firebase Cloud Messaging (Push)

| Propiedad | Valor |
|-----------|-------|
| Auth | OAuth2 con credenciales JSON |
| Estado | Implementación base (no bloqueante) |
| Fallback | Retorna `None` si no hay configuración |

### 8.5 Nominatim (Geocoding)

| Propiedad | Valor |
|-----------|-------|
| URL | `https://nominatim.openstreetmap.org` |
| Uso | Configurable para self-hosted |
| PostGIS | `ST_DWithin` + `ST_Distance` para búsqueda por radio |

---

## 9. Flujos de Estado

### 9.1 Contratación

```
          ┌──────────┐
          │ PENDIENTE │ (cliente solicita)
          └─────┬────┘
                │
        ┌───────┼───────┐
        │               │
   ┌────▼────┐    ┌─────▼─────┐
   │ ACEPTADO│    │ RECHAZADO │ (proveedor rechaza)
   └────┬────┘    └───────────┘
        │
   ┌────▼────────┐
   │PAGADO_GARANTIA│ (cliente paga)
   └────┬────────┘
        │
   ┌────▼──────────┐
   │ EN_PROGRESO   │
   └────┬──────────┘
        │
   ┌────▼──────┐       ┌──────────┐
   │ COMPLETADO│──────►│ CANCELADO│ (cualquier estado previo)
   └────┬──────┘       └──────────┘
        │
   (reseña opcional)
```

### 9.2 Pago

```
         ┌───────────┐
         │ PENDIENTE │
         └─────┬─────┘
               │
          ┌────▼─────┐
          │ APROBADO │ (webhook MP)
          └────┬─────┘
               │
         ┌─────┴─────┐
         │           │
   ┌─────▼────┐ ┌────▼──────┐
   │ LIBERADO │ │REEMBOLSADO│ (disputa admite
   └──────────┘ └───────────┘  reembolso)
```

### 9.3 Disputa

```
       ┌──────────┐
       │ ABIERTA  │ (participante abre)
       └────┬─────┘
            │
     ┌──────▼───────┐
     │ EN_REVISION  │ (admin revisa)
     └──────┬───────┘
            │
     ┌──────▼────┐
     │ RESUELTA  │ → acción: liberar o reembolsar
     └───────────┘
```

---

## 10. Tests y CI/CD

### 10.1 Suite de Tests

| Archivo | Tests | Cobertura |
|---------|-------|-----------|
| `tests/test_auth.py` | 9 | Registro, login, me, forgot-password |
| `tests/test_servicios.py` | 12 | CRUD, geo-search, validaciones, permisos |
| `tests/test_contrataciones.py` | 12 | Contratación + disputas (8 + 4) |

### 10.2 Ejecutar Tests

```bash
# Con Docker (requiere base de datos de test)
docker compose exec api python -m pytest tests/ -v --tb=short

# Local (configurar DATABASE_URL en .env a BD de test)
pytest tests/ -v --tb=short
```

### 10.3 Fixtures Principales (`tests/conftest.py`)

| Fixture | Descripción |
|---------|-------------|
| `test_db_url` | URL de la BD de test desde settings |
| `test_engine` | Engine async aislado por test |
| `db_session` | Sesión con savepoint/rollback por test |
| `client` | TestClient de FastAPI con DB override |
| `usuario_cliente` | Usuario de prueba (rol cliente, verificado) |
| `usuario_proveedor` | Usuario de prueba (rol proveedor, verificado) |
| `auth_headers` | Bearer token del cliente de prueba |
| `auth_headers_proveedor` | Bearer token del proveedor de prueba |

### 10.4 CI/CD (GitHub Actions)

El pipeline en `.github/workflows/ci.yml` ejecuta los tests en cada push/PR a `dev` y `main`:

1. Levanta PostgreSQL + PostGIS como service container
2. Instala dependencias Python
3. Ejecuta `pytest tests/ -v --tb=short` con variables de entorno de CI

---

> **Documentación generada el 2026-06-16** — Para la interfaz Swagger interactiva, ejecutar el servidor y visitar `/docs`.
