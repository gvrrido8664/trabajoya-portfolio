# Plan de rediseño — Flujo del CLIENTE (TrabajoYa app)

> **Para la IA implementadora:** este documento es un spec accionable. Implementá en el
> orden del checklist final. El flujo del **cliente se mantiene CLARO** (contraste deliberado
> con el flujo del **proveedor**, que ya está en oscuro premium — `lib/features/proveedor/widgets/pro_ui.dart`).
> **No toques el flujo del proveedor.** Reutilizá el sistema de diseño existente (`AppTheme`)
> y los widgets compartidos; no recrees lo que ya existe. Después de cada bloque corré
> `flutter analyze` y dejalo sin issues.

---

## 1. Objetivo y principios

Hacer que el flujo del cliente se vea **profesional, claro y coherente**, y que **funcione de
verdad** (hoy hay buscadores muertos y datos hardcodeados).

Principios obligatorios:
1. **Cero datos demo/hardcodeados** en pantallas reales. Todo viene de la API.
2. **Reutilizar tokens** de `lib/app/theme.dart` (`AppTheme.*`). Prohibido `AppColors.*`
   suelto o `Colors.grey[300]` para bordes (usar `AppTheme.border`).
3. Cada pantalla con sus 3 estados: **loading** (`SkeletonLoader`), **vacío/error**
   (`EmptyStateWidget`), y **contenido**.
