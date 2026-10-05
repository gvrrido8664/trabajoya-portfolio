# Handoff para Gemini — TrabajoYa (Flutter)

> App marketplace chilena. **Léelo entero antes de tocar código.** Autocontenido: no necesitas ver la conversación previa.
> Regla de trabajo: diffs mínimos, reusar lo que existe, `flutter analyze lib` verde después de cada cambio, **no tocar `admin_pagos_screen.dart`** (bloqueado por seguridad).

---

## 0. Lee primero (fuente de verdad)
1. `docs/design-system-rules.md` — reglas de UI obligatorias en cada PR.
2. `docs/provider-ui-roadmap.md` — plan y estado del frente Proveedor (§7 a11y, §8 Cobros: leer sí o sí).
3. `docs/ui-audit-master.md` — auditoría UI original.
4. Código base del sistema: `lib/utils/colors.dart` (AppColors), `lib/app/theme.dart` (AppTheme + status vocabulary), `lib/shared/theme/tokens.dart`, `lib/shared/theme/pro_palette.dart` (ProColors + RolePalette), `lib/features/proveedor/presentation/widgets/pro_ui.dart` (kit Pro).

---

## 1. Estado actual (hecho, NO rehacer)
- **Cliente:** design system Fase 1 (dark mode real, cardTheme unificado, tokens) + Fase 2 (vocabulario único de estado `AppTheme.statusColor/statusLabel/statusIcon` + `StatusBadge.forStatus`) — cerrado.
- **Proveedor P0-P3:** kit Pro (`pro_ui.dart`) + pantallas (dashboard, oportunidades, propuestas, servicios, perfil, contratacion_detail) migradas al tema oscuro con `RolePalette`.
- **Proveedor P4 a11y:** auditoría de contraste WCAG AA hecha. `ProColors.textMuted` #5E6E7D→**#828F9C** (fallaba AA); nuevo token **`ProColors.onAccent` #06283B** (texto oscuro sobre accent); 7 botones accent con blanco corregidos; grises light crudos en `proveedor_profile` → tokens. Detalle en roadmap §7.
- **Cobros (P4):** RECONSTRUIDO correcto. **MP Connect fue ELIMINADO del backend** (asunción previa errónea). Modelo real: escrow → payout automático vía **Fintoc** a la **cuenta bancaria** del proveedor al completar el trabajo. `proveedor_cobros_screen.dart` = config de cuenta bancaria (endpoints reales `GET/PUT /proveedores/me/banco`) + resumen. Detalle en roadmap §8.
- **Drift front↔back corregido:** borrado dead code MP Connect (`pagos_remote_datasource.dart`, `pagos_provider.dart`); estados muertos del dashboard (`LIBERADO`/`EN_PROGRESO`/`ACEPTADA`) → enum real (`COMPLETADO`/`ACEPTADO`).

---

## 2. 🔨 EN PROGRESO — Migrar `FilledButton` crudos → `ProButton` (SOLO frente Proveedor)

**Objetivo:** eliminar botones crudos con `backgroundColor`/`foregroundColor` manuales repetidos; centralizar tamaño/onAccent/estados en `ProButton`. **Condición del dueño:** si a `ProButton` le falta algo, **extender `ProButton` en `pro_ui.dart`, nunca wrappers locales.**

**Ya hecho:**
- `ProButton` extendido en `pro_ui.dart`: ahora tiene `icon` (reemplaza `.icon`), `compact` (ancho al contenido, alt 44 — para diálogos/inline), y el spinner de carga usa el `fg` correcto (no blanco).
- `mis_servicios_screen.dart`: migrados los 3 botones **accent** (verificar / crear servicio / editar).

**Falta migrar (mismo criterio):**
- `lib/features/proveedor/presentation/pages/oportunidades_screen.dart` — FilledButton/OutlinedButton (líneas ~134, 157, 443).
- `lib/features/servicios/presentation/pages/crear_editar_servicio_screen.dart` — OutlinedButton ~512, ElevatedButton ~1087.
- `lib/features/proveedor/presentation/pages/proveedor_profile_screen.dart` — el grande: varios FilledButton/OutlinedButton, **7 usan `.icon`** (~127, 150, 173, 599, 887, 1214, 1234, 1377, 1448, 1748). Usa `ProButton(icon: ...)`.

