# Auditoría UI/UX Maestra — TrabajoYa (lado Cliente)

> **Fecha:** 2026-07-08 · **Alcance:** frontend Flutter (`lib/`), foco en flujo Cliente + sistema compartido. Read-only: ningún cambio de código aplicado.
> **Método:** lectura directa del código (tema, tokens, kits, shells, pantallas) + escaneo cuantitativo con grep sobre `lib/` completo. Cada hallazgo cita archivo/línea. Los supuestos no verificados están marcados como **[NO VERIFICADO]**.
> **Relación con docs previos:** complementa `docs/AUDITORIA_UX.md` (auditoría de conversión, pasada visual) y `FULL_APP_AUDIT_REPORT.md` (auditoría de producción). Este documento es la fuente de verdad **del sistema visual y sus componentes** para el rediseño y el frente Proveedor.

---

## A. Resumen ejecutivo

**Veredicto: sistema de diseño bien diseñado en papel, adoptado a medias en código.** Existe una base excelente (`tokens.dart`, `AppColors`, `AppTheme` M3, `Breakpoints`, kits `cli_ui`/`pro_ui`, DESIGN.md con reglas duras) pero las pantallas la esquivan sistemáticamente: 296 colores hex fuera de los archivos de tokens, ~500 `fontSize:` inline (260 de ellos < 14px), 15 valores distintos de border-radius, 4 implementaciones de skeleton/shimmer y 3 sistemas de breakpoints en paralelo.

**Score de salud (rúbrica técnica 0–4 por dimensión):**

| # | Dimensión | Score | Hallazgo clave |
|---|-----------|-------|----------------|
| 1 | Accesibilidad | 2/4 | Solo 10 usos de `Semantics`; texto blanco sobre ámbar/verde en badges falla 4.5:1; ~73 usos de fontSize ≤ 11 |
| 2 | Performance | 3/4 | Sin problemas graves; pantallas monolíticas de 42–48 KB con `setState` amplio |
| 3 | Theming | 1/4 | Dark mode activado (`ThemeMode.system`) pero roto: cards blancas en dark, kits con colores light constantes |
| 4 | Responsive | 2/4 | `Breakpoints` existe pero conviven 14 cortes ad-hoc (380–1100); `DataTable` en pantallas cliente móviles |
| 5 | Anti-patrones | 2/4 | Bounce `elasticOut` en diálogo de éxito, glow decorativo en header Pro (prohibido por DESIGN.md), paleta paralela en help modal |
| **Total** | | **10/20** | **Aceptable — requiere trabajo significativo antes de escalar al frente Proveedor** |

**Conteo por severidad:** 6 críticos · 9 importantes · 8 mejoras recomendadas.

**Los 5 problemas que más pesan:**
1. **Dark mode a medias en producción** — la app sigue el dark del sistema pero la mayoría de superficies cliente están hardcodeadas en claro (cards blancas, textos oscuros fijos). Usuarios con dark activado ven una mezcla rota hoy.
2. **DESIGN.md y el código divergen en la paleta** — los 8 neutros/semánticos documentados no coinciden con `AppColors`. No hay fuente de verdad real.
3. **Doble `cardTheme` en conflicto** en `theme.dart`: la card efectiva (elevation 6, radius 16, borde, blanco) contradice la especificación (e1, radius 14, sin borde) y rompe dark.
4. **4 sistemas de loading skeleton** y **3+ vocabularios de status badge/color** duplicados.
5. **Tipografía inline masiva** con micro-textos (8.5–11px) que el `textTheme` central no contempla.

**Próximo paso recomendado:** congelar el frente Proveedor hasta cerrar la Fase 1 del plan (sección I): decidir dark mode, unificar tokens, y consolidar los componentes duplicados. Construir Proveedor sobre este suelo multiplica la deuda.

---

## B. Estado general del sistema visual

### Lo que existe (inventario de infraestructura)