4. **Identidad clara "premium"**: superficies blancas, bordes sutiles `AppTheme.border`,
   sombras suaves, esquinas 14–16px, mucho aire, jerarquía tipográfica fuerte (Inter, ya en
   el theme). Acento principal `AppTheme.primary` (#1565C0); naranja `AppTheme.secondary`
   solo para ratings/CTAs secundarios.
5. Ningún `onPressed: () {}` ni `onSubmitted` que no haga nada.

---

## 2. Kit de diseño claro — crear `lib/features/cliente/widgets/cli_ui.dart`

Espeja la idea de `pro_ui.dart` pero en **claro**. Una sola fuente de verdad para el look del
cliente. Exporta:

- **`CliColors`** (derivados de `AppTheme`, no redefinir hex sueltos):
  `bg = AppTheme.background`, `surface = Colors.white`, `border = AppTheme.border`,
  `textPrimary = AppTheme.textPrimary`, `textSecondary = AppTheme.textSecondary`,
  `accent = AppTheme.primary`, `secondary = AppTheme.secondary`, `success = AppTheme.success`.
- **`CliCard`** — contenedor: `surface` + `Border.all(color: border)` + sombra suave
  (`Colors.black.withValues(alpha: 0.05)`, blur 12, offset (0,4)) + radius 16 + `InkWell`
  opcional (`onTap`). Equivalente claro de `ProCard`.
- **`CliSectionHeader`** — barrita de acento 3px + título w700 + acción opcional ("Ver todas").
  Igual estructura que `ProSectionHeader`.
- **`CliQuickAction`** — tarjeta icono+label (para accesos rápidos si se usan), fondo blanco,
  borde sutil, icono en chip de acento tenue.
- **`CliCategoryChip`** — chip de categoría con icono+color por slug (ver §3.8).
- **`CliStatPill`** / badge reutilizable para conteos y estados (envuelve color+label).

Para loading/empty/error **reutilizar** `EmptyStateWidget` (`lib/widgets/empty_state_widget.dart`)
y `SkeletonLoader` (`lib/widgets/skeleton_loader.dart`) — ya soportan el tema claro.

> Referencia de estilo: copiar la *estructura* de los componentes de
> `lib/features/proveedor/widgets/pro_ui.dart` (ProCard, ProSectionHeader, ProQuickAction)
> y portarla a colores claros. No importar `pro_ui.dart` desde el flujo cliente.

---

## 3. Cambios pantalla por pantalla

### 3.1 `lib/features/cliente/screens/cliente_shell.dart`
**Estado:** nav de 5 tabs (Buscar, Mis Solicitudes, Contrataciones, Chat, Perfil), ya claro y
correcto.
**Cambios:** mínimos. Asegurar consistencia con el kit (mismos colores de activo/inactivo,
`AppTheme.primary` activo). Mantener badge de no leídos en Chat (ya existe vía `ChatProvider`).
**Aceptación:** sin cambios de comportamiento; visual consistente.

### 3.2 `lib/features/cliente/screens/cliente_landing_screen.dart` (HOME — marketplace mejorado)
**Estado:** hero con buscador que **no busca** (solo navega), 6 quick-chips hardcodeados,
`CategoriaGrid` con 10 categorías hardcodeadas, sección de servicios real (`ServiciosService`).
**Cambios:**
1. **Buscador real en el hero:** el `TextField` debe, en `onSubmitted`, navegar a la pantalla
   de búsqueda **pasando el query** para que filtre de verdad:
   `context.push('/cliente/buscar?q=${Uri.encodeComponent(texto)}')` (ver §3.3 para recibir
   el query). El icono de filtros (`tune`) abre la misma pantalla. Nada de navegar sin query.
2. **Categorías desde API (origen único):** eliminar las 6 quick-chips hardcodeadas y la lista
   hardcodeada del grid. Cargar `GET /api/v1/categorias` una sola vez y alimentar tanto los
   chips rápidos como `CategoriaGrid`. Cada categoría navega a buscar **filtrando por esa
   categoría**: `/cliente/buscar?categoria_id=<id>` (o `?cat=<slug>`).
3. **Sección "Proveedores destacados"** (nueva, datos reales): usar `GET /api/v1/proveedores/top?limit=10`
   (ver `trabajoya-api/API_REFERENCE.md` §4.12). Mostrar tarjetas horizontales con avatar,
   nombre, rating (★) y nº de trabajos. Tap → perfil/servicios del proveedor
   (`/servicio/...` o un futuro `/proveedor/:id`; si no existe ruta de perfil público, enlazar
   a sus servicios vía búsqueda). Si la lista viene vacía → ocultar la sección (no inventar).
4. **Servicios disponibles:** mantener la carga real; usar `ServicioCard`
   (`lib/features/public/widgets/servicio_card.dart`) en vez de la tarjeta inline duplicada.
5. Envolver secciones con `CliSectionHeader` y `CliCard`. Mantener el hero con gradiente
   pero derivando colores de `AppTheme.primary`/`primaryDark` (no hex sueltos).
6. Quitar **todo** handler vacío.
**Copy sugerido:** hero "¿Qué necesitás hoy?" / "Encontrá profesionales verificados cerca
tuyo". Secciones: "Categorías", "Proveedores destacados", "Servicios disponibles".
**Aceptación:** el buscador filtra de verdad; las categorías salen de la API; no hay nombres
de proveedores/reseñas inventados; cada sección tiene loading/empty.

### 3.3 `lib/features/servicios/screens/servicios_list_screen.dart` (BUSCAR)
**Estado:** búsqueda client-side, chips de categoría + "Cerca de ti" (PostGIS), estados
loading/error/vacío con `SkeletonList`/`EmptyStateWidget`. Falta orden, paginación, contador,
y no recibe query inicial.
**Cambios:**
1. **Recibir query inicial** desde la ruta (`?q=` y `?categoria_id=`): pre-cargar el campo de
   búsqueda y/o la categoría seleccionada al entrar (la ruta debe declarar estos query params
   en `lib/app/router.dart`).
2. **Orden de resultados:** menú/segmented para ordenar por **precio**, **rating** y
   **distancia** (cuando hay ubicación). Aplicar sobre la lista ya cargada.
3. **Contador de resultados:** "N resultados" arriba de la lista.
4. **Paginación / scroll infinito:** usar `skip`/`limit` de `GET /api/v1/servicios` y/o
   `/servicios/buscar` (ver `API_REFERENCE.md` §4.3) cargando más al llegar al final
   (`ScrollController` + `getServicios` con offset). Evitar traer todo de una.
5. **"Cerca de ti":** mostrar el **radio km real** activo en el chip (ej. "Cerca de ti · 10 km")
   y permitir cambiarlo.
**Aceptación:** entrar desde el hero con texto filtra; hay orden y contador; el scroll pagina;
"Cerca de ti" muestra el radio.

### 3.4 `lib/features/servicios/screens/servicio_detail_screen.dart` (DETALLE)
**Estado:** galería, precio "boleta incluida", card proveedor con badge verificado (rating
≥ 4.5), chips de info, CTA "Contratar". Buen estado.
**Cambios:** copy **"Contratar" → "Solicitar servicio"** (más claro). Pulir con el kit
(`CliCard` para la card del proveedor, `CliSectionHeader` para "Descripción"). Mantener el
bottom sheet de ayuda. No cambiar la lógica.
**Aceptación:** CTA dice "Solicitar servicio"; visual coherente con el kit.

### 3.5 `lib/features/servicios/screens/solicitar_servicio_screen.dart` (SOLICITAR)
**Estado:** form con mensaje (req), monto (opc), fecha (opc). Usa `AppColors.*` y
`Colors.grey[300]` (inconsistente), copy genérico, sin confirmación.
**Cambios:**
1. **Migrar tokens:** todo `AppColors.*`/`Colors.grey[300]` → `AppTheme.*` (`border`, `surface`,
   `secondary`, `success`). Inputs con el `inputDecorationTheme` global (no estilos sueltos).
2. **Diferenciar opcionales:** etiquetar monto y fecha como "(opcional)".
3. **Presupuesto sugerido:** si el servicio tiene `precioMin/precioMax`, mostrar un hint
   ("Sugerido: $X – $Y") y/o prellenar el campo monto.
4. **Confirmación previa:** antes de enviar, un diálogo/bottom-sheet de resumen ("Vas a enviar
   esta solicitud a <proveedor>") con botón confirmar.
**Aceptación:** sin `AppColors`; opcionales claros; hay sugerencia de precio y confirmación.

### 3.6 `lib/features/cliente/screens/crear_solicitud_screen.dart` (CREAR SOLICITUD)
**Estado:** 5 campos (categoría, título, descripción — req; presupuesto, ubicación — opc).
Categorías reales desde API. Ubicación manual.
**Cambios:**
1. **Aligerar densidad** y marcar opcionales claramente; agrupar visualmente (lo esencial
   arriba).
2. **Ayuda contextual:** micro-textos ("Una buena descripción recibe más propuestas").
3. **Geolocalización opcional** para "ubicación": botón "Usar mi ubicación" reutilizando la
   lógica de permisos/GPS que ya existe en `servicios_list_screen.dart` (`_buscarCercanos`),
   manteniendo el campo de texto como fallback.
4. Validación inline clara.
**Aceptación:** form menos denso, opcionales evidentes, opción de geolocalización.

### 3.7 `lib/features/cliente/screens/mis_solicitudes_screen.dart` (MIS SOLICITUDES)
**Estado:** lista real (`SolicitudesService.getMisSolicitudes()`), cards con estado, FAB
"Nueva Solicitud". Sin filtros.
**Cambios:** agregar **fila de chips de filtro por estado** (Todas / Abierta / Cerrada…) usando
`AppTheme.statusColor` y `AppTheme.statusLabel` para el color/label. Filtrar la lista en
cliente. Pulir cards con `CliCard`.
**Aceptación:** se puede filtrar por estado; visual coherente.

### 3.8 `lib/features/public/widgets/categoria_grid.dart` (REFACTOR — quitar hardcodeo)
**Estado:** 10 categorías hardcodeadas (nombre/icono/color) dentro del widget.
**Cambios:** que el widget **reciba la lista de categorías** (del modelo `Categoria`, desde
API) en vez de tenerlas fijas. Mapear **icono y color por `slug`** mediante un helper con
**fallback** (icono genérico + color neutro) para slugs desconocidos. Así el grid y los
quick-chips del landing comparten el mismo origen.
**Aceptación:** el grid se alimenta de la API; sin lista hardcodeada; slugs nuevos no rompen.

---

## 4. Datos / endpoints a usar

Referencia completa: `trabajoya-api/API_REFERENCE.md`.
- **Categorías:** `GET /api/v1/categorias` → `[{id, nombre, slug, icono, descripcion}]`.
- **Proveedores destacados:** `GET /api/v1/proveedores/top?limit=10` → `[{id, nombre, avatar_url, avg_rating, bio, total_contratos}]`.
- **Servicios (listar/paginar):** `GET /api/v1/servicios?categoria_id&skip&limit`.
- **Búsqueda geo:** `GET /api/v1/servicios/buscar?lat&lng&radio_km&categoria_id&skip&limit` (incluye `distancia`).
- **Mis solicitudes:** `GET /api/v1/solicitudes/mis-solicitudes`.

Servicios Flutter existentes a reutilizar: `ServiciosService` (`lib/services/servicios_service.dart`),
`SolicitudesService` (`lib/services/solicitudes_service.dart`). **Agregar** si faltan:
`getCategorias()` y `getTopProveedores({int limit})` (siguiendo el patrón de `ApiClient`).

---

## 5. Reutilización obligatoria (no recrear)
- `lib/widgets/empty_state_widget.dart` — estados vacío/error.
- `lib/widgets/skeleton_loader.dart` — loading (`SkeletonList`, `SkeletonDetail`).
- `lib/features/public/widgets/servicio_card.dart` — tarjeta de servicio (usar en landing y
  buscar; eliminar tarjetas inline duplicadas).
- `lib/app/theme.dart` — `AppTheme.*`, `statusColor`, `statusLabel`.
- Lógica de GPS/permisos ya presente en `servicios_list_screen.dart`.

---

## 6. Criterios de aceptación / verificación
- `flutter analyze` **sin issues** en los archivos tocados.
- Recorrido cliente end-to-end: home → tipear en el hero → **buscar filtra por ese texto** →
  tocar categoría → **buscar filtra por categoría** → abrir servicio → **"Solicitar servicio"**
  con resumen/confirmación → crear solicitud (con geolocalización opcional) → Mis Solicitudes
  con filtros por estado.
- **No** quedan datos hardcodeados (proveedores/reseñas/categorías inventadas) ni handlers
  vacíos.
- El flujo del **proveedor sigue intacto** (oscuro) y el del **cliente sigue claro**.

---

## 7. Checklist de implementación (en orden)
1. [ ] Crear `lib/features/cliente/widgets/cli_ui.dart` (kit claro).
2. [ ] Agregar `getCategorias()` y `getTopProveedores()` a los services si faltan.
3. [ ] Refactor `categoria_grid.dart` para recibir categorías dinámicas (mapeo por slug).
4. [ ] Rediseñar `cliente_landing_screen.dart` (buscador real, categorías API, destacados,
       `ServicioCard`, sin handlers muertos).
5. [ ] Declarar query params `q`/`categoria_id` en la ruta `/cliente/buscar` (`router.dart`)
       y consumirlos en `servicios_list_screen.dart` (+ orden, contador, paginación, radio km).
6. [ ] `servicio_detail_screen.dart` (copy "Solicitar servicio" + kit).
7. [ ] `solicitar_servicio_screen.dart` (tokens AppTheme, opcionales, presupuesto sugerido,
       confirmación).
8. [ ] `crear_solicitud_screen.dart` (densidad, ayuda, geolocalización opcional).
9. [ ] `mis_solicitudes_screen.dart` (filtros por estado).
10. [ ] `cliente_shell.dart` (pulido de consistencia).
11. [ ] `flutter analyze` y corregir; probar el recorrido completo.
