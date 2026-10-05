# Reglas del Design System — TrabajoYa

> **Propósito:** reglas de cumplimiento obligatorio para toda pantalla o componente nuevo (Cliente, Proveedor, Admin). Nacen de la auditoría [ui-audit-master.md](ui-audit-master.md) (2026-07-08): cada regla existe porque su violación ya ocurrió y ya costó. Aplicar en cada PR que toque UI.
> Complementa `DESIGN.md` (dirección visual) — este documento es el *enforcement*: qué está prohibido, qué es obligatorio y dónde vive cada cosa.

---

## 1. Color

**R1.1 — Cero colores literales en pantallas.** Prohibido `Color(0xFF...)` y `Colors.*` (salvo `Colors.transparent`) fuera de `lib/utils/colors.dart`, `lib/app/theme.dart`, `lib/shared/theme/tokens.dart` y los archivos de kit (`cli_ui.dart`, `pro_ui.dart`). Si necesitas un color que no existe, se agrega al token con nombre semántico — nunca inline.
*Por qué:* hoy hay 296 hex y 343 `Colors.*` regados; es la causa nº1 del drift y del dark roto.

**R1.2 — Un solo azul.** El azul de marca es `AppColors.primary` (#1D4ED8). Prohibido introducir azules paralelos. `AppTheme.info` solo con aprobación explícita y documentación en DESIGN.md; mientras tanto, tratarlo como deprecado.

**R1.3 — Semántica fija:** azul = marca/navegación/selección · verde = transaccional y éxito (`CtaButton`) · ámbar = rating/advertencia · rojo = error/destructivo. Nunca cruzarlos (nunca verde para destructivo, nunca rojo decorativo).

**R1.4 — Estado nunca solo por color.** Todo indicador de estado lleva etiqueta textual o icono además del color (daltonismo). `RatingBadge` es el patrón de referencia.

**R1.5 — Brillo vía tema, no ternarios.** Prohibido `Theme.of(context).brightness == Brightness.dark ? hexA : hexB` en pantallas. La variación light/dark se resuelve en `ColorScheme`/kit, una sola vez.

## 2. Tipografía

**R2.1 — Inter única familia**, servida desde `assets/fonts/InterVariable.ttf`. No introducir segundas fuentes.

**R2.2 — Cero `fontSize:` inline en pantallas.** Usar `Theme.of(context).textTheme.*` (con `copyWith` solo para `color`/`fontWeight` dentro de escala). Si un tamaño no existe en el textTheme, se discute agregarlo al tema — no se inventa localmente.

**R2.3 — Piso 12px** (= `labelSmall`). Prohibido 8.5–11px: si el contenido "no cabe", el problema es de jerarquía o de copy, no de tamaño.

**R2.4 — Techo de peso w700.** w800/w900 no pertenecen a la escala. Énfasis extra = tamaño o color, no más peso.

**R2.5 — Un patrón de encabezado de sección** por tier: en Cliente es `CliSectionHeader`. No headers artesanales por pantalla.

## 3. Spacing y radio

**R3.1 — Solo `Spacing.*`** (`tokens.dart`) en paddings/margins/gaps. Prohibidos literales numéricos en `EdgeInsets`/`SizedBox` salvo 0 y valores de `Spacing`.

**R3.2 — Solo `Radii.*`**: sm 8 (chips) · md 12 (botones, inputs) · lg (cards) · pill 999. Los 15 valores actuales (4→30) se congelan: nada nuevo fuera de la escala. *(Pendiente decisión D3 de la auditoría: card = 14 o 16; hasta entonces, usar `Radii.lg`.)*

**R3.3 — Elevación solo por vocabulario:** e0 reposo · e1 cards · e2 navegación/menús · e3 diálogos (`Elevation.*`). Sin sombras decorativas, sin glows, sin sombras de color (excepto respuesta a hover ya definida en kit).

## 4. Componentes (usar, no re-crear)

**R4.1 — Antes de escribir un widget visual, buscar en este orden:** `lib/shared/widgets/` → kit del tier (`cli_ui.dart` / `pro_ui.dart`) → componente M3 tematizado. Crear uno nuevo exige: no existe, se agrega al kit (nunca dentro de la pantalla), y API paralela a su equivalente del otro tier.

**R4.2 — Botones:** `FilledButton` = acción primaria de marca · `CtaButton` = transaccional (Pagar/Contratar, máx 1-2 por vista) · `OutlinedButton` = secundaria · `TextButton` = terciaria. `ElevatedButton` queda deprecado para código nuevo. Altura 52, radius `Radii.md`, siempre con estado loading si dispara red.

**R4.3 — Inputs:** el `inputDecorationTheme` del tema es la única fuente. Prohibido construir `InputDecoration` con bordes/fills propios. Todo campo: label, validator, error visible con icono/texto.

**R4.4 — Estados (status):** un solo enum/extension de Status (color + label + icono) para toda la app; badges siempre en formato píldora tintada (fondo color al 10-15% + texto del color oscuro + punto), nunca fondo sólido con texto blanco. Prohibidos los `switch` locales de status en pantallas.

**R4.5 — Loading:** un solo módulo de skeleton (theme-aware) + `DelayedLoader` anti-flicker. Skeletons que anticipan la forma del contenido, no spinners centrados (spinner solo para acciones de botón).

**R4.6 — Empty states:** `EmptyStateWidget` siempre (nunca `Text('No hay datos')`); con título + descripción que enseña + acción cuando exista siguiente paso.

**R4.7 — Modales:** agotar alternativas inline antes de un modal. Confirmación destructiva = `AlertDialog` M3 con acción destructiva en rojo. Bottom sheets para acciones móviles contextuales. Sin animaciones bounce/elastic.

**R4.8 — Cards:** `Card` del tema o `CliCard`/`ProCard`. Nunca cards anidadas. Nunca `border-left`/stripe de color como acento.

**R4.9 — Tablas:** `DataTable` solo en Admin/desktop. En superficies Cliente/Proveedor móviles, listas o cards. Si hay tabla en ≥600px debe existir su colapso <600px.

## 5. Layout y responsive

**R5.1 — Solo `Breakpoints`** (`lib/shared/layout/breakpoints.dart`): mobile <600 · tablet <1024 · desktop. Prohibido comparar `MediaQuery...width` contra números ad-hoc (760, 800, 1100…). Si un layout necesita otro corte, se agrega constante nombrada a `Breakpoints` con justificación.

**R5.2 — Grillas** vía `Breakpoints.gridColumns` (2/3/4). Contenido de lectura max-width ~720-760px centrado; dashboards hasta 1200.

**R5.3 — Touch targets ≥44×44** en todo interactivo (`minimumSize: Size(44,44)` en icon/text buttons pequeños).

**R5.4 — Todo texto en contenedores estrechos** lleva `maxLines` + `overflow` definidos (labels en español son largos).

## 6. Motion

**R6.1 —** Duraciones y curva de `Motion` (`tokens.dart`): 150-300ms, easeInOut/easeOut. Prohibido `elasticOut`/bounce.
**R6.2 —** Toda animación decorativa u ornamental (confetti, celebraciones) verifica `MediaQuery.disableAnimations` y ofrece alternativa estática.
**R6.3 —** Motion comunica estado (carga, cambio, feedback); nada de coreografías de entrada de página.

## 7. Accesibilidad (piso WCAG AA)

**R7.1 — Contraste:** texto normal ≥4.5:1, grande ≥3:1 — verificar contra el fondo *real* (tintado incluido). Regla práctica: texto blanco solo sobre `primary`, `primaryDark`, `danger` y superficies oscuras Pro; nunca sobre `secondary` (ámbar) ni `success`.
**R7.2 — Semantics con contenido real:** componentes interactivos anuncian qué son y qué contienen (patrón `RatingBadge`/`ServicioCardShared`). Prohibidos labels genéricos ("Tarjeta seleccionable") y `button: true` en elementos no interactivos.
**R7.3 — Imágenes decorativas** con `ExcludeSemantics`; informativas con label.
**R7.4 — Formularios:** error asociado al campo, con texto (no solo borde rojo); foco visible; teclado correcto por tipo de dato.

## 8. Dark mode y tiers

**R8.1 —** Hasta cerrar la decisión D1 de la auditoría: **ninguna pantalla nueva implementa su propio dark** (ni ternarios ni hex oscuros). Se escribe contra `colorScheme`/kit y hereda lo que el sistema resuelva.
**R8.2 —** El workspace oscuro del Proveedor es **identidad fija**, independiente de `ThemeMode`. No mezclarlo con el dark mode del cliente.
**R8.3 —** Los tres tiers comparten: azul de marca como color activo, `Spacing`/`Radii`/`Elevation`/`Motion`, enum Status, y el mismo patrón de sidebar. Lo que cambia entre tiers es piel (superficie/densidad), nunca vocabulario.

## 9. Proceso (anti-drift)

**R9.1 — Checklist de PR de UI:** ¿cero hex/Colors.* nuevos? ¿cero fontSize inline? ¿cero breakpoints ad-hoc? ¿componentes del kit? ¿estados loading/empty/error definidos? ¿contraste verificado? ¿probado <600px y >1024px?
**R9.2 — Si DESIGN.md y el código divergen,** se corrige en el mismo PR o se abre issue — nunca se deja divergir en silencio.
**R9.3 — Componentes se modifican en su archivo fuente,** nunca se copian a la pantalla "para ajustarlo".
**R9.4 — Deprecados (no usar en código nuevo):** `ElevatedButton`, `shimmer_loading.dart`, `ShimmerServicioCard/List/Grid` de shimmer_loader, `HomeScreen`/`app_shell.dart`, `StatusBadge` sólido actual, `withOpacity`, `AppTheme.info`/`tertiary` sin documentar, ternarios `isDark`.
