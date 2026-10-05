# 📘 Guía Completa — TrabajoYa

Guía maestra para seguir desarrollando, mantener y publicar TrabajoYa.
Última actualización: 2026-06-21.

---

## 1. Arquitectura general

TrabajoYa es un marketplace de servicios (tipo "Uber de oficios") con dos partes:

| Componente | Tecnología | Carpeta | Producción |
|---|---|---|---|
| **Backend (API)** | FastAPI + SQLAlchemy async + PostGIS | `trabajoya-api/` | Fly.io → `https://web-production-3bcbe.up.Fly.io.app` |
| **Frontend (App)** | Flutter 3.44 (web/Android/iOS) | `trabajoya-app/` | Vercel (web) → `https://flutter-web-deploy-rho.vercel.app` |
| **Base de datos** | PostgreSQL + PostGIS | Supabase (cloud) | Pooler IPv4 `aws-1-sa-east-1.pooler.supabase.com:5432` |
| **Pagos** | MercadoPago (sandbox) | — | API de MP |

Flujo: **App Flutter** → llama a la **API en Fly.io** → la API consulta **Supabase** y procesa **pagos con MercadoPago**.

---

## 2. Cómo levantar el proyecto en local

### 2.1 Backend (FastAPI)

```bash
cd trabajoya-api

# 1. Crear/activar entorno virtual (primera vez)
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Mac/Linux

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Levantar el servidor (con auto-reload)
uvicorn app.main:app --reload --port 8000
```

- API local: `http://localhost:8000`
- Documentación interactiva (Swagger): `http://localhost:8000/docs`
- El `.env` ya apunta a Supabase, así que en local usás la **misma base de datos** que producción. ⚠️ Cuidado: cualquier cambio afecta los datos reales.

> Variables en `trabajoya-api/.env` (NO se sube a git). Las críticas: `DATABASE_URL`, `JWT_SECRET_KEY`, `MP_ACCESS_TOKEN`.

### 2.2 Frontend (Flutter)

```bash
cd trabajoya-app

# 1. Instalar dependencias (primera vez o tras cambiar pubspec)
flutter pub get

# 2a. Correr en Chrome (web)
flutter run -d chrome

# 2b. Correr en emulador Android
flutter run -d emulator-5554

# 2c. Listar dispositivos disponibles
flutter devices
```

**Importante — a qué backend apunta la app:** se decide en
[lib/core/api/constants.dart](../lib/core/api/constants.dart):

- **Web** → Fly.io (producción)
- **Android emulador** → `http://10.0.2.2:8000` (tu backend local)
- **iOS/Desktop** → `http://localhost:8000` (tu backend local)

> Si querés que la web use tu backend local mientras desarrollás, cambiá `_Fly.ioUrl` o la rama `kIsWeb` temporalmente.

### 2.3 Usuarios de prueba

Creados por el seed (`recreate_db.py`). Password de todos: **`Password123`**

| Email | Rol |
|---|---|
| `cliente@test.com` | cliente |
| `proveedor@test.com` | proveedor |
| `admin@test.com` | admin |

---

## 3. Mapa de páginas (rutas)

Definidas en [lib/app/router.dart](../lib/app/router.dart). El usuario se redirige por rol tras login.

### Públicas
| Ruta | Pantalla |
|---|---|
| `/` | Landing pública |
| `/login`, `/register` | Login / registro |
| `/forgot-password`, `/reset-password` | Recuperar contraseña |
| `/verify-email` | Verificación de email |
| `/servicio/:id` | Detalle de servicio (público) |

### Cliente (shell con bottom-nav)
| Ruta | Pantalla |
|---|---|
| `/cliente/home` | Inicio cliente |
| `/cliente/buscar` | Buscar servicios |
| `/cliente/mis-solicitudes` | Mis solicitudes |
| `/cliente/trabajos` | Mis contrataciones |
| `/cliente/chat` | Conversaciones |
| `/cliente/perfil` | Perfil |
| `/crear-solicitud`, `/solicitud/:id` | Crear / ver solicitud |

### Proveedor (shell con bottom-nav)
| Ruta | Pantalla |
|---|---|
| `/proveedor/oportunidades` | Oportunidades (solicitudes abiertas) |
| `/proveedor/mis-propuestas` | Mis propuestas |
| `/proveedor/servicios` | Mis servicios |
| `/proveedor/solicitudes` | Contrataciones recibidas |
| `/proveedor/chat`, `/proveedor/perfil` | Chat / perfil |
| `/crear-servicio`, `/editar-servicio/:id` | Crear / editar servicio |
| `/solicitud/:id/proponer` | Enviar propuesta |