| Pieza | Archivo | Estado |
|---|---|---|
| Tokens de spacing/radius/elevación/motion | [tokens.dart](../lib/shared/theme/tokens.dart) | ✅ Bien diseñado; adopción parcial (579 usos de `Spacing.*` vs 128 `EdgeInsets` literales; `Radii.*` casi sin usar) |
| Paleta central | [colors.dart](../lib/utils/colors.dart) | ⚠️ Correcta en estructura, pero **no coincide con DESIGN.md** (ver D-C2) |
| Tema Material 3 (light + dark) | [theme.dart](../lib/app/theme.dart) | ⚠️ Completo pero con conflictos internos (doble cardTheme, colores paralelos `info`/`tertiary`) |
| Tipografía | Inter Variable local (`assets/fonts/InterVariable.ttf`), `textTheme` completo | ✅ Base sólida; ignorada por ~500 `fontSize` inline |
| Breakpoints | [breakpoints.dart](../lib/shared/layout/breakpoints.dart) (600/1024) | ⚠️ Existe pero las pantallas usan 14 cortes ad-hoc propios |
| Kit Cliente | [cli_ui.dart](../lib/features/cliente/presentation/widgets/cli_ui.dart) | ⚠️ Buen API; colores light constantes → rompe dark |
| Kit Proveedor | [pro_ui.dart](../lib/features/proveedor/presentation/widgets/pro_ui.dart) | ⚠️ Paleta `ProColors` completa pero fuera de tokens; incluye glow prohibido |
| Widgets compartidos | `lib/shared/widgets/` (12 archivos) | ⚠️ Mezcla de calidad; duplicación fuerte en loaders |
| Documentación | `DESIGN.md`, `PRODUCT.md` | ⚠️ Buenas reglas, desincronizadas del código |

### Diagnóstico de fondo

El proyecto no tiene un problema de *diseño* — tiene un problema de **gobernanza**: cada pantalla grande (42–48 KB) re-implementa localmente lo que el sistema ya provee (inputs, badges, colores de estado, breakpoints, shimmers). El patrón dominante es "copiar el estilo de la pantalla anterior con ajustes", que es exactamente cómo se produce drift. La sección F documenta lo que sí funciona y debe conservarse.

---

## C. Inventario de patrones y componentes

### C.1 Componentes compartidos (`lib/shared/widgets/`)

