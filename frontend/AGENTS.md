## Goal actual (2026-08-05): restyle visual completo de la app

**Iniciativa activa.** Plan aprobado en
`docs/Importante/plan-restyle-app-completa.md` — léelo COMPLETO antes de tocar
cualquier pantalla o token de color/tipografía/radio. Migra toda la app (auth,
cliente, proveedor, admin, landing) al lenguaje visual "orden de trabajo"
definido en los mockups de `design-concepts/` (fondo papel, tinta navy, acento
óxido, bordes finos de 1px sin sombras, marcas de esquina en L). Es un
*restyle*, no una reescritura: toda la funcionalidad/ruteo/API real se
conserva.

**Esto reemplaza y deroga las siguientes reglas de la sección "Goal anterior"
de abajo, que quedaron obsoletas y CONTRADICEN el plan nuevo:**
- ~~"Register cambia colores según rol (Cliente → verde, Proveedor → azul)"~~
  → el plan (Fase 4) elimina esa divergencia explícitamente: la opción de rol
  activa se pinta en tinte óxido para ambos roles, igual que el mockup.
- ~~"`withOpacity` preferido sobre `withValues`"~~ → usar `withValues`
  (`withOpacity` está deprecado; el código ya migró a `withValues` en la
  mayoría de sitios y el restyle toca cientos de literales de color).

El resto de este documento (Goal anterior, Progress, Key Decisions, Critical
Context, Relevant Files) documenta una iniciativa **ya completada** (categorías
jerárquicas + auth conectado al backend real). Se conserva como contexto
histórico/técnico porque sigue siendo información válida sobre cómo funciona el
backend y el modelo de datos — pero ninguna de sus preferencias visuales aplica
al restyle en curso.

---

## Goal anterior (completado)
- Rediseño completo del flujo Cliente conectado al backend real, incluyendo categorías jerárquicas con subcategorías, login/register funcional, y búsqueda por tipo de categoría.

## Constraints & Preferences (del goal anterior — ver derogaciones arriba)
- Todos los usuarios test usan password `test123` hasheado con bcrypt.
- Categorías jerárquicas: raíces en tabla `categorias`, subcategorías en tabla `subcategorias` (FK `categoria_id` → `categorias.id`).
- Hero chips = categorías raíz (tipos). Al tocarlos, navega a `/cliente/buscar?q=<raiz.nombre>` buscando servicios de todas sus subcategorías.
- Dropdown en crear_solicitud/crear_servicio: 2 niveles (tipo → subcategoría).
- Login/Register conectados al backend real.
- Rol en register debe enviarse en minúsculas ("cliente"/"proveedor").

