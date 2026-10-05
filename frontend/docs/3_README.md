# TrabajoYa App

Marketplace de servicios en Chile. Conecta clientes que necesitan servicios (gasfiteria, electricidad, jardineria, etc.) con proveedores verificados.

## Tech Stack

| Capa | Tecnologia |
|---|---|
| Framework | Flutter 3.44+ (Dart 3.12+) |
| Estado | Provider (ChangeNotifier) |
| Routing | GoRouter (declarativo, 23 rutas) |
| HTTP | package:http |
| Auth | JWT + flutter_secure_storage |
| Pagos | MercadoPago (WebView) |
| Geolocalizacion | geolocator |
| UI | Material 3, Google Fonts (Inter), light/dark themes |

## Estructura del proyecto

```
lib/
├── main.dart                     # Entry point
├── app/
│   ├── app.dart                  # Root widget + providers
│   ├── router.dart               # GoRouter (23 rutas)
│   └── theme.dart                # Temas light/dark (teal + orange)
├── core/
│   ├── api_client.dart           # HTTP client singleton con JWT
│   ├── constants.dart            # mockMode flag + apiBaseUrl
│   ├── mock_data.dart            # API mock completa con datos fake
│   ├── storage_io.dart           # Secure storage nativo
│   └── storage_web.dart          # localStorage wrapper (web)
├── features/
│   ├── auth/                     # Login, registro, forgot password, verify email, perfil
│   ├── servicios/                # Home (tabbed), listado, detalle, crear/editar
│   ├── contrataciones/           # Solicitar, detalle, mis contrataciones, resenas
│   ├── chat/                     # Conversaciones, chat
│   ├── pagos/                    # Pago con MercadoPago
│   ├── admin/                    # Dashboard, usuarios, servicios, pagos, disputas
│   ├── perfil/                   # Edicion de perfil
│   ├── suscripciones/            # Planes premium
│   └── splash/                   # Splash screen
├── models/                       # 6 modelos: Usuario, Servicio, Contratacion, Mensaje, Resena, Categoria
├── services/                     # 8 servicios API (auth, servicios, contrataciones, chat, pagos, etc.)
└── widgets/                      # Componentes reutilizables
```

## Requisitos previos

- **Flutter SDK** >= 3.44.0 ([instalacion](https://docs.flutter.dev/get-started/install/windows))
- **Docker Desktop** (para ejecutar el backend `trabajoya-api`)

## Getting Started

```bash
# Clonar el repo (app + api comparten carpeta padre)
git clone <repo-url> TrabajoYa
cd TrabajoYa\trabajoya-app

# Instalar dependencias
flutter pub get

# Ejecutar en modo mock (sin backend)
flutter run -d chrome
```

### Credenciales de prueba (mock mode)

Cualquier email y password funciona. El rol se asigna segun el email:
- Contiene `admin` → Administrador
- Contiene `carlos` o `proveedor` → Proveedor (Carlos Perez)
- Contiene `ana` → Proveedora (Ana Martinez)
- Otro → Cliente (Maria Gonzalez)

## Conexion con backend real

```bash
# 1. Levantar el backend
cd ..\trabajoya-api
docker compose up -d

# 2. Cambiar mockMode a false en lib/core/constants.dart
const mockMode = false;

# 3. Ejecutar la app
cd ..\trabajoya-app
flutter run -d chrome    # o windows, android, etc.
```

### Credenciales de prueba (backend real)

| Rol | Email | Password |
|---|---|---|
| Admin | admin@trabajoya.cl | admin123 |
| Cliente | cliente1@trabajoya.cl | password123 |
| Proveedor | proveedor1@trabajoya.cl | password123 |

Para mas detalles sobre el modo mock, ver [5_mockmode.md](5_mockmode.md).

## Roles de usuario

| Rol | Funcionalidades |
|---|---|
| **Cliente** | Buscar servicios, solicitar contrataciones, chatear con proveedores, pagar, dejar resenas, abrir disputas |
| **Proveedor** | Crear/gestionar servicios, aceptar/rechazar solicitudes, chatear, suscribirse a planes premium |
| **Admin** | Dashboard con estadisticas, gestionar usuarios/servicios/pagos, resolver disputas |

## Funcionalidades implementadas

- Autenticacion completa (login, registro, verificacion de email, recuperacion de password, JWT)
- Catalogo de servicios con busqueda y filtros
- Busqueda geoespacial de servicios cercanos
- CRUD de servicios (crear, editar, pausar, eliminar)
- Flujo de contratacion (solicitar, aceptar, rechazar, finalizar)
- Chat entre cliente y proveedor por contratacion
- Pagos con MercadoPago (WebView)
- Sistema de resenas por estrellas y comentarios
- Planes de suscripcion premium para proveedores
- Panel admin con dashboard de metricas
- Modo mock para desarrollo sin backend
- Temas light/dark con Material 3

## Plataformas

Android, iOS, Web (PWA), Windows, Linux, macOS

## Testing

```bash
flutter test
```

Actualmente incluye un test de widget que verifica que la app renderiza correctamente.