### Compartidas
| Ruta | Pantalla |
|---|---|
| `/contratacion/:id` | Detalle de contratación |
| `/chat/:contratacionId` | Chat de una contratación |
| `/pago/:contratacionId` | Pantalla de pago (MercadoPago) |
| `/pago/resultado/:contratacionId` | Resultado del pago |
| `/resena/:contratacionId` | Dejar reseña |
| `/planes` | Planes de suscripción |

### Admin (shell con sidebar)
`/admin` (dashboard), `/admin/clientes`, `/admin/proveedores`, `/admin/transacciones`, `/admin/realizados`, `/admin/cancelados`, `/admin/cobrados`, `/admin/fallidos`, `/admin/feedback`, `/admin/suscripciones`.

---

## 4. Backend — estructura y endpoints

Carpeta `trabajoya-api/app/`:
- `api/` — 17 archivos de rutas (un `routes_*.py` por dominio): auth, usuarios, categorias, servicios, contrataciones, chat, pagos, suscripciones, upload, admin, disputas, resenas, bugs, proveedores, oportunidades, solicitudes, propuestas.
- `models/` — modelos SQLAlchemy (la **fuente de verdad** del esquema de la BD).
- `schemas/` — esquemas Pydantic (validación entrada/salida).
- `services/` — lógica de negocio (ej. `payment_service.py` para MercadoPago).
- `core/` — config, seguridad (JWT, bcrypt), rate limiter.
- `database.py` — engine async + sesiones.
- `main.py` — app FastAPI, middlewares (CORS), registro de routers.

Ver todos los endpoints en vivo: **`/docs`** (Swagger) en local o en Fly.io.

---

## 5. Cómo actualizar (deploy)

### 5.1 Actualizar el BACKEND (Fly.io)

Fly.io está conectado al repo de GitHub `trabajoya-api` y **redesplega solo** al pushear a `main`:

```bash
cd trabajoya-api
git add .
git commit -m "descripcion del cambio"
git push          # ← Fly.io detecta el push y redespliega (~1-2 min)
```

- Variables de entorno: se editan en **Fly.io → Variables** (no en el repo).
- Ver logs / errores: **Fly.io → Deploy Logs**.
- Verificar que está vivo: abrir `https://web-production-3bcbe.up.Fly.io.app/health` → debe dar `{"status":"ok"}`.

### 5.2 Actualizar el FRONTEND WEB (Vercel)

Vercel NO está conectado a git (deploy manual por límite de tamaño). Pasos:

```bash
cd trabajoya-app

# 1. Compilar web
flutter build web --release

# 2. Copiar el build a la carpeta limpia de deploy
cp -r build/web/. /c/Users/Nacho/Desktop/flutter-web-deploy/

# 3. Desplegar a Vercel
cd /c/Users/Nacho/Desktop/flutter-web-deploy
npx vercel --prod --yes
```

> La carpeta `flutter-web-deploy` existe aparte para que Vercel suba SOLO el build (~49 MB) y no el repo entero (que supera el límite de 100 MB).

### 5.3 Cambiar la base de datos (esquema)

La BD se genera desde los modelos. Si agregás/cambiás un modelo en `app/models/`:

```bash
cd trabajoya-api
python recreate_db.py          # recrea esquema faltante + seed (NO borra)
python recreate_db.py --drop   # ⚠️ BORRA TODO y recrea desde cero + seed
```

> `recreate_db.py` está en `.gitignore` (utilidad local). Para producción seria conviene migrar a **Alembic** (ver §7).

---

## 6. Estado actual y qué falta

### ✅ Funcionando
- Backend online en Fly.io conectado a Supabase.
- Frontend web online en Vercel.
- Auth completo (registro, login, JWT de 7 días).
- CRUD de servicios, solicitudes, propuestas, contrataciones.
- Chat, reseñas, panel admin.
- Pagos MercadoPago en **sandbox**.