| Componente | Archivo | Usos | Evaluación |
|---|---|---|---|
| `CtaButton` (verde transaccional) | cta_button.dart | 3 | ✅ Correcto (52px, loading, expand). Rama `isDark` muerta en [cta_button.dart:31](../lib/shared/widgets/cta_button.dart#L31) (ambos lados devuelven lo mismo) |
| `StatusBadge` | status_badge.dart | ~8 | ❌ Fondo sólido + texto blanco; contradice la spec de DESIGN.md (píldora tintada + punto + label) y falla contraste sobre ámbar |
| `EmptyStateWidget` | empty_state.dart | 8 | ⚠️ Buen API (variantes, 2 acciones, compact) pero visual fuera de sistema: glow blur 40, radius 20, w800/w900, colores light fijos |
| `RatingBadge` | rating_badge.dart | — | ✅ Referencia de cómo hacerlo: tokens, Semantics, icono+texto |
| `SkeletonBox/List/Detail` | skeleton_loader.dart | — | ✅ Theme-aware (pkg shimmer) |
| `ShimmerContainer/DelayedLoader` + `ShimmerServicioCard/List/Grid` | shimmer_loader.dart | — | ⚠️ Sistema paralelo #2; `ShimmerContainer` sí respeta reduced-motion (positivo) |
| `ServiceShimmerCard/Grid` | shimmer_loading.dart | — | ❌ Sistema paralelo #3; blanco/grises hardcodeados, solo light |
| `ServicioCardShared` | servicio_card.dart | — | ⚠️ Buen Semantics; pero pasa `colorScheme.primary` como color de *cualquier* estado al badge ([servicio_card.dart:151-154](../lib/shared/widgets/servicio_card.dart#L151-L154)) |
| `SuccessDialog` | success_dialog.dart | — | ⚠️ Curva `elasticOut` (bounce prohibido), colores light fijos, botón 50px (estándar: 52) |
| `HelpModal` | help_modal.dart | — | ❌ Introduce paleta paralela: indigo #6366F1, naranjo #EA580C, rojo #DC2626, fondos #F8FAFC fijos |
| `ConfettiOverlay` | confetti_overlay.dart | — | ⚠️ Sin manejo de reduced-motion |
| `AvatarEditor` | avatar_editor.dart | — | No auditado en profundidad **[NO VERIFICADO]** |

### C.2 Kit Cliente (`cli_ui.dart`)

- `CliCard` — hover con lift -3px + borde acento, presión +1px. Bien resuelto, pero: `Semantics(label: 'Tarjeta seleccionable', button: true)` se aplica **siempre**, incluso sin `onTap`, y el label genérico pisa el contenido real ([cli_ui.dart:76-78](../lib/features/cliente/presentation/widgets/cli_ui.dart#L76-L78)).
- `CliSectionHeader` — título w700 + barrita acento 3px + acción. Funcional; la barrita es un "mini side-stripe" decorativo (vocabulario a decidir: conservar como firma o eliminar — hoy convive con headers hechos a mano en otras pantallas).
- `CliQuickAction`, `CliCategoryChip`, `CliStatPill` — APIs correctas. `CliStatPill` es el badge **más cercano a la spec** de DESIGN.md; debería ser la base del StatusBadge unificado.
- **Problema estructural del kit:** `CliColors` son `const` claros ([cli_ui.dart:7-18](../lib/features/cliente/presentation/widgets/cli_ui.dart#L7-L18)). Todo lo construido con el kit queda light-only.

### C.3 Shells y navegación

| Shell | Archivo | Patrón |
|---|---|---|
| Cliente | [cliente_shell.dart](../lib/features/cliente/presentation/pages/cliente_shell.dart) | Mobile: `NavigationBar` M3 (5 tabs, badge de no-leídos ✅). Desktop (>800): sidebar custom con **gradiente decorativo** sobre `textDark` |
| Proveedor | proveedor_shell.dart | Shell oscuro propio |
| Admin | [admin_shell.dart](../lib/features/admin/presentation/pages/admin_shell.dart) | Sidebar #0F172A + contenido claro |
| **Legacy** | [app_shell.dart](../lib/shared/layout/app_shell.dart) `HomeScreen` | ❌ Shell viejo con navegación por tabs propia, **aún ruteado en `/home`** ([router.dart:317](../lib/app/router.dart#L317)). Duplica navegación y estilos |

DESIGN.md exige "el **mismo** sidebar navy" para los tres roles; hoy hay **tres sidebars distintos** (gradiente cliente / oscuro proveedor / #0F172A admin).

### C.4 Vocabulario de estados (status)

Cuatro fuentes compitiendo:
1. `AppTheme.statusColor()/statusLabel()` ([theme.dart:49-71](../lib/app/theme.dart#L49-L71)) — la canónica, **casi sin adopción**.
2. `ProColors.status()` ([pro_ui.dart:33-55](../lib/features/proveedor/presentation/widgets/pro_ui.dart#L33-L55)) — mapa distinto (p.ej. `completado`→verde aquí, →azul oscuro en AppTheme).
3. `_statusColor()` locales en admin_pagos, admin_disputas, solicitud_detail (switch propio que devuelve `Colors.grey` como fallback).
4. `ServicioCardShared` que ignora todo y pinta el estado con `primary`.

---

## D. Hallazgos por severidad

### 🔴 Crítico (rompe la experiencia o contradice reglas duras del sistema)

**C1. Dark mode activado pero roto en la mayoría del flujo Cliente**
- **Evidencia:** `themeMode: ThemeMode.system` en [app.dart:63](../lib/app/app.dart#L63); `AppTheme.dark` hereda `_cardTheme()` con `color: Colors.white` ([theme.dart:407-418](../lib/app/theme.dart#L407-L418)) → **cards blancas sobre fondo #0B1120**; `CliColors` const claros; `EmptyStateWidget`, `SuccessDialog`, `HelpModal` con textos/fondos light fijos; `ProfileAmplioScreen` fuerza `backgroundColor: AppColors.background` y pisa el textTheme con colores claros ([profile_screen.dart:84-102](../lib/features/auth/presentation/pages/profile_screen.dart#L84-L102)). Solo 7 archivos consultan `Brightness.dark`.
- **Impacto:** cualquier usuario Android/iOS/web con dark del sistema ve una app parchada: pantallas claras forzadas, cards blancas flotando en fondos oscuros, texto oscuro sobre oscuro (`mis_solicitudes` usa `CliColors.textPrimary` fijo).
- **Recomendación:** decisión binaria inmediata — (a) fijar `ThemeMode.light` hoy (1 línea, honesto con lo implementado) y planificar dark como fase; o (b) prohibir todo color literal y migrar a `Theme.of(context).colorScheme`. No hay opción intermedia defendible.

**C2. La paleta documentada (DESIGN.md) no es la paleta implementada (AppColors)**
- **Evidencia:** DESIGN.md declara success `#0F9D58`, error `#D9304E`, secondary `#E8A317`, bg `#F0F4F8`, surface `#F8FAFB`, texto `#041E2A`/`#6B7280`, border `#DADCE0`. `AppColors` implementa `#10B981`, `#EF4444`, `#F59E0B`, `#F1F5F9`, `#FFFFFF`, `#0F172A`/`#64748B`, `#CBD5E1`. El cuerpo de DESIGN.md además cita `#1A73E8` y `#041E49`, azules marcados como "histórico a eliminar" por su propia regla dura.
- **Impacto:** no existe fuente de verdad; cada decisión nueva puede anclarse al documento equivocado. El frente Proveedor heredaría la ambigüedad.
- **Recomendación:** declarar `lib/utils/colors.dart` como fuente única y regenerar el frontmatter/cuerpo de DESIGN.md desde el código (o viceversa, una sola vez, con decisión explícita).

**C3. Doble `cardTheme` en conflicto dentro del tema**
- **Evidencia:** `_base()` define cards e1/radius 14 ([theme.dart:305-311](../lib/app/theme.dart#L305-L311)) — fiel a DESIGN.md — y luego `light`/`dark` lo pisan con `_cardTheme()`: elevation 6, radius 16, borde, `Colors.white` ([theme.dart:162](../lib/app/theme.dart#L162), [407-418](../lib/app/theme.dart#L407-L418)).
- **Impacto:** toda `Card` de la app viola la regla "flat-at-rest, e1, radius 14, sin borde" de DESIGN.md; y es la causa raíz de las cards blancas en dark (C1).
- **Recomendación:** eliminar `_cardTheme()` o reconciliarlo con la spec; una sola definición.

**C4. Contraste insuficiente en badges de estado sólidos**
- **Evidencia:** `StatusBadge` pinta texto blanco 12px sobre el color recibido ([status_badge.dart:17-30](../lib/shared/widgets/status_badge.dart#L17-L30)). Sobre `secondary` #F59E0B el ratio es ~1.9:1; sobre `success` #10B981 ~2.3:1 (mínimo WCAG AA: 4.5:1 en 12px).
- **Impacto:** los estados — información crítica de un marketplace — son ilegibles para baja visión y en sol directo.
- **Recomendación:** adoptar la spec ya escrita en DESIGN.md §5 (fondo tintado al 10-15% + texto en el color 700 + punto): `CliStatPill` ya la implementa casi exacta.

**C5. Cuatro sistemas de skeleton/shimmer en paralelo**
- **Evidencia:** `skeleton_loader.dart` (theme-aware), `shimmer_loader.dart` (custom + `ShimmerServicioCard/List/Grid`), `shimmer_loading.dart` (`ServiceShimmerCard/Grid`, hardcode light), e inline `Shimmer.fromColors` con hex en [cliente_landing_screen.dart:189-209](../lib/features/cliente/presentation/pages/cliente_landing_screen.dart#L189-L209).
- **Impacto:** cuatro estéticas de carga distintas en el mismo flujo; dos rompen dark; solo una respeta reduced-motion.
- **Recomendación:** consolidar en un solo módulo (base: `SkeletonBox` de skeleton_loader + `DelayedLoader` de shimmer_loader, que son las dos piezas buenas).

**C6. Vocabulario de color/label de estados cuadruplicado e inconsistente**
- **Evidencia:** sección C.4. Mismo estado (`completado`) es azul oscuro en `AppTheme`, verde en `ProColors`, `primary` en `ServicioCardShared`.
- **Impacto:** el usuario no puede aprender el código de color; cliente y proveedor verán colores distintos para el mismo hecho.
- **Recomendación:** un solo `Status` enum + extensión (color, label, icono) consumido por el badge unificado; borrar los switches locales.

### 🟠 Importante (deuda que degrada consistencia y accesibilidad)

**I1. ~500 `fontSize` inline; 260 bajo 14px (100×13, 87×12, 57×11, 13×10, 3×≤9)**
El `textTheme` central define piso 12 (`labelSmall`); las pantallas inventan 8.5–11px (p.ej. [solicitud_detail_screen.dart:1025](../lib/features/solicitudes/presentation/pages/solicitud_detail_screen.dart#L1025), hero pill 11px en [cliente_landing_screen.dart:260](../lib/features/cliente/presentation/pages/cliente_landing_screen.dart#L260)). Riesgo de legibilidad + escala rota con text-scaling del SO.

**I2. 296 hex + 343 `Colors.*` fuera de los archivos de tokens**
Top ofensores: pro_ui (39), proveedor_profile/pago/contratacion_detail (17 c/u), conversaciones (16), solicitud_detail (33 `Colors.*`+12 hex). Incluye grises Tailwind sueltos (#1E293B, #334155, #0F172A) que duplican `AppColors` con otros valores.

**I3. Dark mode "a mano" con ternarios `isDark ?` y hex crudos**
`solicitud_detail_screen.dart` (7 bloques) y `crear_solicitud_screen.dart` (4) reimplementan el ColorScheme por widget ([crear_solicitud_screen.dart:902-915](../lib/features/cliente/presentation/pages/crear_solicitud_screen.dart#L902-L915)). Es el patrón que garantiza drift: cada pantalla elige sus propios oscuros.

**I4. Tres sistemas de breakpoints**
`Breakpoints` (600/1024) vs cortes ad-hoc: `<760`×14, `>1100`×9, `<600`×9, `>900`, `>960`, `<780`, `>800` (cliente_shell), `<650`, `<380`… El mismo layout cambia de columna en anchos distintos según la pantalla.

**I5. Inputs re-implementados por pantalla**
`crear_solicitud_screen` define su propia `InputDecoration` con borde `#D8E0EA` (≠ token `#CBD5E1`) ignorando el `inputDecorationTheme` central; `login_screen` usa borde `#EEF2F7`. Tres vocabularios de input en el flujo principal.

**I6. Botonera sin vocabulario único**
114 `ElevatedButton` vs 35 `FilledButton` (el tema declara FilledButton como estándar M3), más botones ad-hoc: empty_state radius 20 + elevation 8 + sombra de color + w800; success_dialog altura 50; landing radius 18. `CtaButton` (el componente correcto para transaccional) solo se usa 3 veces.

**I7. Shell legacy `HomeScreen` vivo en `/home`**
Navegación duplicada con estilos propios ([app_shell.dart](../lib/shared/layout/app_shell.dart), [router.dart:317](../lib/app/router.dart#L317)). Ruta alcanzable → dos experiencias de navegación distintas según cómo entres. Candidato a eliminación (verificar deep-links antes).

**I8. Accesibilidad semántica mínima**
10 usos de `Semantics` en toda la app (4 de ellos en el kit y widgets compartidos — buena señal), 45 tooltips. Imágenes de `ServicioCardShared` correctamente excluidas ✅, pero listas, tablas y formularios grandes sin landmarks ni labels. `CliCard` anuncia "Tarjeta seleccionable" genérico incluso cuando no es interactiva.

**I9. `DataTable` en pantallas cliente sin variante móvil verificada**
[mis_contrataciones_screen.dart:197](../lib/features/contrataciones/presentation/pages/mis_contrataciones_screen.dart#L197) y [solicitud_detail_screen.dart:267](../lib/features/solicitudes/presentation/pages/solicitud_detail_screen.dart#L267). DataTable no colapsa bien <600px; hay scroll horizontal como mitigación **[NO VERIFICADO en runtime]**.

### 🟢 Mejora recomendada

**M1. Curva `elasticOut` en SuccessDialog** ([success_dialog.dart:58](../lib/shared/widgets/success_dialog.dart#L58)) — bounce prohibido por las reglas del sistema; usar `Motion.curve`/easeOutCubic. `ConfettiOverlay` sin fallback reduced-motion.

**M2. Glow y gradientes decorativos residuales** — header Pro con "glow de acento" (comentario en [pro_ui.dart:113](../lib/features/proveedor/presentation/widgets/pro_ui.dart#L113); DESIGN.md §2.b: "sin glows"); sidebar cliente con gradiente ([cliente_shell.dart:112-116](../lib/features/cliente/presentation/pages/cliente_shell.dart#L112-L116)); glow blur-40 en empty states. El hero gradient azul del landing es defendible como superficie de marca, pero debería ser decisión documentada, no default.

**M3. Colores fuera de paleta en HelpModal** (indigo #6366F1, naranjo #EA580C) — mapear a `info`/`warning` del sistema. El verde WhatsApp #25D366 es marca externa, se conserva.

**M4. Pesos w800/w900** dispersos (profile headline, landing hero, empty states) — el sistema define máx w700. Decidir si w800 entra a la escala o se normaliza.

**M5. Radii sin token** — 15 valores en uso (4→30 + 999). `Radii` define 4+pill. Migrar los literales dominantes (12/14/16) y decidir si 16 reemplaza a 14 como `lg` (el uso real ya votó: 66×16 vs 24×14).

**M6. `AppTheme.info` y `tertiary` violeta** ([theme.dart:23-29](../lib/app/theme.dart#L23-L29)) — introducen un segundo azul y un morado no documentados; conflicto con la regla "fuente única de color". Documentar o eliminar.

**M7. Legacy menor:** 11 `withOpacity` (deprecado, migrar a `withValues`), alias `AppEmptyState`, parámetro dual `message`/`description` en EmptyState, rama `isDark` muerta en CtaButton.

**M8. Búsquedas recientes fake** en landing (`['Pintor','Electricista','Plomero']` seed en [cliente_landing_screen.dart:34](../lib/features/cliente/presentation/pages/cliente_landing_screen.dart#L34), no persistidas) — pariente del hallazgo de "datos inventados" de la auditoría de producción; mostrar solo búsquedas reales del usuario.

---

## E. Hallazgos por pantalla / módulo

| Pantalla | Archivo | Hallazgos principales |
|---|---|---|
| **Landing cliente** | cliente_landing_screen.dart (42 KB) | Hero gradient + eyebrow-pill 11px w700; breakpoints propios (1100/700/600); shimmer inline hardcodeado (C5); radius 18/22/24/26/32 ad-hoc; w900 |
| **Crear solicitud** (formulario) | crear_solicitud_screen.dart (48 KB) | 10 `TextFormField` con validators ✅; InputDecoration propia con hex fuera de token (I5); dark a mano con hex crudos (I3); monolito de 48 KB |
| **Mis solicitudes** | mis_solicitudes_screen.dart | Construida sobre `CliColors` fijos → rota en dark (C1); fontSize 12/13 inline |
| **Detalle solicitud** | solicitud_detail_screen.dart | El peor caso de I2+I3 (33 `Colors.*`, 12 hex, 7 bloques `isDark`); switch de status local; error rosado #DC9B9B de bajo contraste en light ([:642](../lib/features/solicitudes/presentation/pages/solicitud_detail_screen.dart#L642)); DataTable (I9); fontSize 10/11 |
| **Servicios (lista/detalle)** | servicios_list_screen, servicio_detail | Grid con `Breakpoints.gridColumns` ✅ (de lo mejor); detalle con 20 TextStyle inline y 7 hex |
| **Perfil** | profile_screen.dart | Fuerza tema claro pisando textTheme (C1); breakpoints propios 1100/760; 30 TextStyle inline; w900; botones radius 18 |
| **Auth (login/registro)** | login_screen, register_screen | Bordes hex propios (#EEF2F7); 22 TextStyle inline en registro; botones sociales Apple/Google correctos como marcas externas |
| **Pagos** | pago_screen.dart | 33 `Colors.*` + 17 hex — pantalla transaccional (la que más confianza debe transmitir) es la menos sistematizada |
| **Chat** | conversaciones_screen, chat_panel | 16 + 9 hex; no auditado en profundidad **[NO VERIFICADO]** |
| **Contrataciones** | mis_contrataciones, contratacion_detail | DataTable en móvil (I9); 16-17 hex c/u |
| **Empty states** (transversal) | empty_state.dart | API buena, visual fuera de sistema, dark roto (C1, I6) |
| **Loaders** (transversal) | 4 archivos | C5 |
| **Modales/diálogos** | success_dialog, help_modal, AlertDialogs dispersos | Bounce (M1), paleta paralela (M3), confirmaciones con `AlertDialog` M3 estándar ✅ |
| **Navegación** | shells | Tres sidebars distintos vs regla "mismo sidebar navy"; shell legacy en `/home` (I7); NavigationBar móvil M3 correcta ✅ |
| **Tablas** | admin_* + 2 cliente | Uso razonable en admin (registro denso permitido); en cliente reconsiderar como cards/listas en móvil |

---

## F. Reglas del sistema que SÍ funcionan (conservar)

1. **`tokens.dart` completo y bien comentado** — Spacing base-4, Radii, Elevation e0-e3, Motion 150-300ms. Es la base correcta; el problema es adopción, no diseño.
2. **Inter Variable local, una sola familia** — cumple la "Inter-Only Rule"; textTheme con escala razonable.
3. **`AppTheme` M3 con ColorSchemes explícitos** light y dark (el dark scheme en sí está bien construido; lo rompen los overrides).
4. **NavigationBar M3 móvil con badge de no-leídos** en cliente_shell — patrón estándar, accesible.
5. **`RatingBadge`** — el ejemplo canónico de componente: tokens + Semantics + icono-nunca-solo-color.
6. **`CtaButton`** — separación semántica azul-marca / verde-transaccional respetada.
7. **`DelayedLoader`** (anti-flicker) y `ShimmerContainer` con reduced-motion — únicos loaders con consideración de movimiento.
8. **`Breakpoints` + `gridColumns`** — API correcta; servicios_list la usa bien.
9. **Formularios con validators** consistentes en crear_solicitud (10/10 campos).
10. **Confirmaciones destructivas** con AlertDialog + acción en rojo (logout, cancelaciones).
11. **`ExcludeSemantics` en imágenes decorativas** de ServicioCardShared.
12. **La dirección de tres tiers (Cliente claro / Pro oscuro / Admin denso)** documentada en DESIGN.md §2.b es una decisión válida y distintiva — el problema es solo su ejecución parcial.

---

## G. Deuda visual/técnica pendiente (backlog consolidado)

| # | Deuda | Sev. | Esfuerzo | Hallazgo |
|---|---|---|---|---|
| 1 | Decidir y ejecutar estrategia dark mode | 🔴 | S (opción a) / XL (opción b) | C1 |
| 2 | Sincronizar DESIGN.md ↔ AppColors | 🔴 | S | C2 |
| 3 | Unificar cardTheme (borrar `_cardTheme()` o reconciliar) | 🔴 | S | C3 |
| 4 | StatusBadge tintado según spec + enum Status único | 🔴 | M | C4, C6 |
| 5 | Consolidar 4 loaders en 1 módulo | 🔴 | M | C5 |
| 6 | Migrar fontSize inline a textTheme (por pantalla) | 🟠 | L | I1 |
| 7 | Barrido de hex/Colors.* → tokens (por pantalla) | 🟠 | L | I2, I3 |
| 8 | Reemplazar cortes ad-hoc por `Breakpoints` | 🟠 | M | I4 |
| 9 | Borrar InputDecorations locales (usar tema) | 🟠 | S | I5 |
| 10 | ElevatedButton→FilledButton + normalizar variantes | 🟠 | M | I6 |
| 11 | Eliminar HomeScreen legacy + ruta /home | 🟠 | S | I7 |
| 12 | Pase de Semantics en listas/forms principales | 🟠 | M | I8 |
| 13 | DataTable→cards responsivas en pantallas cliente | 🟠 | M | I9 |
| 14 | Motion: quitar elastic, reduced-motion en confetti | 🟢 | S | M1 |
| 15 | Quitar glows/gradientes no documentados | 🟢 | S | M2 |
| 16 | HelpModal a paleta semántica | 🟢 | S | M3 |
| 17 | Decidir w800; migrar Radii literales | 🟢 | M | M4, M5 |
| 18 | Documentar o eliminar `info`/`tertiary` | 🟢 | S | M6 |
| 19 | Limpieza legacy (withOpacity, aliases, ramas muertas) | 🟢 | S | M7 |
| 20 | Búsquedas recientes reales | 🟢 | S | M8 |

---

## H. Recomendaciones para el frente Proveedor

Ver detalle y secuencia en [provider-ui-roadmap.md](provider-ui-roadmap.md). Lo esencial:

1. **No construir sobre el suelo actual.** Las fases 1–2 del plan (sección I) son prerequisito: si el frente Proveedor se abre con 4 loaders, 3 badges y dark roto, cada pantalla nueva duplica la deuda.
2. **`pro_ui.dart` ya existe y es la semilla correcta** (ProColors con jerarquía bg/surface/surfaceHi/elevated, bordes sutiles estilo workspace) — pero necesita: (a) mover `ProColors` a la arquitectura de tokens, (b) eliminar el glow del header (violación directa de DESIGN.md §2.b), (c) alinear `ProColors.status()` al enum Status unificado.
3. **El workspace oscuro Pro es identidad, no dark mode** — mantenerlo independiente de `ThemeMode`. Eso además simplifica la decisión C1: el flujo Pro no depende de ella.
4. **Reusar la infraestructura buena:** Breakpoints, DelayedLoader, RatingBadge, CtaButton, el enum Status nuevo. Prohibido crear "ProStatusBadge" paralelo.
5. **Definir el kit Pro ANTES de las pantallas** (ProButton/ProInput/ProTable/ProEmptyState) con paridad 1:1 de API con el kit Cli — misma prop-shape, distinta piel.

---

## I. Plan sugerido de implementación por fases

**Fase 0 — Decisiones (½ día, requiere al dueño de producto):**
D1: ¿Dark mode se pospone (ThemeMode.light) o se arregla? · D2: ¿Fuente de verdad de paleta: código o DESIGN.md? · D3: ¿Radius de card: 14 o 16? · D4: ¿Se conserva la barrita de CliSectionHeader como firma visual?

**Fase 1 — Fundaciones (deuda 1-5, ~1 semana):**
Cerrar los 6 críticos. Todo es cirugía localizada en `theme.dart`, `colors.dart`, DESIGN.md y 5 widgets compartidos. Sin tocar pantallas.

**Fase 2 — Consolidación de componentes (deuda 9-11, 14-16):**
Un solo vocabulario de botón/input/badge/loader/modal. Borrar legacy. Aquí nace el "kit congelado" que el frente Proveedor consumirá.

**Fase 3 — Barrido por pantallas (deuda 6-8, 12-13):**
Pantalla por pantalla (orden sugerido: pago → solicitud_detail → landing → perfil → crear_solicitud), migrar hex/fontSize/breakpoints a tokens. Ideal en paralelo con el desarrollo Pro ya que no comparten archivos.

**Fase 4 — Frente Proveedor** sobre el kit congelado (ver roadmap).

**Fase 5 — Polish transversal:** motion, Semantics, micro-textos, auditoría de contraste final con dark (si D1=b).

> Regla de control de drift durante todas las fases: [design-system-rules.md](design-system-rules.md) es de cumplimiento obligatorio en cada PR que toque UI.
