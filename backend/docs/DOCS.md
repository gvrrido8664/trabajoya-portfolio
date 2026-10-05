# TrabajoYa API — Documentación Técnica

> **Versión:** 1.1.0 — **Stack:** FastAPI + PostgreSQL/PostGIS + async — **Propósito:** Marketplace de servicios domésticos

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
   - [Reseñas](#57-reseñas)
   - [Chat](#58-chat)
   - [Pagos](#59-pagos)
   - [Suscripciones](#510-suscripciones)
   - [Upload](#511-upload)
   - [Proveedores](#512-proveedores)
   - [Oportunidades](#513-oportunidades)
   - [Admin](#514-admin)
   - [Disputas](#515-disputas)
   - [Bugs](#516-bugs)
6. [Modelos de Datos](#6-modelos-de-datos)
7. [WebSocket Chat](#7-websocket-chat)
8. [Servicios Externos](#8-servicios-externos)
9. [Flujos de Estado](#9-flujos-de-estado)
10. [Tests y CI/CD](#10-tests-y-cicd)

---

## 1. Visión General

**TrabajoYa API** es un backend marketplace que conecta **clientes** que necesitan servicios domésticos con **proveedores** que los ofrecen. La plataforma gestiona desde la publicación y búsqueda geográfica de servicios hasta la contratación, pago, chat en tiempo real y resolución de disputas.

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
                    │  (React/RN)  │
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
│   │   ├── __init__.py     # Re-exporta todos los modelos
│   │   ├── usuario.py      # Usuario + RolUsuario enum
│   │   ├── categoria.py    # Categoria (plana, sin jerarquía)
│   │   ├── servicio.py     # Servicio + EstadoServicio enum (es_destacado, fotos ARRAY)
│   │   ├── contratacion.py # Contratacion + EstadoContratacion enum (6 estados)
│   │   ├── mensaje.py      # Mensaje (chat)
│   │   ├── resena.py       # Reseña (relación 1:1 con contratación)
│   │   ├── pago.py         # Pago + EstadoPago (simplificado, 4 estados)
│   │   ├── plan.py         # Plan de suscripción (simplificado)
│   │   ├── suscripcion.py  # Suscripcion + EstadoSuscripcion (simplificado)
│   │   ├── disputa.py      # Disputa + EstadoDisputa (simplificado)
│   │   └── bug_reporte.py  # BugReport (nuevo)
│   │
│   ├── schemas/            # Schemas Pydantic (request/response)
│   │   ├── __init__.py     # Re-exporta todos los schemas
│   │   ├── auth.py         # RegistroRequest, LoginRequest, Token, UsuarioResponse
│   │   ├── usuario.py      # UsuarioUpdate, UbicacionUpdate, ProveedorResumen
│   │   ├── categoria.py    # CategoriaResponse
│   │   ├── servicio.py     # ServicioCreate, ServicioUpdate, ServicioResponse, ServicioEnrichedResponse
│   │   ├── contratacion.py # ContratacionCreate, ContratacionResponse, ContratacionEnrichedResponse
│   │   ├── chat.py         # MensajeResponse, MensajeEnviar, ConversacionResumen, OtroUsuario
│   │   ├── pagos.py        # PagoCreate, PagoResponse, PagoPreferenceResponse
│   │   ├── suscripcion.py  # PlanResponse, SuscripcionCreate, SuscripcionResponse
│   │   ├── disputa.py      # DisputaCreate, DisputaResponse
│   │   ├── resena.py       # ResenaCreate, ResenaResponse
│   │   └── bugs.py         # BugReportCreate, BugReportResponse
│   │
│   ├── api/                # ★ Handlers (rutas / controladores)
│   │   ├── dependencies.py # Dependencias: get_current_user, get_current_provider, get_current_admin
│   │   ├── routes_auth.py           # Registro, login, verificación email, reset password
│   │   ├── routes_usuarios.py       # Perfil público, actualización, ubicación, referidos
│   │   ├── routes_categorias.py     # Listar categorías
│   │   ├── routes_servicios.py      # CRUD servicios + búsqueda geográfica + destacados
│   │   ├── routes_contrataciones.py # Solicitud, aceptar/rechazar, finalizar
│   │   ├── routes_resenas.py        # Reseñas (POST /resenas, GET /resenas/usuario/:id)
│   │   ├── routes_chat.py           # Chat REST + WebSocket
│   │   ├── routes_pagos.py          # Crear preferencia MP, webhook, estado
│   │   ├── routes_suscripciones.py  # Suscripción a planes premium
│   │   ├── routes_upload.py         # Subida de avatares y fotos de servicio
│   │   ├── routes_proveedores.py    # Top proveedores
│   │   ├── routes_oportunidades.py  # Contrataciones pendientes para proveedores
│   │   ├── routes_admin.py          # Dashboard, gestión de usuarios/servicios/pagos/bugs
│   │   ├── routes_disputas.py       # Apertura y resolución de disputas
│   │   └── routes_bugs.py           # Reporte de bugs (público + admin)
│   │
│   ├── services/           # Lógica de negocio (servicios externos)
│   │   ├── email_service.py        # Resend (email transaccional)
│   │   ├── payment_service.py      # MercadoPago (preferencias, webhooks)
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
│       ├── 182533923411_init.py              # Schema inicial (8 tablas)
│       ├── e672bf5cf4af_disputas_y_referidos.py  # Disputas + referidos
│       └── d4e5f6a7b8c9_refactor_modelos_fase1.py  # Refactor modelos Fase 1
│
└── tests/                  # Suite de tests (38 tests)
    ├── conftest.py         # Fixtures: db_session, client, auth_headers, categoria, servicio_activo
    ├── test_auth.py        # 9 tests (registro, login, me, forgot-password)
    ├── test_servicios.py   # 12 tests (CRUD, geo-search, validaciones)
    ├── test_contrataciones.py  # 10 tests (contratación + disputas)
    └── test_nuevos_endpoints.py  # 7 tests (bugs, destacar, oportunidades, top proveedores)
```

---

## 4. Autenticación

### 4.1 Esquema

La API utiliza **JWT (JSON Web Tokens)** con el esquema `Bearer`. El token se obtiene al hacer login y debe enviarse en el header `Authorization` de todas las rutas protegidas.

### 4.2 Flujo Completo

```
1. POST /api/v1/auth/register   → Crea usuario + envía email de verificación
2. GET  /api/v1/auth/verify-email?token=... → Verifica email
3. POST /api/v1/auth/login       → Obtiene JWT (access_token + user)
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

Registra un nuevo usuario. Envía email de verificación. Soporta sistema de referidos (parámetro query `ref` con el código de referido).

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
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `ref` | `string?` | Código de referido |
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "3e8a7c1b-...",
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
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
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
  "id": "3e8a7c1b-...",
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
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `token` | `string` | Token de verificación enviado por email |
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Email verificado exitosamente"
}
```
</details>

---

#### `POST /api/v1/auth/forgot-password`

Envía un link de restablecimiento de contraseña al email. **Siempre responde 200** para evitar enumeración de usuarios.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `email` | `string` | Email del usuario |
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Si el email existe, recibirás un link para restablecer tu contraseña"
}
```
</details>

#### `POST /api/v1/auth/reset-password`

Cambia la contraseña usando el token de reseteo.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `token` | `string` | Token de reseteo enviado por email |
| `new_password` | `string` | Nueva contraseña |
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "message": "Contraseña actualizada exitosamente"
}
```
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
  "id": "3e8a7c1b-...",
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

---

#### `PUT /api/v1/usuarios/me`

Actualiza el perfil del usuario autenticado.

#### `PATCH /api/v1/usuarios/me/ubicacion`

Actualiza la ubicación del usuario autenticado (coordenadas geográficas).

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
      "id": "4f9b8c2d-...",
      "nombre": "Andrea",
      "apellido": "Herrera",
      "created_at": "2026-06-15T10:00:00Z"
    }
  ]
}
```
</details>

> **Nota:** Los campos `email_verificado`, `ultima_conexion` y `referido_por` fueron eliminados del modelo `Usuario`.

---

### 5.4 Categorías

Prefijo: `/api/v1/categorias`

#### `GET /api/v1/categorias`

Lista todas las categorías. Las categorías son planas (sin jerarquía `parent_id`).

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "a1b2c3d4-...",
    "nombre": "Plomería",
    "slug": "plomeria",
    "icono": "🔧",
    "descripcion": "Reparación e instalación de tuberías..."
  }
]
```
</details>

---

#### `GET /api/v1/categorias/{slug}`

Obtiene una categoría por su slug.

---

### 5.5 Servicios

Prefijo: `/api/v1/servicios`

---

#### `POST /api/v1/servicios`

Crea un nuevo servicio (requiere rol `proveedor` o `admin`). El campo `fotos` es un array de strings.

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
  "fotos": ["https://res.cloudinary.com/...", "https://res.cloudinary.com/..."]
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
  "status": "activo",
  "precio_min": 15000.0,
  "precio_max": 80000.0,
  "radio_cobertura_km": 15,
  "direccion_texto": "Santiago, Región Metropolitana",
  "fotos": ["https://res.cloudinary.com/..."],
  "es_destacado": false,
  "created_at": "2026-06-16T12:00:00Z",
  "updated_at": "2026-06-16T12:00:00Z"
}
```
</details>

---

#### `GET /api/v1/servicios`

Lista servicios activos. Filtrable por categoría y proveedor. Excluye servicios `ELIMINADO`.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `categoria_id` | `string?` | Filtrar por categoría |
| `proveedor_id` | `string?` | Filtrar por proveedor |
| `skip` | `int` | Paginación (default: 0) |
| `limit` | `int` | Paginación (default: 20, max: 100) |
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
    "fotos": ["https://..."],
    "status": "activo",
    "created_at": "2026-06-16T12:00:00Z",
    "updated_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

#### `GET /api/v1/servicios/buscar`

Búsqueda geoespacial: encuentra servicios activos dentro de un radio desde un punto geográfico. Ordenados por distancia.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `lat` | `float` | Latitud del punto de búsqueda |
| `lng` | `float` | Longitud del punto de búsqueda |
| `radio_km` | `float` | Radio de búsqueda en km (default: 10) |
| `categoria_id` | `string?` | Filtrar por categoría |
| `skip` | `int` | Paginación (default: 0) |
| `limit` | `int` | Paginación (default: 20, max: 100) |
</details>

#### `GET /api/v1/servicios/{servicio_id}`

Obtiene detalle de un servicio por UUID (excluye `ELIMINADO`). Retorna servicio enriquecido (con nombre y rating del proveedor).

#### `PUT /api/v1/servicios/{servicio_id}`

Actualiza un servicio (solo el proveedor propietario).

#### `PATCH /api/v1/servicios/{servicio_id}/pausar`

Alterna el estado del servicio entre `activo` y `pausado`.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "pausado"
}
```
</details>

#### `DELETE /api/v1/servicios/{servicio_id}`

Eliminación lógica: cambia el estado a `ELIMINADO`.

---

### 5.6 Contrataciones

Prefijo: `/api/v1/contrataciones`

---

#### `POST /api/v1/contrataciones`

Crea una solicitud de contratación (solo rol `cliente`). No se puede contratar el propio servicio.

#### `GET /api/v1/contrataciones`

Lista las contrataciones del usuario autenticado (como cliente o proveedor). Incluye nombres y título del servicio.

#### `GET /api/v1/contrataciones/{contratacion_id}`

Obtiene detalle de una contratación (solo participantes).

#### `PATCH /api/v1/contrataciones/{contratacion_id}/aceptar`

El proveedor acepta una contratación pendiente.

#### `PATCH /api/v1/contrataciones/{contratacion_id}/rechazar`

El proveedor rechaza una contratación pendiente.

#### `PATCH /api/v1/contrataciones/{contratacion_id}/finalizar`

Cualquiera de las partes marca la contratación como completada.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "completado"
}
```
</details>

---

#### `POST /api/v1/contrataciones/{contratacion_id}/resena`

Deja una reseña sobre una contratación completada. Una reseña por contratación.

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
  "comentario": "Excelente servicio",
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

#### `GET /api/v1/contrataciones/usuario/{usuario_id}/resenas`

Lista las reseñas recibidas por un usuario.

---

### 5.7 Reseñas

Prefijo: `/api/v1/resenas`

---

#### `POST /api/v1/resenas`

Deja una reseña sobre una contratación completada. Una reseña por contratación.

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
  "contratacion_id": "d4e5f6a7-...",
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
  "comentario": "Excelente servicio",
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

---

#### `GET /api/v1/resenas/usuario/{usuario_id}`

Lista las reseñas recibidas por un usuario (público).

---

### 5.8 Chat

Prefijo: `/api/v1/chat`

---

#### `WebSocket /api/v1/chat/ws/{contratacion_id}?token=<jwt>`

Conexión WebSocket para chat en tiempo real. El token JWT se envía como query parameter.

#### `POST /api/v1/chat/mensajes/{contratacion_id}`

Envía un mensaje vía REST (alternativa al WebSocket). Marca automáticamente los mensajes recibidos como leídos al consultar.

<details>
<summary>Request Body</summary>

```json
{
  "contenido": "Hola, ¿qué tal?"
}
```
</details>

#### `GET /api/v1/chat/mensajes/{contratacion_id}`

Historial de mensajes de una contratación. Paginado, ordenado del más reciente al más antiguo. Marca los mensajes del otro usuario como leídos.

#### `GET /api/v1/chat/conversaciones`

Lista las conversaciones activas del usuario (deduplicadas por par de usuarios).

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

### 5.9 Pagos

Prefijo: `/api/v1/pagos`

---

#### `POST /api/v1/pagos/crear`

Crea una preferencia de pago en MercadoPago para una contratación aceptada. Solo el cliente puede iniciar el pago.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `contratacion_id` | `string` | ID de la contratación |
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "preference_id": "123456789-...",
  "init_point": "https://www.mercadopago.cl/checkout/v1/redirect?...",
  "sandbox_init_point": "https://sandbox.mercadopago.cl/checkout/v1/redirect?..."
}
```
</details>

---

#### `POST /api/v1/pagos/webhooks/pagos`

**Endpoint público** (sin autenticación). Webhook de MercadoPago para recibir notificaciones de pago.

#### `GET /api/v1/pagos/{contratacion_id}/estado`

Consulta el estado del pago de una contratación.

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "status": "aprobado",
  "monto": 25000.0,
  "fee_plataforma": 0.0,
  "monto_neto": 0.0
}
```
</details>

---

### 5.10 Suscripciones

Prefijo: `/api/v1/suscripciones`

#### `POST /api/v1/suscripciones/crear`

Crea una suscripción a un plan premium. Retorna la preferencia de pago de MercadoPago.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `plan_slug` | `string` | Slug del plan |
</details>

#### `GET /api/v1/suscripciones/me`

Consulta el estado de la suscripción actual del usuario (solo proveedor).

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

<details>
<summary>Response <code>200 OK</code> (sin suscripción)</summary>

```json
{
  "tiene_suscripcion": false,
  "plan": "basic"
}
```
</details>

---

### 5.11 Upload

Prefijo: `/api/v1/upload`

#### `POST /api/v1/upload/avatar`

Sube una imagen de avatar. **5 MB máx.** Formatos: JPEG, PNG, WebP.

#### `POST /api/v1/upload/servicio/{servicio_id}`

Sube una foto de servicio. **10 MB máx.** Máx. 5 fotos por servicio.

#### `DELETE /api/v1/upload/{public_id}`

Elimina un archivo subido mediante su `public_id` de Cloudinary.

---

### 5.12 Proveedores

Prefijo: `/api/v1/proveedores`

#### `GET /api/v1/proveedores/top`

Lista los mejores proveedores ordenados por `avg_rating` descendente.

<details>
<summary>Parámetros</summary>

| Tipo | Parámetro | Tipo | Descripción |
|------|-----------|------|-------------|
| Query | `limit` | `int` | Máx. 50 (default: 10) |

</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
[
  {
    "id": "3e8a7c1b-...",
    "nombre": "Carlos Muñoz",
    "avatar_url": "https://res.cloudinary.com/...",
    "avg_rating": 4.9,
    "bio": "Experto en plomería...",
    "total_contratos": 12
  }
]
```
</details>

---

### 5.13 Oportunidades

Prefijo: `/api/v1/oportunidades`

#### `GET /api/v1/oportunidades`

Lista contrataciones pendientes para que los proveedores encuentren trabajo disponible. Endpoint público.

<details>
<summary>Response <code>200 OK</code></summary>

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
    "created_at": "2026-06-16T12:00:00Z"
  }
]
```
</details>

---

### 5.14 Admin

Prefijo: `/api/v1/admin` — **Todas requieren rol `admin`**

| Endpoint | Descripción |
|---|---|
| `GET /admin/stats` | Dashboard con métricas generales |
| `GET /admin/usuarios` | Lista todos los usuarios (filtrable por rol/email) |
| `POST /admin/usuarios` | Crea un usuario (auto-verificado) |
| `PATCH /admin/usuarios/{id}/toggle-active` | Activa/desactiva un usuario |
| `PUT /admin/usuarios/{id}` | Actualiza cualquier campo de un usuario |
| `GET /admin/servicios` | Lista todos los servicios |
| `GET /admin/pagos` | Lista todos los pagos |
| `GET /admin/disputas` | Lista todas las disputas (filtrable por status) |
| `PATCH /admin/disputas/{id}/resolve` | Resuelve una disputa (body: `{resolucion, action}`) |
| `GET /admin/bugs` | Lista todos los reportes de bug |
| `PATCH /admin/bugs/{bug_id}` | Actualiza el estado de un bug report |

---

### 5.15 Disputas

Prefijo: `/api/v1/disputas`

---

#### `POST /api/v1/disputas/contratacion/{contratacion_id}`

Abre una disputa sobre una contratación. Solo los participantes. Una disputa por contratación.

<details>
<summary>Path + Query Params</summary>

| Parámetro | Tipo | Ubicación | Descripción |
|-----------|------|-----------|-------------|
| `contratacion_id` | `string` | Path | ID de la contratación |
| `motivo` | `string` | Query | Motivo de la disputa |
| `evidencias` | `string?` | Query | Evidencias adicionales |
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "c3d4e5f6-...",
  "status": "abierta",
  "motivo": "El proveedor no completó el trabajo acordado"
}
```
</details>

---

#### `GET /api/v1/disputas/admin`

Lista todas las disputas (solo admin). Filtrable por estado.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `status` | `string?` | Filtrar por estado (`abierta`, `resuelta`) |
</details>

<details>
<summary>Response <code>200 OK</code></summary>

```json
{
  "total": 1,
  "data": [
    {
      "id": "c3d4e5f6-...",
      "contratacion_id": "d4e5f6a7-...",
      "abridor_id": "3e8a7c1b-...",
      "motivo": "El proveedor no completó el trabajo",
      "evidencias": null,
      "status": "abierta",
      "resolucion": null,
      "created_at": "2026-06-16T12:00:00Z"
    }
  ]
}
```
</details>

#### `PATCH /api/v1/disputas/admin/{disputa_id}/resolver`

Resuelve una disputa (solo admin). Acción: `reembolsar` o `liberar`.

<details>
<summary>Query Params</summary>

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `resolucion` | `string` | Notas de la resolución |
| `accion` | `string` | `reembolsar` o `liberar` |
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

### 5.16 Bugs

Prefijo: `/api/v1/bugs`

---

#### `POST /api/v1/bugs`

Reporta un bug (requiere autenticación).

<details>
<summary>Request Body</summary>

```json
{
  "titulo": "Error al iniciar sesión",
  "descripcion": "No funciona el login con email verificado",
  "area": "funcion"
}
```
</details>

<details>
<summary>Response <code>201 Created</code></summary>

```json
{
  "id": "f6a7b8c9-...",
  "titulo": "Error al iniciar sesión",
  "descripcion": "No funciona el login con email verificado",
  "area": "funcion",
  "status": "abierto",
  "created_at": "2026-06-16T12:00:00Z"
}
```
</details>

---

#### `GET /api/v1/bugs/mis-reportes`

Lista los bugs reportados por el usuario autenticado.

---

## 6. Modelos de Datos

### 6.1 Diagrama de Entidad-Relación

```
usuarios (1) ─────< servicios (N)       ┌─ resenas (1:1 con contratacion)
usuarios (1) ─────< contrataciones (N) ──┤
usuarios (1) ─────< mensajes (N)          ├─ pagos (1:1 con contratacion)
usuarios (1) ─────< disputas (N)          └─ disputas (1:1 con contratacion)
usuarios (1) ─────< bug_reportes (N)
categorias (1) ───< servicios (N)
planes (1) ───────< suscripciones (N)
usuarios (1) ─────< suscripciones (N)
```

### 6.2 Tabla: `usuarios`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador único |
| `email` | `VARCHAR(255)` | UNIQUE, NOT NULL, INDEX | Email del usuario |
| `password_hash` | `VARCHAR(255)` | NOT NULL | Hash bcrypt de la contraseña |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre |
| `apellido` | `VARCHAR(100)` | NOT NULL | Apellido |
| `telefono` | `VARCHAR(20)` | NULLABLE | Teléfono de contacto |
| `rol` | `ENUM` | NOT NULL | `cliente`, `proveedor`, `admin` |
| `avatar_url` | `VARCHAR(500)` | NULLABLE | URL del avatar en Cloudinary |
| `bio` | `TEXT` | NULLABLE | Biografía o descripción |
| `habilidades` | `TEXT` | NULLABLE | JSON array de habilidades |
| `is_active` | `BOOLEAN` | NOT NULL | Si la cuenta está activa |
| `is_verified` | `BOOLEAN` | NOT NULL | Si el usuario fue verificado por admin |
| `avg_rating` | `FLOAT` | NOT NULL | Rating promedio (calculado de reseñas) |
| `codigo_referido` | `VARCHAR(20)` | UNIQUE, INDEX | Código único del programa de referidos |
| `referidos_count` | `INTEGER` | NOT NULL | Contador de referidos exitosos |
| `created_at` | `DATETIME(tz)` | NOT NULL | Fecha de creación |
| `updated_at` | `DATETIME(tz)` | NOT NULL | Última actualización

### 6.3 Tabla: `categorias`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre visible |
| `slug` | `VARCHAR(100)` | UNIQUE, NOT NULL, INDEX | Slug URL |
| `icono` | `VARCHAR(50)` | NULLABLE | Emoji o icono |
| `descripcion` | `TEXT` | NULLABLE | Descripción de la categoría |

> **Campo eliminado:** `parent_id` — las categorías ahora son planas.

### 6.4 Tabla: `servicios`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Proveedor |
| `categoria_id` | `UUID` | FK → `categorias.id`, NOT NULL, INDEX | Categoría |
| `titulo` | `VARCHAR(200)` | NOT NULL | Título del servicio |
| `descripcion` | `TEXT` | NOT NULL | Descripción detallada |
| `precio_min` | `FLOAT` | NULLABLE | Precio mínimo estimado |
| `precio_max` | `FLOAT` | NULLABLE | Precio máximo estimado |
| `ubicacion` | `GEOGRAPHY(POINT, 4326)` | NULLABLE | Ubicación (PostGIS) |
| `radio_cobertura_km` | `INTEGER` | NOT NULL | Radio de cobertura en km |
| `direccion_texto` | `VARCHAR(500)` | NULLABLE | Dirección en texto |
| `status` | `ENUM` | NOT NULL | `activo`, `pausado`, `eliminado` |
| `fotos` | `TEXT[]` | NULLABLE | Array de URLs de fotos |
| `es_destacado` | `BOOLEAN` | NOT NULL | Si está destacado |

### 6.5 Tabla: `contrataciones`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `cliente_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Cliente |
| `proveedor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Proveedor |
| `servicio_id` | `UUID` | FK → `servicios.id`, NOT NULL, INDEX | Servicio |
| `status` | `ENUM` | NOT NULL | `pendiente`, `aceptado`, `rechazado`, `completado`, `cancelado`, `disputa` |
| `monto_acordado` | `FLOAT` | NULLABLE | Monto acordado |
| `mensaje_solicitud` | `TEXT` | NULLABLE | Mensaje inicial del cliente |
| `fecha_programada` | `DATETIME(tz)` | NULLABLE | Fecha programada |

### 6.6 Tabla: `mensajes`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, NOT NULL, INDEX | Contratación |
| `emisor_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Quién envía |
| `contenido` | `TEXT` | NOT NULL | Contenido del mensaje |
| `leido` | `BOOLEAN` | NOT NULL | Si fue leído |

### 6.7 Tabla: `pagos`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL | Contratación (1:1) |
| `monto` | `FLOAT` | NOT NULL | Monto total |
| `status` | `ENUM` | NOT NULL | `pendiente`, `aprobado`, `rechazado`, `cancelado` |
| `preference_id` | `VARCHAR(255)` | NULLABLE | ID de preferencia MP |
| `mp_payment_id` | `VARCHAR(255)` | NULLABLE | ID del pago en MP |

> **Campos eliminados:** `cliente_id`, `proveedor_id`, `fee_plataforma`, `monto_neto`, `gateway`, `gateway_payment_id`

### 6.8 Tabla: `resenas`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL | Contratación (1:1) |
| `calificador_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Quién califica |
| `calificado_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Quién recibe la calificación |
| `puntuacion` | `INTEGER` | NOT NULL | Puntuación (1–5) |
| `comentario` | `TEXT` | NULLABLE | Comentario |

### 6.9 Tabla: `planes`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `nombre` | `VARCHAR(100)` | NOT NULL | Nombre del plan |
| `descripcion` | `TEXT` | NULLABLE | Descripción del plan |
| `beneficios` | `VARCHAR[]` | NULLABLE | Array de beneficios |
| `precio_mensual` | `FLOAT` | NOT NULL | Precio mensual en CLP |

### 6.10 Tabla: `suscripciones`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `usuario_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Usuario suscrito |
| `plan_id` | `UUID` | FK → `planes.id`, NOT NULL | Plan contratado |
| `status` | `ENUM` | NOT NULL | `activa`, `cancelada`, `vencida` |
| `fecha_inicio` | `DATETIME(tz)` | NOT NULL | Inicio |
| `fecha_vencimiento` | `DATETIME(tz)` | NULLABLE | Fin de la suscripción |

### 6.11 Tabla: `disputas`

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `contratacion_id` | `UUID` | FK → `contrataciones.id`, UNIQUE, NOT NULL | Contratación (1:1) |
| `abierta_por_id` | `UUID` | FK → `usuarios.id`, NOT NULL | Quién abre la disputa |
| `motivo` | `TEXT` | NOT NULL | Descripción del problema |
| `status` | `ENUM` | NOT NULL | `abierta`, `resuelta` |
| `resolucion` | `TEXT` | NULLABLE | Notas del admin |
| `action_tomada` | `VARCHAR(50)` | NULLABLE | `reembolsar` o `liberar` |
| `resolved_at` | `DATETIME(tz)` | NULLABLE | Cuándo se resolvió |

### 6.12 Tabla: `bug_reportes` (nueva)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | `UUID` | PK | Identificador |
| `usuario_id` | `UUID` | FK → `usuarios.id`, NOT NULL, INDEX | Quién reporta |
| `titulo` | `VARCHAR(200)` | NOT NULL | Título del bug |
| `descripcion` | `TEXT` | NOT NULL | Descripción detallada |
| `area` | `ENUM` | NOT NULL | `diseno`, `funcion`, `logica`, `otro` |
| `status` | `ENUM` | NOT NULL | `abierto`, `en_proceso`, `resuelto` |
| `resolved_at` | `DATETIME(tz)` | NULLABLE | Cuándo se resolvió |

---

## 7. WebSocket Chat

### 7.1 Conexión

```
ws://localhost:8000/api/v1/chat/ws/{contratacion_id}?token={jwt_token}
```

### 7.2 Autenticación

El token JWT se envía como **query parameter** (`token`). El servidor valida que:
1. El token sea válido y no esté expirado
2. El usuario autenticado sea participante de la contratación

### 7.3 Protocolo

| Dirección | Formato | Descripción |
|-----------|---------|-------------|
| Cliente → Servidor | `{"contenido": "texto"}` | Texto plano |
| Servidor → Clientes | `{"id":..., "emisor_id":..., "contenido":..., ...}` | Eco + broadcast |

### 7.4 ConnectionManager

El `ConnectionManager` mantiene un diccionario `{user_id: [WebSocket, ...]}` que permite enviar mensajes a todas las conexiones activas de un usuario y broadcast global.

---

## 8. Servicios Externos

### 8.1 MercadoPago (Pagos)

| Propiedad | Valor |
|-----------|-------|
| SDK | API REST via `httpx` |
| Webhook | `POST /api/v1/pagos/webhooks/mercadopago` |
| Moneda | **CLP** (Peso chileno) |
| Modo | Sandbox/Producción según token |

### 8.2 Cloudinary (Archivos)

| Propiedad | Valor |
|-----------|-------|
| Avatar máx | 5 MB, 400×400 thumb |
| Foto servicio máx | 10 MB, 1200×800 |
| Formatos | JPEG, PNG, WebP |
| Máx fotos/servicio | 5 |

### 8.3 Resend (Email Transaccional)

| Propiedad | Valor |
|-----------|-------|
| Free tier | 100 emails/día |
| Remitente | `TrabajoYa <noreply@trabajoya.cl>` |
| Tipos | Verificación, bienvenida, reset password |

### 8.4 Firebase Cloud Messaging (Push)

Implementación base (no bloqueante). Retorna `None` si no hay configuración.

### 8.5 Nominatim (Geocoding)

URL configurable para self-hosted. PostGIS: `ST_DWithin` + `ST_Distance` para búsqueda por radio.

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
   │ ACEPTADO│    │ RECHAZADO │
   └────┬────┘    └───────────┘
        │
   ┌────▼──────┐
   │ COMPLETADO│──► CANCELADO
   └────┬──────┘
        │
   ┌────▼────┐
   │ DISPUTA │ (cualquier parte abre disputa)
   └─────────┘
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
   │ CANCELADO│ │ RECHAZADO │
   └──────────┘ └───────────┘
```

### 9.3 Disputa

```
       ┌──────────┐
       │ ABIERTA  │ (participante abre)
       └────┬─────┘
            │
       ┌────▼────┐
       │ RESUELTA│ → acción: liberar o reembolsar
       └─────────┘
```

---

## 10. Tests y CI/CD

### 10.1 Suite de Tests

| Archivo | Tests | Cobertura |
|---------|-------|-----------|
| `tests/test_auth.py` | 9 | Registro, login, me, forgot-password |
| `tests/test_servicios.py` | 12 | CRUD, geo-search, validaciones, permisos |
| `tests/test_contrataciones.py` | 10 | Contratación (7) + disputas (3) |
| `tests/test_nuevos_endpoints.py` | 7 | Bugs (3), destacar (2), oportunidades (1), top proveedores (1) |
| **Total** | **38** | |

### 10.2 Ejecutar Tests

```bash
# Con Docker
docker compose exec api python -m pytest tests/ -v --tb=short

# Local
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
| `categoria` | Categoría de prueba |
| `servicio_activo` | Servicio activo de prueba |

### 10.4 CI/CD (GitHub Actions)

El pipeline en `.github/workflows/ci.yml` ejecuta los tests en cada push/PR a `dev` y `main`:

1. Levanta PostgreSQL + PostGIS como service container
2. Instala dependencias Python
3. Ejecuta `pytest tests/ -v --tb=short`

---

> **Documentación generada el 2026-06-17** — Para la interfaz Swagger interactiva, ejecutar el servidor y visitar `/docs`.