**Reglas de la migración (importante):**
- **Accent/primario** (`backgroundColor: ProColors.accent`) → `ProButton(label, onPressed)`; si tenía icono → `icon:`; si está en `AlertDialog.actions` o inline → `compact: true`; dentro de `Expanded` el ancho completo por defecto va bien.
- **Outline** (`OutlinedButton`) → `ProButton(isOutline: true, ...)`.
- **NO migrar (dejar crudos):**
  - Botones **destructivos** `backgroundColor: ProColors.danger` → son la Tarea 2.
  - Botones con **color semántico bespoke** (ej. toggle Pausar/Activar amber↔success en `mis_servicios` ~499) — no son primarios; `ProButton` no debe volverse un theming genérico. Déjalos y anótalos.
  - `TextButton` de "Cancelar" en diálogos (dismissive) — quedan.
  - `FloatingActionButton` — no es ProButton.
- **NO tocar** `contratacion_detail_screen.dart` (es rol-dinámico con `RolePalette`; forzar `ProButton`, que siempre usa `ProColors.accent`, rompería la vista clara del cliente) ni pantallas cliente (`servicio_detail`, `servicios_list`).

---

## 3. Pendiente (orden aprobado, después de la migración)
2. **Botones destructivos AA:** hoy `foregroundColor: Colors.white` sobre `ProColors.danger` #F87171 = ~2.3:1 (falla). Están en `proveedor_profile` (~178) y `mis_servicios` (~283, 290). **Mejor solución:** añadir variante `danger` a `ProButton` (en `pro_ui.dart`) con foreground oscuro legible (o un `ProColors.onDanger`), y migrar esos botones. También el toggle amber/success de mis_servicios necesita foreground oscuro.
3. **Colapso móvil de contrataciones (<600):** `ContratacionesProveedorScreen` (en `mis_contrataciones_screen.dart`) usa `DataTable` con scroll horizontal; en <600 debería colapsar a cards/lista (regla R4.9). Idealmente extraer un `ProListRow`/`ProTable` en el kit con colapso.

**Deferido (frente Cliente, Fase 3):** barrido de dark en pantallas cliente que evaden el sistema: `auth/profile_screen.dart` (fuerza tema claro con un wrapper Theme — quitar SOLO tras migrar sus colores internos), `solicitudes/solicitud_detail_screen.dart` y `cliente/crear_solicitud_screen.dart` (ternarios `isDark` con hex crudos), `shared/widgets/help_modal.dart` (paleta paralela). Migrar `AppColors.textDark/isDark-hex` → `Theme.of(context).colorScheme`/`textTheme`.

---

## 4. Verdades del backend (verificadas en `../trabajoya-api` — NO asumir)
- **MP Connect eliminado.** El modelo `Usuario` lo dice: `# Cuenta conectada del agregador (MP Connect) eliminada`. Endpoints `/pagos/connect/mp/*` NO existen (404). Su UI ya fue borrada.
- **`EstadoContratacion`** (real) = `PENDIENTE, ACEPTADO, RECHAZADO, COMPLETADO, CANCELADO, DISPUTA`. **No** hay `EN_PROGRESO` ni `LIBERADO`. Contratación es masculino (`ACEPTADO`), no `ACEPTADA`.
- **`StatusPropuesta`** usa femenino `ACEPTADA/RECHAZADA` (por eso el vocabulario canónico tiene ambas formas — es correcto, no lo "arregles").
- **Cobros/payout:** cliente paga (`Pago.status=APROBADO`) → al completar, backend dispersa vía Fintoc a la cuenta bancaria del proveedor (`Pago.payout_status`). Endpoints reales: `GET/PUT /proveedores/me/banco` (`routes_banco.py`). Bancos válidos (Fintoc): los 8 en `BancoService.bancos`. `account_type` ∈ corriente|vista|ahorro.
- **Verifica el backend antes de asumir el modelo de negocio.** (Esa suposición ya costó una pantalla mal construida.)

