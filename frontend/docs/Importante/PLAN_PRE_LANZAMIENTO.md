# Plan integral TrabajoYa — Pre-lanzamiento

> Fecha: 2026-06-21
> Stack: Flutter (Vercel Web + Play Store) · FastAPI (Fly.io) · PostgreSQL (Supabase sa-east-1)

---

## 1. Backend (FastAPI — Fly.io)

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 1.1 | JWT secret production | Generar clave aleatoria segura y setearla solo en Fly.io secrets (no en .env local) | 🔴 |
| 1.2 | DEBUG=false en Fly.io | `DEBUG` debe ser `false` en producción | 🔴 |
| 1.3 | CORS restringido | Cambiar de `["*"]` a `["https://flutter-web-deploy-rho.vercel.app"]` | 🔴 |
| 1.4 | Rate limiting | Agregar `slowapi` o middleware similar | 🟡 |
| 1.5 | Health check mejorado | Endpoint `/health` con estado DB, versión, uptime | 🟢 |
| 1.6 | MercadoPago producción | Reemplazar credenciales TEST por token PRO | 🔴 |
| 1.7 | Cloudinary | Setear `CLOUDINARY_CLOUD_NAME`, `API_KEY`, `API_SECRET` en Fly.io | 🟡 |
| 1.8 | Resend (emails) | Setear `RESEND_API_KEY` para emails transaccionales | 🟡 |
| 1.9 | Webhook MP en Fly.io | Exponer endpoint y configurar MP | 🟡 |

## 2. Frontend (Flutter — Vercel Web + Play Store)

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 2.1 | Nombre app Android | `AndroidManifest.xml: android:label` → `"TrabajoYa"` | 🔴 |
| 2.2 | Nombre app iOS | `Info.plist: CFBundleDisplayName` → `"TrabajoYa"` | 🔴 |
| 2.3 | Keystore firma Android | Generar `upload-keystore.jks` y configurar release signing | 🔴 |
| 2.4 | Icono app | Reemplazar default icons en `mipmap-*` con logo TrabajoYa | 🔴 |
| 2.5 | Splash screen | Personalizar `launch_background.xml` | 🟡 |
| 2.6 | Android permissions | Revisar si `ACCESS_FINE_LOCATION` es necesario | 🟡 |
| 2.7 | iOS signing | Configurar certificates + provisioning profile | 🔴 |
| 2.8 | CI/CD Android | GitHub Action que genere AAB en cada tag/release | 🟡 |
| 2.9 | CI/CD iOS | GitHub Action build + TestFlight (requiere macOS runner) | 🟢 |
| 2.10 | Onboarding | Pantalla de intro primera vez que abre la app | 🟢 |
| 2.11 | Deep linking | Configurar enlaces profundos (reset-password, etc.) | 🟢 |
| 2.12 | Error handling | Mensajes de error amigables para el usuario final | 🟡 |
| 2.13 | Probar en Android físico | `flutter run --release` en dispositivo real | 🔴 |

## 3. Base de datos (Supabase)

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 3.1 | Seed usuarios | Ejecutar `trabajoya-api/seed_usuarios_prueba.sql` en SQL Editor | 🔴 |
| 3.2 | Backup schedule | Backup diario (incluido en free tier point-in-time recovery) | 🟡 |
| 3.3 | Índices faltantes | Revisar queries lentas con `pg_stat_statements` | 🟢 |
| 3.4 | Pooler limits | Verificar límite free (5 conexiones concurrentes) | 🟡 |

## 4. Infraestructura

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 4.1 | Fly.io secrets | Mover variables sensibles a Fly.io dashboard (no en .env local) | 🔴 |
| 4.2 | Dominio personalizado | Comprar (`trabajoya.cl`) y apuntar Fly.io + Vercel | 🟡 |
| 4.3 | SSL/TLS | Verificar HTTPS activo en Fly.io y Vercel (auto) | 🟢 |
| 4.4 | Monitoreo | Uptime monitor (uptimerobot, betterstack gratis) | 🟡 |

## 5. Config & Secrets

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 5.1 | JWT_SECRET_KEY producción | `openssl rand -hex 32`, setear solo en Fly.io | 🔴 |
| 5.2 | CORS_ORIGINS producción | Fly.io: `["https://flutter-web-deploy-rho.vercel.app"]` | 🔴 |
| 5.3 | FRONTEND_URL | Ya apunta a Vercel ✅ | 🟢 |
| 5.4 | BACKEND_URL | Ya apunta a Fly.io ✅ | 🟢 |
| 5.5 | MP_ACCESS_TOKEN producción | Reemplazar TEST por token PRO | 🔴 |

## 6. Testing

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 6.1 | Tests backend | Ejecutar suite existente con `pytest` | 🟡 |
| 6.2 | Tests frontend | `flutter test` y verificar que pasen | 🟡 |
| 6.3 | Flujo completo E2E | registro → login → crear servicio → contratar → pagar → reseña | 🟡 |

## 7. Play Store Launch

| # | Tarea | Detalle | Prioridad |
|---|-------|---------|-----------|
| 7.1 | Cuenta desarrollador | Crear cuenta Google Play (USD 25 única vez) | 🔴 |
| 7.2 | Ficha Play Store | Descripción, capturas, feature graphic | 🔴 |
| 7.3 | Política de privacidad | Crear y hostear URL (puede ser en Vercel) | 🔴 |
| 7.4 | Content rating | Cuestionario de clasificación de contenido | 🔴 |
| 7.5 | Testing interno | Subir AAB y probar con cuenta interna | 🔴 |
| 7.6 | Closed track | Release cerrada con testers antes de producción | 🟡 |
| 7.7 | Production release | Publicar en producción | 🟡 |

---

## Prioridades inmediatas (rojas)

1. Seed de usuarios en Supabase
2. JWT_SECRET production en Fly.io
3. CORS restringido a dominio Vercel
4. DEBUG=false en Fly.io
5. Keystore firma Android + nombre app + ícono
6. Política de privacidad (requisito Play Store)
7. MercadoPago producción
8. Prueba en Android físico