### ⚠️ Pendiente / no configurado
| Tema | Estado | Qué hacer |
|---|---|---|
| **Email (Resend)** | ❌ `RESEND_API_KEY` vacío | Crear cuenta en resend.com, poner la API key en `.env` y Fly.io. Sin esto NO se envían verificaciones ni recuperación de contraseña. |
| **Subida de imágenes (Cloudinary)** | ❌ credenciales vacías | Crear cuenta en cloudinary.com, completar `CLOUDINARY_*`. Sin esto no se suben fotos de servicios/perfil. |
| **MercadoPago producción** | 🟡 solo sandbox | Cambiar `MP_ACCESS_TOKEN` por el token de producción (`APP_USR-...`) cuando esté listo para cobrar de verdad. |
| **Webhook de MercadoPago** | 🟡 verificar | Confirmar que `BACKEND_URL` en Fly.io apunta a la URL pública para que lleguen los webhooks de pago. |
| **CORS** | 🟡 restringir | Hoy permite el dominio de Vercel. Si cambia la URL del front, actualizar `CORS_ORIGINS` en Fly.io. |
| **Dominio propio** | ❌ | Opcional: comprar dominio y apuntarlo a Vercel (front) y Fly.io (API). |
| **Migraciones (Alembic)** | ❌ | Hoy se usa `recreate_db.py`. Para no perder datos en cambios de esquema, configurar Alembic. |
| **Tests automatizados** | 🟡 parcial | Hay tests en `test/`. Ampliar cobertura antes de release. |

---

## 7. Publicar la app (Google Play / App Store)

La app Flutter ya soporta Android e iOS. Datos actuales:
- **Application ID**: `com.trabajoya.trabajoya_app`
- **Versión**: `1.0.0+1` (en `pubspec.yaml` → `version: X.Y.Z+build`)

### 7.1 Google Play Store (Android)

**Requisitos previos**
1. Cuenta de **Google Play Console** (pago único de USD 25): play.google.com/console
2. Íconos y splash configurados, capturas de pantalla, política de privacidad (URL pública).

**Pasos**
1. **Generar clave de firma** (keystore) — una sola vez:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Guardar el `.jks` en lugar seguro (NO subir a git).
2. Crear `trabajoya-app/android/key.properties`:
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
3. Configurar la firma en `android/app/build.gradle.kts` (sección `signingConfigs` + `release`).
4. Subir la versión cuando haya cambios: editar `version:` en `pubspec.yaml` (ej. `1.0.1+2`).
5. **Compilar el App Bundle** (formato que pide Google):
   ```bash
   flutter build appbundle --release
   ```
   Genera `build/app/outputs/bundle/release/app-release.aab`.
6. En Play Console: crear la app → completar ficha (descripción, capturas, clasificación, privacidad) → subir el `.aab` en **Producción** o **Testing interno** primero.
7. Enviar a revisión (puede tardar días).

### 7.2 App Store (iOS)

**Requisitos previos**
1. **Mac** con Xcode (obligatorio para compilar iOS).
2. **Apple Developer Program** (USD 99/año): developer.apple.com.

**Pasos**
1. En Mac: `cd trabajoya-app && flutter build ipa --release`
2. Abrir `ios/Runner.xcworkspace` en Xcode, configurar **Signing & Capabilities** (Team de Apple Developer).
3. Subir con **Xcode → Product → Archive** o con Transporter.
4. En **App Store Connect**: crear la app, completar ficha, capturas, privacidad.
5. Enviar a revisión de Apple.

> Sin Mac no se puede compilar iOS. Alternativa: usar un servicio de CI con macOS (Codemagic, GitHub Actions con runner macOS).

### 7.3 Checklist antes de publicar
- [ ] Email (Resend) y upload (Cloudinary) configurados.
- [ ] MercadoPago en **producción** (no sandbox).
- [ ] Ícono y splash definitivos.
- [ ] Política de privacidad publicada (URL).
- [ ] Probar flujo completo en dispositivo real.
- [ ] Subir número de versión en `pubspec.yaml`.

---

## 8. Comandos rápidos (cheatsheet)

```bash
# --- Backend ---
cd trabajoya-api
uvicorn app.main:app --reload          # levantar local
git add . && git commit -m "x" && git push   # deploy a Fly.io
python recreate_db.py --drop           # resetear BD (¡destructivo!)

# --- Frontend ---
cd trabajoya-app
flutter pub get                        # instalar deps
flutter run -d chrome                  # correr en web
flutter build web --release            # build web
flutter build appbundle --release      # build Android (Play Store)
flutter build ipa --release            # build iOS (Mac, App Store)
flutter analyze                        # chequear errores de código
flutter test                           # correr tests
```

---

## 9. Enlaces clave

- API producción: https://web-production-3bcbe.up.Fly.io.app
- API docs (Swagger): https://web-production-3bcbe.up.Fly.io.app/docs
- Front web: https://flutter-web-deploy-rho.vercel.app
- Fly.io: https://Fly.io.app (dashboard del backend)
- Supabase: https://supabase.com (dashboard de la BD)
- Vercel: https://vercel.com (dashboard del front)