## Progress
### Done
- **API Client:** Agregado timeout de 15s a todas las requests HTTP (`_request()` wrapper).
- **Login Screen:** Navegación explícita a `/cliente`, `/proveedor`, o `/admin` tras login exitoso. Reemplazó el `_handleLogin` anterior para llamar `auth.login()` real con loading/error en SnackBar.
- **Register Screen:** Rol corregido a minúsculas (`'cliente'`/`'proveedor'`). Navegación explícita tras registro exitoso.
- **Backend:** Migración `a1b2c3d4e5f6` agrega `parent_id` (UUID nullable, FK) a `categorias`. Ya aplicada en Supabase.
- **Backend:** Migración `d77c7427c0a4` crea tabla `subcategorias`, migra datos desde `categorias.parent_id`, dropea columna `parent_id` de `categorias`, agrega FK `servicios.subcategoria_id → subcategorias.id`.
- **Backend:** `models/categoria.py` — sin `parent_id` (columna eliminada por migración). Solo raíces.
- **Backend:** `models/subcategoria.py` — tabla `subcategorias`, FK `categoria_id → categorias.id`.
- **Backend:** `schemas/categoria.py` — campo `parent_id: UUID | None` (se mantiene para compatibilidad frontend, se mapea desde `sub.categoria_id`).
- **Backend:** `routes_categorias.py` — `GET /categorias` construye tree desde `Categoria` (raíces) + `Subcategoria` (hijas). `GET /categorias/{id}/subcategorias` consulta `Subcategoria`.
- **Backend:** `routes_contrataciones.py` — usa `servicio.categoria` (raíz directa) + `servicio.subcategoria` en vez del antiguo `parent_id`.
- **Backend:** `routes_servicios.py` — `listar_servicios` y `buscar_servicios_cercanos` aceptan `categoria_padre_id` para filtrar servicios de todas las subcategorías de una raíz.
- **Backend:** Seed nuevo `scripts/seed_50_categorias.py` — 50 raíces + 500 subcategorías (10 c/u). Ejecutado en Supabase. Ya no usa `Categoria.parent_id`.
- **Frontend:** `categoria_model.dart` — `parentId` tolera string vacío como `null` (compatibilidad con Backend antiguo que devuelve `parent_id: ""` en vez de `parent_id: null`).
- **Frontend:** `servicios_provider.dart` — getter `categoriasRaiz`, método `subcategoriasDe(String?)`, soporte `categoriaPadreId` en `cargarServicios`/`cargarMas`/`buscarCercanos`.
- **Frontend:** `servicios_remote_datasource.dart` — `categoriaPadreId` en `getServicios` y `buscarServicios`.
- **Frontend:** `cliente_landing_screen.dart` — hero chips usan `categoriasRaiz.take(5)` con `onTap` a `/cliente/buscar?q=...`; `_CategoryGrid` usa `.take(27)`.
- **Frontend:** `categorias_list_screen.dart` — reescrito con raíces expandibles/colapsables in-place, cada hija navega a `/cliente/buscar?q=...`.
- **Frontend:** `crear_solicitud_screen.dart` — 2 dropdowns anidados: tipo (raíces) → subcategoría. Segundo dropdown solo se muestra cuando `_categoriaPadreId != null`.
- **Frontend:** `crear_editar_servicio_screen.dart` — mismos 2 dropdowns anidados.
- **Frontend:** `servicios_list_screen.dart` — filter chips usan `categoriasRaiz`, selección envía `categoriaPadreId` al backend.
- **Frontend:** `mock_data.dart` — categorías mock con `parent_id` y raíces.

### In Progress
- *(none)*

### Blocked
- *(none)*

## Key Decisions
- "Ver todas" en landing usa `context.push('/cliente/categorias')` (push, no go) para que AppBar muestre back button automáticamente.
- Hero chips onTap navega a `/cliente/buscar?q=<raiz.nombre>` buscando por texto (no `categoria_padre_id`) porque el backend no necesita filtrar por ID de raíz cuando se busca por texto.
- Categorías hijas en la BD se referencian por slug del padre (no por UUID) para legibilidad del seed.
- El seed recrea toda la BD (truncate + insert) para evitar conflictos de UUIDs entre raíces y subcategorías.
- Login/Register navegan explícitamente (`context.go(...)`) porque el redirect del router usa `context.read()` (no `watch`) y no se re-evalúa automáticamente tras cambios en `AuthProvider`.
- El Backend antiguo backend devuelve `parent_id` como `""` (string vacío) en vez de `null`. `Categoria.fromJson` normaliza ambos casos a `null`.

## Next Steps
- Probar login/register contra backend en vivo. Si el backend está caído, timeout de 15s mostrará SnackBar con error.
- `value` deprecated en `DropdownButtonFormField` → migrar a `initialValue` en próxima refactor.