---

## 5. `ProButton` — API actual (kit Pro)
```dart
ProButton({
  required String label,
  VoidCallback? onPressed,
  bool loading = false,     // spinner (usa el fg correcto)
  bool isOutline = false,   // borde + texto accent
  bool isCta = false,       // fondo success (verde) — para acciones de cobro/confirmación positiva
  IconData? icon,           // icono a la izquierda del label
  double? width,            // ancho fijo; null = full width (salvo compact)
  bool compact = false,     // ancho al contenido, alt 44 (diálogos/inline)
})
```
Filled: fondo `accent` (o `success` si `isCta`), fg `ProColors.onAccent` #06283B (7.5:1). Outline: fg/borde accent. **No** hay variante `danger` todavía (agrégala en la Tarea 2).

Otros del kit: `ProScaffold`, `ProHeader`, `ProSectionHeader`, `ProCard`, `ProInput.decoration(...)`, `ProStatusBadge(status, {label})`, `ProMetricTile(icon, value, label, accent)`, `ProSkeleton(height)`, `ProEmptyState(icon, title, message, actionLabel, onAction)`, `ProQuickAction(icon, label, accent, onTap)`. `RolePalette.of(rol)` para pantallas rol-dinámicas (cliente claro / proveedor oscuro).

---

## 6. Reglas/gotchas clave
- **Cero colores/fontSize crudos en pantallas.** Solo tokens (`ProColors`/`AppColors`/`colorScheme`) y `theme.textTheme`. En Pro, `ProColors.textMuted` es el mínimo legible (no bajar de él).
- **Brillo vía tema/kit, no ternarios `isDark`.** En Cliente, `CliColors.textPrimary/textSecondary/surface/border` son **métodos `(context)`** (rompen `const` — quita el `const` del widget contenedor).
- **Estados siempre por `StatusBadge.forStatus` / `AppTheme.status*`** — nunca switches locales de color.
- **Breakpoints** solo vía `Breakpoints` (mobile<600 / tablet<1024).
- **Dead code conocido:** `test/widget_test.dart` falla por un cambio ajeno preexistente (`TrabajoYaApp` requiere `authProvider`) — no es tuyo, ignóralo. 34 tests pasan.

## 7. Verificar SIEMPRE
```bash
flutter analyze lib      # debe decir "No issues found!"
flutter test             # 34 pasan; solo widget_test.dart falla (ajeno)
```

---

## 8. PROMPT para arrancar a Gemini
> Vas a continuar el frente Proveedor de una app Flutter (TrabajoYa). **Primero lee `docs/HANDOFF-gemini.md` completo**, y de ahí los docs que indica (§0). Trabaja SOLO en el frente Proveedor, con diffs mínimos, corriendo `flutter analyze lib` después de cada cambio. **No toques `admin_pagos_screen.dart`.**
>
> Tarea inmediata (§2 del handoff): **termina de migrar los `FilledButton`/`OutlinedButton` crudos a `ProButton`** en `oportunidades_screen.dart`, `crear_editar_servicio_screen.dart` y `proveedor_profile_screen.dart` (este último usa varios `.icon` → `ProButton(icon:)`). Respeta el criterio: migra accent→`ProButton`, outline→`isOutline`, diálogos/inline→`compact`; **deja** los destructivos (`ProColors.danger`), los toggles semánticos amber/success, los `TextButton` de cancelar y `contratacion_detail` (rol-dinámico). Si a `ProButton` le falta algo, extiéndelo en `pro_ui.dart`, no con wrappers.
>
> Al terminar la migración, sigue con la Tarea 2 (botones destructivos AA: añade variante `danger` a `ProButton`) y la Tarea 3 (colapso móvil <600 de la tabla de contrataciones). Verifica con `flutter analyze lib` + `flutter test` y actualiza `docs/provider-ui-roadmap.md`.