## Critical Context
- Backend `hash_password` es async (usa `bcrypt` con `asyncio.to_thread`).
- `StatefulShellRoute.indexedStack` preserva estado del widget al cambiar query params → no se puede confiar en `initState` para leer `?q=`.
- `CliColors.accent` = `AppTheme.primary`, `CliColors.success` = `AppTheme.success`.
- `ProveedorTop` model existe en `servicios/data/models/`.
- `SolicitudesProvider` expone: `cargarMisSolicitudes()`, `crearSolicitud()` (devuelve bool), `cerrarSolicitud()` (devuelve bool), `error`, `loading`, `misSolicitudes`.
- Para el login, el router ya tiene redirect basado en `auth.isLoggedIn` y `auth.usuario.rol` en `router.dart:47-74`.
- ApiClient ahora tiene timeout de 15s. TimeoutException se convierte en `ApiException(408, ...)`.
- Rol en registro debe enviarse en minúsculas ("cliente"/"proveedor") según schema `RegistroRequest` del backend. Ya corregido en `register_screen.dart:66`.
- Backend antiguo devuelve `parent_id` como `""` (no `null`). El frontend normaliza en `Categoria.fromJson`.
- Backend antiguo NO respeta `?raices=true` (probablemente código desactualizado). El frontend filtra localmente con `categoriasRaiz`.

## Relevant Files
- `trabajoya-api/app/api/routes_auth.py`: `/auth/login` y `/auth/register`
- `trabajoya-api/app/api/routes_auth.py`: `/auth/login` y `/auth/register`
- `trabajoya-api/app/api/routes_categorias.py`: GET /categorias, GET /categorias/{id}/subcategorias
- `trabajoya-api/app/api/routes_servicios.py`: soporta `categoria_padre_id` en listar y buscar
- `trabajoya-api/app/api/routes_contrataciones.py`: usa `servicio.categoria` + `servicio.subcategoria`
- `trabajoya-api/app/models/categoria.py`: sin parent_id
- `trabajoya-api/app/models/subcategoria.py`: tabla subcategorias, FK categoria_id
- `trabajoya-api/app/schemas/categoria.py`: parent_id en CategoriaResponse (compatibilidad frontend)
- `trabajoya-api/migrations/versions/a1b2c3d4e5f6_add_parent_id_to_categorias.py`: agrega parent_id
- `trabajoya-api/migrations/versions/d77c7427c0a4_create_subcategorias_table_drop_parent_.py`: crea subcategorias, elimina parent_id
- `trabajoya-api/scripts/seed_50_categorias.py`: 50 raíces + 500 subcategorías (10 c/u). Ejecutado en Supabase.
- `trabajoya-app/lib/features/auth/presentation/pages/login_screen.dart`: login real con timeout, error, navegación post-login
- `trabajoya-app/lib/features/auth/presentation/pages/register_screen.dart`: colores por rol, register real, navegación post-registro
- `trabajoya-app/lib/features/auth/presentation/providers/auth_provider.dart`: login/register ya funcionales
- `trabajoya-app/lib/features/auth/data/datasources/auth_remote_datasource.dart`: login obtiene token, llama getMe()
- `trabajoya-app/lib/core/api/api_client.dart`: timeout 15s en todas las requests
- `trabajoya-app/lib/features/auth/data/models/usuario_model.dart`: parentId, esRaiz
- `trabajoya-app/lib/features/servicios/data/models/categoria_model.dart`: parentId tolera `""` como `null`
- `trabajoya-app/lib/features/servicios/presentation/providers/servicios_provider.dart`: categoriasRaiz, subcategoriasDe(), categoriaPadreId
- `trabajoya-app/lib/features/cliente/presentation/pages/cliente_landing_screen.dart`: hero chips = raíces, onTap busca subcats, _CategoryGrid limitado a 27
- `trabajoya-app/lib/features/cliente/presentation/pages/categorias_list_screen.dart`: raíces expandibles/colapsables
- `trabajoya-app/lib/features/cliente/presentation/pages/crear_solicitud_screen.dart`: 2 dropdowns (tipo → subcategoría) con guard `_categoriaPadreId != null`
- `trabajoya-app/lib/features/servicios/presentation/pages/crear_editar_servicio_screen.dart`: 2 dropdowns (tipo → subcategoría)
- `trabajoya-app/lib/features/servicios/presentation/pages/servicios_list_screen.dart`: filter chips = raíces, categoriaPadreId
- `trabajoya-app/lib/core/api/mock_data.dart`: categorías mock con parent_id
