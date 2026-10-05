# Plan: restyle completo de la app al lenguaje "orden de trabajo"

**Fecha:** 2026-08-05
**Alcance:** todas las pantallas (auth, cliente, proveedor, admin, landing).
**Regla dura:** es un *restyle*, no una reescritura. Se conserva TODA la
funcionalidad, el ruteo y el cableado a la API real. Solo se agregan funciones
nuevas cuando el diseño nuevo las exija (y se marcan como tales).

**Este plan reemplaza y absorbe** `docs/Importante/plan-restyle-landing-ideal.md`
(aprobado pero nunca implementado — la landing sigue con el diseño azul del
commit `40189f0`). Ver Fase 5.

---

## 1. Contexto

En `design-concepts/` hay 23 mockups HTML estáticos ya construidos y verificados
(`landing-ideal.html` + `auth/` 3 + `cliente/` 5 + `proveedor/` 6 + `admin/` 8).
**Esos mockups son la especificación.** Definen un lenguaje visual de "orden de
trabajo / plano técnico": fondo papel, tinta navy, acento óxido, bordes finos de
1px en vez de sombras, y marcas de registro en L en las esquinas de las tarjetas.

El problema que resuelve este plan no es solo estético. Hoy la app mantiene
**cuatro sistemas de color paralelos**:

| Sistema | Archivo | Alcance |
|---|---|---|
| `AppColors` | `lib/utils/colors.dart` | 40 importadores |
| `AppTheme` | `lib/app/theme.dart` | 23 importadores |
| `ProColors` | `lib/shared/theme/pro_palette.dart` | tema oscuro solo-proveedor |
| `ChatPalette` | `pro_ui.dart:625` | **código muerto, 0 consumidores** |

Más dos "kits" de UI a nivel de feature que en la práctica son compartidos:
`pro_ui.dart` (970 líneas, 11 importadores) y `cli_ui.dart` (309 líneas, 10
importadores). `docs/ui-audit-master.md` ya documentó la deriva que esto genera.

El objetivo de arquitectura de este plan: **colapsar los 4 sistemas en 1**. Eso
es lo que hace que ~30 pantallas hereden el diseño nuevo casi gratis, en vez de
reescribirse una por una.

---

## 2. Decisiones ya tomadas (no volver a preguntar)

1. **Se elimina el tema oscuro del proveedor.** Ambos roles usan el mismo fondo
   papel con sidebar oscura, igual que los mockups.
2. **`themeMode: ThemeMode.light` global.** El modo oscuro queda desactivado (no
   borrado) hasta que exista una variante oscura real del lenguaje nuevo.
3. **Se adoptan las 3 tipografías** (Big Shoulders Display / Archivo / IBM Plex
   Mono) como assets locales, reemplazando Inter. Se deroga la regla "Inter-Only"
   de `DESIGN.md`.
4. **El chat se restylea** al lenguaje nuevo.

---

## 3. Correcciones a los supuestos iniciales (verificadas)

Cuatro hallazgos de la investigación que cambian el plan. Están verificados
contra el código, no asumidos:

1. **`ChatPalette` ya es código muerto.** `grep -rn "ChatPalette" lib` solo
   encuentra su propia definición (`pro_ui.dart:625-661`). El chat real **no** es
   un clon de WhatsApp: usa gradientes azul/teal propios (`chat_panel.dart:649,
   935, 991`) y `conversaciones_screen.dart:423-450` tiene su **propio mapa
   hardcodeado de estado→color** que ignora `AppTheme.statusColor`. Borrar
   `ChatPalette` es gratis; el trabajo real del chat es otro.
2. **Las cifras de deriva de la auditoría están desactualizadas.** Hoy: **202**
   literales `0xFF…` en 27 archivos, pero 66 viven *dentro* de los archivos de
   tokens y 21 en `landing_screen.dart` (que se reescribe igual) → la deriva real
   es **≈115 en ~22 pantallas**. El eje peor no es el color: son los radios,
   **~330 llamadas `BorderRadius.circular(n)` con 20 valores distintos**.
   `fontSize:` inline: 400 sitios, 27 valores distintos.
3. **`AppTheme.tertiary`, `.accent`, `.info`, `.premium` tienen 0 usos.** Están
   muertos; el namespace queda libre para los tokens nuevos.
4. **La matemática HSL de `StatusBadge` sobrevive el cambio de paleta intacta.**
   El riesgo de contraste está en otro lado (ver §5).

---

## 4. Mapeo exacto de la paleta

### 4.1 `lib/utils/colors.dart` — se conservan TODOS los nombres, cambian los valores

Conservar los nombres es lo que permite que los 178 `AppColors.primary` / 81
`.success` / 65 `.danger` sigan compilando. **No se borra ningún miembro.**

| miembro | viejo | **nuevo** | token del mockup |
|---|---|---|---|
| `primary` | `#1D4ED8` | `#C1502E` | `--rust` |
| `primaryDark` | `#1E3A8A` | `#9E3D22` | `--rust-dark` |
| `primaryLight` | `#DBEAFE` | `#F3E3DC` | `--rust-tint` |
| `secondary` | `#F59E0B` | **`#8A6508`** | `--amber` oscurecido (ver quiebre 2) |
| `success` | `#10B981` | `#3F6B4F` | `--verified` |
| `successLight` | `#E6F4EA` | `#DEE9E1` | `--verified-tint` |
| `danger` | `#EF4444` | **`#A32015`** | **sin equivalente** (ver quiebre 3) |
| `dangerLight` | `#FEE2E2` | `#F6E3E0` | derivado |
| `warning` | `#F59E0B` | `#8A6508` | = `secondary` |
| `warningLight` | `#FEF3C7` | `#F5EBD6` | `--amber-tint` |
| `background` | `#F1F5F9` | `#F2F4F3` | `--paper` |
| `surface` | `#FFFFFF` | `#FFFFFF` | `--card` (sin cambio) |
| `textDark` | `#0F172A` | `#12233D` | `--ink` |
| `textLight` | `#627188` | `#3A4A63` | `--ink-soft` |
| `border` | `#CBD5E1` | `#D7DCD8` | `--line` |

**Miembros nuevos a agregar** (nombrados como el mockup, para que el código de
pantalla se lea como la spec): `ink`, `inkSoft`, `paper`, `card`, `line`,
`rust`/`rustDark`/`rustTint` (alias de primary/Dark/Light), `blueprint #2B4C7E`,
`blueprintTint #DDE6F1`, `verified #3F6B4F`, `verifiedTint #DEE9E1`,
`amber #8A6508`, `amberTint #F5EBD6`, `sidebarTop #12233D`,
`sidebarBottom #0B1626`, y **`borderStrong #8E978F`** (ver quiebre 5).

### 4.2 Los cinco quiebres del mapeo

**Quiebre 1 — `primary` hace dos trabajos y el mockup los separa.**
Hoy `AppColors.primary` significa a la vez "relleno del CTA" y "acento neutro
para cromo informativo". Los mockups reservan `--rust` para exactamente cinco
cosas (botones CTA, el cuadrado de la marca, el precio, el ítem activo del nav
móvil, y las píldoras de no-leídos) y usan `--blueprint` para todo lo
informativo (links, `.badge.open`, tintes decorativos de íconos en KPIs,
avatares de respaldo).

De los 178 usos de `AppColors.primary`, **~30 son tintes**
(`.withValues(alpha:)`) — esos son decorativos y se vuelven naranjos si se
voltea primary a óxido sin más. Hay que **re-apuntarlos a `blueprint`/
`blueprintTint` en el mismo commit del cambio**, o media app queda naranja.
Sitios concretos: `cli_ui.dart:120` (barra de `CliSectionHeader`), `:196`, `:249`,
`admin_shell.dart:186,196,206`, `chat_panel.dart:574,855,864`,
`conversaciones_screen.dart:494,603,632`.

> **Decisión:** `primary` = **`--rust` `#C1502E`**, no blueprint.
> Consecuencia: `ColorScheme.primary` maneja el fondo de
> `FilledButton`/`ElevatedButton`, el `foreground`+`side` de `OutlinedButton`,
> `Switch`, ícono/label seleccionado de `NavigationBar`, `TabBar` indicator y el
> `focusedBorder` del input. Todo eso queda óxido, lo que coincide con el
> mockup — **salvo el borde de foco del input**, que el mockup pinta `--ink`
> (`login.html:45`). Así que `_inputTheme()` debe fijar
> `focusedBorder: BorderSide(color: AppColors.ink, width: 2)` explícitamente.

**Quiebre 2 — `secondary` no tiene equivalente honesto.**
El `--amber #B8860B` del mockup se usa como *texto sobre `--amber-tint`*
(`.badge.wait`) a **2.75:1**. Eso reprueba AA para texto y también el 3:1 de
1.4.11 para gráficos. Además es `ColorScheme.secondary` con `onSecondary: white`
→ **3.25:1**, y hoy es el `backgroundColor` del FAB (`theme.dart:316`).
→ `secondary = #8A6508` (5.32:1 sobre blanco, 4.50:1 sobre amber-tint) y **mover
el FAB a `primary`**. Es una corrección de bug real que viaja con el restyle.

**Quiebre 3 — `danger` no tiene ningún equivalente.**
Los mockups nunca muestran un estado destructivo o de error. Pero la app tiene 65
usos de `AppColors.danger` (rechazado / cancelado / disputa / reembolsado /
eliminado) más botones destructivos que en `contratacion_detail_screen.dart`
quedan **al lado** de un primary óxido. Reusar óxido haría que "Cancelar
contratación" fuera indistinguible de "Aceptar".
→ Se introduce **un token fuera del mockup**: `#A32015` (7.57:1 en ambos
sentidos, 6.85:1 sobre papel). Verificar visualmente lado a lado en
`contratacion_detail_screen`.

**Quiebre 4 — sin equivalente para `tertiary`/`inversePrimary`/`outlineVariant`.**
`AppTheme.tertiary #8B5CF6` (violeta): 0 usos → borrar.
En M3, poner **blueprint en `ColorScheme.tertiary`** — es el slot para un segundo
acento de marca y regala `tertiaryContainer: blueprintTint`.

**Quiebre 5 — `--line` es demasiado claro para ser borde de control de formulario.**
`#D7DCD8` sobre blanco = **1.39:1**. WCAG 1.4.11 pide 3:1 para límites de input.
El `#CBD5E1` actual también reprueba, así que no es una regresión — pero ya que se
reescriben todos los inputs: `--line` se queda para bordes decorativos de
tarjeta/tabla (que es como lo usa el mockup) y se agrega **`borderStrong #8E978F`**
(3.01:1) para el `enabledBorder` de los campos. **Documentar como desviación
deliberada del mockup.**

### 4.3 `lib/app/theme.dart` — `lightColorScheme`

```
primary            #C1502E   onPrimary            #FFFFFF   (4.71:1 ✓)
primaryContainer   #F3E3DC   onPrimaryContainer   #9E3D22   (5.35:1 ✓)
secondary          #8A6508   onSecondary          #FFFFFF   (5.32:1 ✓)
secondaryContainer #F5EBD6   onSecondaryContainer #6F5206   (6.15:1 ✓)
tertiary           #2B4C7E   onTertiary           #FFFFFF   (8.61:1 ✓)  ← blueprint
tertiaryContainer  #DDE6F1   onTertiaryContainer  #2B4C7E   (6.84:1 ✓)
error              #A32015   onError              #FFFFFF   (7.57:1 ✓)
errorContainer     #F6E3E0   onErrorContainer     #7A1810
surface            #FFFFFF   onSurface            #12233D   (15.75:1 ✓)
surfaceContainerHighest #F2F4F3  onSurfaceVariant #3A4A63   (8.13:1 ✓)
outline            #D7DCD8   outlineVariant       #F2F4F3
inverseSurface     #12233D   onInverseSurface     #FFFFFF   inversePrimary #F3E3DC
```

`darkColorScheme` y `AppTheme.dark`: **no se tocan.** Se les agrega un comentario
`// Deshabilitado: no existe variante oscura del lenguaje "orden de trabajo".`
Siguen cableados a `MaterialApp.darkTheme` pero `themeMode: ThemeMode.light` los
vuelve inalcanzables.

Otros cambios en `_base()` / `light`:
- `cardTheme` → `elevation: 0`, `shadowColor: transparent`, `shape: TicketBorder(...)`
- radios de todos los botones 12 → `Radii.sm` (4)
- **conservar `minimumSize: Size(0, 52)`** — los 42px efectivos del mockup están
  por debajo del target táctil de 44px que ya se corrigió antes (A11Y-01)
- `chipTheme` 8 → 4; `snackBarTheme` 10 → 4
- `navigationBarTheme.indicatorColor` → `rustTint`, `elevation: 0`
- `tabBarTheme` → `labelColor: ink`, no-seleccionado `inkSoft`, indicador 2px óxido

> ⚠️ Respetar el comentario existente de `theme.dart:199-205`: `copyWith()`
> **reemplaza** los themes de botón en vez de fusionarlos. Todo cambio hecho en
> `_base()` no debe re-agregarse vía `.copyWith()` en `light`.

### 4.4 `lib/shared/theme/tokens.dart`

- `Spacing` — **sin cambios** (42 importadores, los valores están bien).
- `Radii` — re-valorado: `sm 8→4`, `md 12→8`, `lg 14→8`, `xl 20→12`,
  `pill 999` sin cambio (las variantes `rSm/rMd/rLg/rXl` siguen solas).
- `Elevation.e1` → `[]` (idéntico a `e0`): el lenguaje es plano con bordes finos.
  **Se conservan `e2`/`e3`** — los menús, diálogos y bottom-sheets de Flutter sí
  necesitan separarse del contenido y los mockups no cubren overlays.
- `Motion` — sin cambios.

---

## 5. Qué se rompe al cambiar los valores

### 5.1 `StatusBadge` — sobrevive, **no tocar la matemática**

`shared/widgets/status_badge.dart:50-57` calcula
`textColor = HSL(color).withLightness(L*0.5, tope 0.32)` y `bg = color @14%`.
Pasando la paleta nueva por la *misma* fórmula:

| estado | fuente | texto derivado | fondo derivado | **ratio** |
|---|---|---|---|---|
| `abierta` → blueprint | `#2B4C7E` | `#16263F` | `#E1E6ED` | **12.11** |
| `pendiente` → amber | `#B8860B` | `#5C4306` | `#F5EEDD` | **8.03** |
| `aceptado` → verified | `#3F6B4F` | `#203628` | `#E4EAE6` | **10.63** |
| `completado` → ink | `#12233D` | `#09111E` | `#DEE0E4` | **14.31** |
| `cerrada` → gris | `#8A9188` | `#454943` | `#EFF0EE` | **8.03** |

(La paleta actual da 6.36–12.80, o sea la nueva es **mejor** en todos los casos.)

> **La trampa es la inversa de lo esperable:** si alguien "implementa fielmente el
> mockup" y reemplaza el cálculo HSL por los pares de tinte literales del mockup,
> queda `amber #B8860B` sobre `amber-tint #F5EBD6` = **2.75:1**, un fallo AA duro.
> En `StatusBadge` solo se cambian tres cosas: `BorderRadius.circular(999)` → `3`,
> agregar `fontFamily: 'IBMPlexMono'` + mayúsculas + `letterSpacing`, y quitar el
> borde. **Las líneas 53–57 quedan textuales.**

### 5.2 `AppTheme.statusColor` — una colisión semántica

Mapeo nuevo: `abierta→blueprint`, `en_evaluacion/pendiente/pausado→secondary`,
`aceptado/en_progreso/liberado/activo→verified`, `completado→ink`,
`cerrada→#8A9188` (un gris de la familia papel; `Colors.grey` tiene tinte azul y
choca), `rechazado/cancelado/disputa/reembolsado/eliminado→danger`.

**Colisión:** `abierta→blueprint` mientras `ColorScheme.primary` es óxido.
Cualquier pantalla que dibuje "abierta" con `AppColors.primary` en vez de
`AppTheme.statusColor('abierta')` queda mal de una forma *nueva*. Hay tres:
`admin_usuarios_screen.dart:1050` y `:1192` (ambos `_ => AppColors.primary` como
default) y el mapa paralelo completo de `conversaciones_screen.dart:423-450`.
Los tres se pliegan a `AppTheme.statusColor` en su fase.

### 5.3 Garantías WCAG documentadas en código que dejan de ser ciertas

- **`AppColors.textLight` (colors.dart:34-37)** documenta que `#627188` se eligió
  porque slate-500 daba 4.34:1. El valor nuevo `#3A4A63` sobre papel da
  **8.13:1** — la garantía se *fortalece*. **Reescribir el comentario, no
  borrarlo**: documenta un bug real del pasado.
- **`ProColors` (pro_palette.dart:18-21, 29-33, 38-41)** — sus comentarios pasan
  a ser **activamente falsos y peligrosos**:
  - `onAccent = #06283B` dice "nunca uses blanco sobre accent". Contra el acento
    claro nuevo (blueprint `#2B4C7E`) el blanco da **8.61:1** y `#06283B` da
    ~1.4:1. **Es la regresión silenciosa más peligrosa de todo el restyle**:
    etiquetas casi negras sobre botón azul oscuro.
    *Verificado:* sitios reales en `pro_ui.dart:773`, `:605`,
    `mis_servicios_screen.dart:242` y `:491`, y 6 sitios de
    `contratacion_detail_screen.dart` (`:79, :157, :226, :297, :520, :531`).
  - `onDanger = #2C0505` — mismo modo de falla contra `#A32015`.
  - `textMuted #828F9C` "no bajar de este valor" — sobre blanco da ~2.6:1. Debe
    colapsarse en `inkSoft`.

### 5.4 Pares críticos, para tener en registro

`ink/paper 14.26` · `ink/card 15.75` · `inkSoft/paper 8.13` · `inkSoft/card 8.98` ·
`rust/card 4.71` · **`rust/paper 4.27` ← reprueba AA** (verificado a mano: el texto
óxido, ej. el precio, debe ir sobre tarjeta blanca, nunca directo sobre el fondo
papel) · `rustDark/card 6.68` · `blueprint/card 8.61` · `verified/card 6.13` ·
sidebar inactivo `rgba(255,255,255,.68)` sobre el degradado ink = **7.97–8.74** ✓ ·
píldora óxido sobre sidebar = **3.34** (gráfico, pasa 1.4.11).

---

## 6. Orden de fases

### Fase 0 — Preparación. Sin cambio visual. Se puede desplegar.
- Descargar las 3 familias a `assets/fonts/`
  (`BigShouldersDisplay[wght].ttf`, `Archivo[wdth,wght].ttf`,
  `IBMPlexMono-Regular/-Medium/-SemiBold.ttf`) desde
  `raw.githubusercontent.com/google/fonts` (OFL), registrarlas en `pubspec.yaml`
  bajo `flutter: fonts:`. **Conservar la entrada de Inter por ahora.**
- Borrar código muerto ya verificado: `ChatPalette` (`pro_ui.dart:625-661`),
  `AppTheme.tertiary/accent/info/premium`, `shared/widgets/cta_button.dart`,
  `shared/widgets/rating_badge.dart`.
- Crear (sin usar todavía): `lib/shared/theme/ticket_border.dart`,
  `lib/shared/widgets/ticket_card.dart`, `lib/shared/widgets/eyebrow.dart`.
- Extraer el formateador de tiempo relativo privado de `oportunidades_screen.dart`
  a `lib/core/utils/` (lo necesitan 3 mockups; hoy solo existe ahí).

### Fase 1 — **EL BIG BANG. No se puede dividir.**

Un solo commit con: `utils/colors.dart` · `app/theme.dart` (ambos ColorSchemes,
`_fontFamily`, `_textTheme`, `_inputTheme`, `_tabBarTheme`, `_base`,
`statusColor`) · `shared/theme/tokens.dart` · `app/app.dart`
(`themeMode: ThemeMode.light`) · `shared/theme/pro_palette.dart` (re-valorado a
claro) · `pro_ui.dart` (colapso de `RolePalette` + la línea de `ProButton`) ·
`cli_ui.dart` · `shared/layout/app_sidebar.dart` (3 factories) · los ~30
re-apuntes de tintes decorativos de `primary` · **el barrido global de
`BorderRadius.circular(n)`** (§8a).

**Por qué no se puede dividir:** los miembros de `ProColors` son `const` y
aparecen dentro de `const BoxDecoration(...)` en 11 archivos. Re-valorarlos a
claro re-pinta esas 11 pantallas al instante — pero si el fondo de `ProScaffold`
(`pro_ui.dart:33`) y `AppSidebar.proveedor` no se voltean en el **mismo** commit,
toda el área de proveedor queda texto blanco sobre blanco. Simétricamente,
cambiar `AppColors` sin `themeMode: light` deja a los usuarios con el sistema en
oscuro sobre el tema azul viejo. No existe un orden de esos cuatro cambios que
produzca un estado intermedio desplegable.

**Todo lo posterior a la Fase 1 es por-superficie y desplegable individualmente.**

### Fase 2 — Despliegue del motivo
Cambiar las tripas de `ProCard` (`pro_ui.dart:268`) y `CliCard` (`cli_ui.dart:28`)
para que deleguen en `TicketCard`; apuntar `CardThemeData.shape` a `TicketBorder`.
**2 archivos editados, 21 consumidores heredan.**

### Fase 3 — Shell y cromo
`app_sidebar.dart`, `cliente_shell.dart`, `proveedor_shell.dart`,
`admin_shell.dart` (además: borrar los dos wrappers ahora redundantes
`Theme(data: AppTheme.light)` en `admin_shell.dart:69` y `:140`, y el
`Color(0xFF0F172A)` hardcodeado del AppBar en `:99`). Envolver los tres
`NavigationBar` en un `DecoratedBox` con borde superior de 1px `--line`
(`NavigationBar` no tiene slot de borde).

### Fase 4 — Cluster de auth
`login 481` · `register 1110` · `forgot` · `reset` · `email_verified` · `totp` ·
`verificación`. Es el más chico, el más visible y totalmente autocontenido —
buen piloto. Tarjeta `.ticket`, labels mono en mayúscula, CTA óxido, links
blueprint, anillo de foco `--ink`.
**Quitar la divergencia `_roleColor` de `register_screen.dart:59`** — el mockup
(`register.html:43`) pinta la opción de rol activa en tinte óxido para *ambos*
roles. **Conservar el wizard de 3 pasos**: el mockup es de un solo paso, y eso es
una simplificación del mockup, no una especificación.

### Fase 5 — Landing (absorbe el plan anterior)
De `plan-restyle-landing-ideal.md` se **eliminan** tres pasos que ahora son
globales: definir constantes `_kInk`/`_kRust` locales al archivo, construir
`_TicketDecoration`/`_TicketCard` privados, y aplicar las 3 familias con
`TextStyle(fontFamily:)` literal.
Se **conserva textual**: su tabla de origen de fuentes, sus decisiones de datos
honestos (testimonios omitidos; sección de solicitudes en vivo alimentada por el
`SolicitudesService` real; mapa estático de fotos de categoría con respaldo a
ícono), la excepción de `CachedNetworkImage`, el bento compuesto a mano (sin
paquete de grid escalonado) y su paso de verificación de fuentes en producción.

### Fase 6 — Cliente (5 mockups)
`cliente_landing 1252` · `mis_solicitudes 607` · `mis_contrataciones 442` ·
`crear_solicitud 1068` · `solicitar_servicio 681` · `servicios_list 374` ·
`servicio_detail 701`.

### Fase 7 — Proveedor (6 mockups)
`proveedor_dashboard 599` · `oportunidades 662` · `mis_propuestas 334` ·
`mis_servicios 554` · `crear_editar_servicio 1403` · `proveedor_cobros 442`.

### Fase 8 — Admin (8 mockups)
Mayor delta estructural: los mockups usan `<table>` reales con `thead` mono en
mayúscula; hoy las pantallas admin usan Cards/ListTiles (y solo algunas
`DataTable` sobre 800px). Introducir **un** `lib/shared/widgets/data_table_ticket.dart`
**antes** de tocar las 8 pantallas. Piloto: `admin_usuarios 1493`.

### Fase 9 — Chat
`conversaciones 655` + `chat_panel 999`. Master-detail con borde de 1px, lista de
300px, burbuja saliente `--ink` con texto blanco (15.75:1), entrante blanca con
borde `--line`, fondo del hilo `--paper`, botón de envío circular óxido.
Plegar el mapa de color de `conversaciones_screen.dart:423-450` en
`AppTheme.statusColor`.

### Fase 10 — Limpieza de widgets compartidos
`empty_state.dart` (8 importadores) · `skeleton_loader.dart` (8) ·
`premium_badge.dart` (3) · `servicio_card.dart` (2) · `help_modal.dart` ·
`success_dialog.dart` · `confetti_overlay.dart`.
Luego **deduplicar el fork** `auth/profile_screen.dart` (1594) /
`proveedor_profile_screen.dart` (1904): extraer los 9 widgets privados con
nombres idénticos (`_EditarPerfilDialog`, `_ProfileSideCard`, `_MiniKpiItem`,
`_PersonalInfoCard`, `_InfoGridTile`, `_ActivityMetricsCard`, `_ActivityGridTile`,
`_SecurityCard`, `_SecurityItemRow`) a `lib/shared/widgets/profile/`.
**Va al final**: es una refactorización, no un restyle, y hacerlo antes obliga a
restylear el mismo código dos veces.

### Fase 11 — Barrido de deriva
Eliminar Inter de `pubspec.yaml` + reescribir `DESIGN.md` (§8).

---

## 7. El motivo `.ticket` en Flutter

**Recomendación: un `ShapeBorder` (`extends OutlinedBorder`), NO un
`CustomPainter` y NO un `Decoration`.**

```
lib/shared/theme/ticket_border.dart   → class TicketBorder extends OutlinedBorder
lib/shared/widgets/ticket_card.dart   → class TicketCard extends StatelessWidget
```

**Por qué gana `ShapeBorder`:** entra en todos los slots donde el código *ya*
pasa un `RoundedRectangleBorder` — `CardThemeData.shape` (`theme.dart:356`),
`Material(shape:)`, `InkWell(customBorder:)`,
`Container(decoration: ShapeDecoration(shape:))`, `Dialog`, `BottomSheet`,
`FilledButton.styleFrom(shape:)`. El despliegue es un buscar/reemplazar del
literal `RoundedRectangleBorder(...)` y `ProCard`, `CliCard`, `CardThemeData` y
todos los diálogos heredan las marcas. Un `CustomPainter` obligaría a envolver
cada sitio en un `Stack`/`CustomPaint`; un `Decoration` no compone con
`Card.shape` ni con `InkWell.customBorder` y rompe el clipping del splash.

Detalles de implementación que importan:
- `paint()`: (1) trazar el `RRect` con `strokeWidth: 1` en `--line`; (2) cuatro
  `drawLine` formando las dos L — superior-izquierda (abajo + derecha) e
  inferior-derecha (arriba + izquierda), `strokeWidth: 2`,
  `strokeCap: StrokeCap.square`, brazo de **9**, color `ink @50%`. Dibujar sobre
  `rect.deflate(0.5)` con antialiasing, si no las marcas de 2px desaparecen a
  device-pixel-ratio 1.0.
- **`getOuterPath` debe devolver el rect redondeado plano.** Las marcas son solo
  pintura — si se meten en el path, se rompen el hit-testing, el clipping de
  `Material` y los splashes de tinta.
- Implementar `scale`, `copyWith`, `lerpFrom`/`lerpTo` (devolver `null` está
  bien) y `==`/`hashCode` — Flutter los llama en las transiciones de tema.
- Constructor: `TicketBorder({double radius = 8, bool marks = true, Color line,
  Color ink, double side = 1})`. Con `marks: false` se obtiene la caja simple de
  1px que usan los KPIs y la tabla de `admin/usuarios.html` (que **no** son
  `.ticket`), así que una sola clase cubre ambos casos.
- El mockup pone las marcas en `top/left: -1px` (fuera del borde). En Flutter,
  dibujarlas *sobre* la línea es visualmente equivalente y evita que las recorte
  un `ClipRect` ancestro — ojo que `proveedor_shell.dart:52` envuelve el
  contenido en `ClipRect`, así que todo lo pintado fuera de límites se pierde.

Dos primitivas acompañantes, mismo directorio:
- `eyebrow.dart` — cuadrado óxido de 6px + IBM Plex Mono 11px, `letterSpacing:
  1.54` (`.14em`), mayúsculas.
- **No agregar un widget de badge nuevo.** El `.badge` del mockup *es*
  `StatusBadge` con radio 3 + mono mayúscula.

---

## 8. Retirar `RolePalette` sin tocar los 11 consumidores de `pro_ui`

`RolePalette` tiene **11 sitios de llamada en exactamente 2 archivos**
(`contratacion_detail_screen.dart` ×7, `mis_contrataciones_screen.dart` ×4).
`ProColors` tiene ~250 referencias en 11 archivos.

**Paso A — volver inalcanzable la rama oscura, conservando el tipo y los nombres.**
En `pro_ui.dart:581-614`, reemplazar los ternarios de la lista de inicialización
por resoluciones claras incondicionales: `scaffold/bg` → `AppColors.paper`;
`surface/surfaceHi` → `colorScheme.surface`; `border` → `colorScheme.outline`;
`textPrimary` → `colorScheme.onSurface`; `textSecondary/textMuted` →
`colorScheme.onSurfaceVariant`; `accent` → `AppColors.blueprint`;
**`onAccent` → `Colors.white`** (la trampa de §5.3); `cardShadow` → `null` (ambos
consumidores lo pasan directo a `boxShadow:`, que es nullable — verificado);
`statusColor(s)` → `AppTheme.statusColor(s)`.
Conservar `final bool dark;` y **ambos constructores** para que
`RolePalette(esProveedor, context)` de `contratacion_detail_screen.dart:262` siga
compilando. Marcar el campo y la clase con `@Deprecated`.
→ **Cero ediciones en las 2 pantallas consumidoras**, y quedan claras al instante.

**Paso B — `ProColors`: re-valorar en el lugar, NO borrar.**
Borrar una clase `const` con 250 referencias dentro del commit big-bang es cómo
se llega a un `flutter analyze` con 300 errores. En vez de eso, `pro_palette.dart`
conserva todos los nombres con valores claros:

| miembro | usos | valor nuevo |
|---|---|---|
| `bg` | 14 | `#F2F4F3` |
| `surface` | 14 | `#FFFFFF` |
| `surfaceHi` / `elevated` | 7 / 5 | `#F2F4F3` |
| `border` | 26 | `#D7DCD8` |
| `textPrimary` | 46 | `#12233D` |
| `textSecondary` | 50 | `#3A4A63` |
| `textMuted` | 7 | `#3A4A63` (colapsado) |
| **`accent`** | **51** | **`#2B4C7E` (blueprint), no óxido** |
| `amber` | 14 | `#8A6508` |
| `success` | 15 | `#3F6B4F` |
| `danger` | 16 | `#A32015` |
| `onAccent` | 3 | `#FFFFFF` |
| `onDanger` | 1 | `#FFFFFF` |

**La decisión sobre `accent` es el punto de apalancamiento.** De sus 51 usos, ~48
son decorativos (halo de `ProAvatar` `:439`, ícono de `ProQuickAction` `:680`,
`ProMetricTile` `:142`, barra de `ProSectionHeader` `:233`, `ProCard` `:294`,
`ProEmptyState` `:499`, `ProLoading` `:545`, `ProInput.focusedBorder` `:889`).
Solo **uno** significa "relleno de CTA": `pro_ui.dart:794` dentro de `ProButton`.
Poniendo `accent = blueprint` quedan 48 sitios correctos con cero ediciones, y se
cambia exactamente una línea (el `backgroundColor` de `ProButton` → óxido).
Al revés habría que barrer ~25 sitios. **Reescribir los tres doc-comments
obsoletos en el mismo cambio** — dejarlos es peor que borrarlos.

**Paso C —** las Fases 6/7 reescriben las pantallas para referenciar
`AppColors`/`Theme.of(context)` directo. La **Fase 10** borra `pro_palette.dart`,
`RolePalette` y el `export` de `pro_ui.dart:7`.

---

## 9. Deriva: ~115 hex sueltos / 400 `fontSize` inline / ~330 radios

Tres ejes, tres respuestas distintas.

**(a) Radios — mecánico, máximo apalancamiento, y va DENTRO de la Fase 1.**
~330 llamadas con 20 valores: `12`×91, `16`×49, `18`×35, `20`×29, `10`×21,
`14`×20, `8`×16, `999`×13, `28`×10, `24`×10, más la cola. El vocabulario destino
son dos números (4, 8) más `pill`. El mapeo es determinista por clase de widget:
botones/chips/inputs/badges → `Radii.sm`; contenedores/tarjetas/tiles/sheets →
`Radii.md`; avatares/píldoras → `Radii.pill`.
**Va en la Fase 1 porque un radio a medio migrar es el estado intermedio roto más
visible que existe** — una píldora de 20px al lado de un botón de 4px se lee como
un bug, mientras que un hex suelto se lee como un matiz.

**(b) Hex sueltos — fase propia (Fase 11), con script + revisión.**
Tabla de sustitución: `0xFF1D4ED8→AppColors.primary` ·
`0xFF0F172A→AppColors.textDark` · `0xFF64748B|0xFF627188|0xFF94A3B8→textLight` ·
`0xFFCBD5E1→border` · `0xFFF1F5F9→background` · `0xFF10B981|0xFF059669→success` ·
`0xFFEF4444|0xFFDC2626→danger` · `0xFFF59E0B|0xFFD97706→secondary`, más los restos
Tailwind en `conversaciones_screen.dart:423-450`, `chat_panel.dart:649/935/991`,
`app_sidebar.dart:208/209/217/218/290/313/459/474/478`.
~15 de los ~115 son paradas de gradiente que necesitan una *decisión de diseño*,
no una sustitución: **los mockups contienen exactamente UN gradiente** (el de la
sidebar) y un glow radial. Todos los demás gradientes de la app **se borran, no se
traducen**.
**Guarda posterior:** el repo tiene `tools/` y `deploy.ps1` pero no infra de lint.
Lo más barato y durable es un `tools/check_tokens.ps1` invocado desde `deploy.ps1`
que falle si aparece `Color(0x` fuera de `lib/utils/colors.dart`,
`lib/app/theme.dart` y `lib/shared/theme/`. Sin eso la deriva vuelve en dos
meses — que es exactamente lo que documentó `docs/ui-audit-master.md`.

**(c) `fontSize` inline — NO es fase propia, viaja con cada fase de pantalla.**
400 sitios, 27 valores (`13`×84, `14`×64, `12`×63, `11`×40, `16`×31, `15`×29…).
Un grep no puede inferir si `fontSize: 13` debe ser `bodySmall` o `labelMedium`:
es semántico. Barrerlo a ciegas produciría 400 decisiones arbitrarias.
En vez de eso: la Fase 1 deja `Theme.of(context).textTheme` correcto, y cada fase
de pantalla borra los tamaños inline de *esa* pantalla como parte de la reescritura
que ya está haciendo. **Criterio de salida por fase:**
`grep -c "fontSize:" <archivos de la fase>` devuelve 0.

> ⚠️ **Trampa relacionada: NO redimensionar el `textTheme` globalmente en la Fase 1.**
> Los mockups son web de escritorio a 13.5px de cuerpo; el `_textTheme` actual es
> `bodyMedium: 16`. Bajar 16→13.5 global re-fluye todas las pantallas a la vez, y
> 13.5px es muy chico para una app Flutter móvil. **En la Fase 1 se cambian solo
> familias y pesos**, más las 4 familias mono nuevas. Los tamaños chicos del
> mockup se adoptan por pantalla, donde el layout lo soporte.

**Cuatro estilos nuevos en `AppTheme`** (única API nueva — `TextTheme` no tiene
slot mono): `eyebrow` (IBMPlexMono 11/w600/ls 1.54), `dataLarge` (22/w600/
`FontFeature.tabularFigures()`), `dataSmall` (12/w600/tabular), `badgeLabel`
(10.5/w700/ls 0.3).
**Big Shoulders Display va solo en `displayLarge`/`displayMedium`** — los mockups
lo usan exclusivamente para el wordmark y el H1 de la landing; los `h2`/`h3`
in-app son Archivo 800, así que `headline*`/`title*` siguen en Archivo.

**Reescritura de `DESIGN.md`** (Fase 11): reemplazar la sección "The Inter-Only
Rule" (línea 184) por una regla de tres familias con el reparto exacto de roles y
la prohibición de introducir una cuarta; actualizar el bloque YAML `typography:`
(líneas 26–51) y las entradas `text-primary-dark`/`text-secondary-dark` (24–25);
agregar la tabla de contraste de §5.4 como línea base aceptada; documentar
`TicketBorder` y la regla "sin sombras, `Elevation.e1 == []`".

---

## 10. Auditoría de datos honestos

Cruzado contra los modelos `Solicitud`, `Servicio`, `Usuario`, `Contratacion`,
`Resena` y los proveedores reales de cada pantalla.

### Debe ELIMINARSE (no existe el campo, no hay derivación posible)

| mockup | elemento | por qué |
|---|---|---|
| `proveedor/dashboard.html:191` | badge **`Urgente`** | `Solicitud` no tiene campo de prioridad/urgencia. |
| `proveedor/dashboard.html:191,199,207` | **`$25.000/h`, `Desde $30.000`** | `Solicitud` solo tiene `presupuestoMax` (nullable). No hay modalidad por hora ni mínimo. → `Hasta $X` / `A convenir`. El commit `b50f002` ya arregló un bug donde `precio_max` se leyó mal como rango. |
| `proveedor/dashboard.html:212-221` | **"Últimas reseñas"** con nombre, avatar y ★★★★★ | `Resena` solo tiene `calificadorId` — sin nombre ni avatar — y el único endpoint es `getResenasUsuario(usuarioId)`. Mismo hallazgo que ya hizo el plan de la landing. → eliminar, o renderizar puntuación + comentario + fecha con "Cliente · hace 3 d". **Decidir contra la API real, no asumir.** |
| `cliente/buscar.html:228-248` | **`· 112 trabajos`** | No existe contador de trabajos completados en `Servicio` ni `Usuario`. `proveedorRating` **sí** es real → conservar la ★, reemplazar el conteo por el chip real de verificado (`proveedorEsPremium`/`proveedorDocEstado`). |
| `cliente/buscar.html:228,240` | **fotos** de proveedor en las cards | `Servicio` tiene `proveedorNombre` pero no URL de avatar. Usar la variante `.avatar-fallback` de iniciales del propio mockup. |
| `proveedor/perfil.html` | **`Banco Estado · ····6284`** | `Usuario` solo expone `bankConfigured: bool`. → "Cuenta bancaria configurada / Configurar". Verificar si existe endpoint `/me/bank` antes de mostrar más. |
| `cliente/perfil.html` | **"Métodos de pago"** | Los pagos son mediados por gateway (Fintoc); verificar si existe endpoint de instrumentos guardados. Si no, enlazar a la pantalla real de pagos o eliminar la fila. |
| `cliente/perfil.html` | **"Correo, push y WhatsApp"** | WhatsApp no es un canal de esta app. Corregir el copy a los canales reales. |
| `cliente/chat.html:102-103` | **punto verde "En línea"** | No hay sistema de presencia — el chat es por polling (`ChatProvider`). Eliminar. |
| `admin/soporte.html` | formato **`#SOP-330`** | Prefijo casi seguramente inventado — usar el id real del payload. |
| `admin/suscripciones.html` | tier **"Premium Anual"** | Verificar que sea un plan real y no un segundo tier inventado. |
| `admin/pagos.html` | columna **Gateway** y **`#TXN-88430`** | El commit `b50f002` dice "columna Gateway leía una key inexistente" — **re-verificar el nombre real de la key** antes de volver a renderizarla. |

### Real — se puede construir tal como está dibujado

| mockup | elemento | fuente |
|---|---|---|
| `proveedor/dashboard.html:166-181` | los **4 KPIs** | `proveedor_dashboard_screen.dart:67-89` — ingresos desde `payoutStatus == 'SENT'` (ya correctamente más estricto que `status == COMPLETADO`), `activeJobsCount`, `pendingProposalsCount`, `usuario.avgRating`. |
| `proveedor/dashboard.html:189` | categoría, comuna, "hace 12 min" | `Solicitud.categoriaNombre` / `.ubicacionTexto` / `.createdAt`. |
| `cliente/buscar.html:216-222` | tiles de categoría con emoji | `Categoria.icono` es un emoji real. **Pero usar la taxonomía real**, que es más amplia que los 6 oficios manuales dibujados (Arte y Diseño, Asesoría, Clases y Educación, Mascotas, Moda, Música, Tecnología…). No hardcodear los seis del mockup. |
| `cliente/buscar.html` | "cerca de ti" | `Servicio.distancia` es real. |
| **`admin/dashboard.html` — la página completa** | 6 KPIs, gráfico de barras, top categorías, transacciones recientes | Todo ya consumido en `admin_full_dashboard_screen.dart:33-46,123-194`. **Totalmente honesto — es el mejor caso, usarlo de piloto de la Fase 8.** El gráfico de barras hecho a mano ya usa datos reales; solo necesita restyle. |
| `admin/usuarios.html:126-143` | 3 KPIs + tabla Usuario/Rol/Estado/Registro/Acciones | Todo real. |
| `*/perfil.html` | "4.9 Calificación", "2025 Proveedor desde", "✓ Identidad verificada" | `avgRating`, `proveedorActivadoAt`/`createdAt`, `isVerified`+`docEstado`. |
| `proveedor/perfil.html` | "217 Trabajos completados" | No existe el campo, **pero es derivable honestamente** de `ContratacionesProvider` (contar `status == COMPLETADO`), que esa pantalla ya carga. Derivarlo, no eliminarlo. |
| todos los badges de estado | | Renderizar **siempre** vía `AppTheme.statusLabel(status)`, nunca los strings a mano del mockup — los mockups dicen "Abierta/Pendiente/Resuelto" ad hoc mientras el vocabulario canónico vive en `theme.dart:66-86`. |

---

## 11. Verificación por fase

**Fase 0** — `flutter pub get`; renderizar un `Text` de prueba en 3 pesos por
familia más una cadena mono con cifras tabulares; `flutter analyze`; **build web
de release y cargar la URL de producción en un perfil de navegador nuevo** para
confirmar que las familias resuelven de verdad y no caen en silencio a Inter.
(Este repo ya se quemó con el bug de caché de Cloudflare en
`MaterialIcons-Regular.otf`: **un build local verde no es evidencia**.)
Confirmar que los `.ttf` aterrizan en `build/web/assets/assets/fonts/`.

**Fase 1** — `flutter analyze` con **cero issues nuevos** (comparar contra
`analyze_output.txt` como línea base). Barrido manual de una pantalla por familia
a 360 / 768 / 1440: `login`, `cliente_landing`, `proveedor_dashboard`, `admin`
dashboard, `mis_contrataciones` y `contratacion_detail` (los dos consumidores de
`RolePalette`), `conversaciones`. Buscar específicamente: etiquetas casi negras
sobre botón azul (la trampa de `onAccent`), cuerpos de `ProScaffold` invisibles,
contraste del FAB, color del `NavigationBar` seleccionado, y cualquier
`Colors.grey` sobreviviente que ahora choque con la familia papel.
**Todo par fg/bg improvisado se pasa por el cálculo de ratio antes de subir.**

**Fase 2** — visual: las marcas de esquina renderizan en las cuatro esquinas a
dpr 1.0/2.0/3.0; nada recortado por el `ClipRect` de `proveedor_shell.dart:52`;
los splashes de tinta siguen contenidos; la transición de tema no lanza excepción
desde `lerpFrom`/`lerpTo`.

**Fase 3** — orden de tabulación por la sidebar; `Semantics(button:, selected:,
label:)` se sigue emitiendo por ítem (`app_sidebar.dart:329-333`); el drawer móvil
de admin abre; el `NavigationBar` respeta el safe-area inferior; en landscape
corto el footer de la sidebar sigue reservando su altura.

**Fases 4–9, por pantalla** — (a) `flutter analyze`; (b) click-through real de
cada ruta que la pantalla alcanza, enumerada desde `router.dart` (no inspección
visual); (c) capturas a 320 / 390 / 768 / 1440; (d)
`grep -c "fontSize:\|Color(0x" <archivo>` devuelve 0; (e) **los estados de carga,
vacío y error también se restylean** — `ProEmptyState`, `ProSkeleton`,
`empty_state.dart`, `skeleton_loader.dart` son los que se olvidan siempre;
(f) por cada dato mostrado, nombrar el campo del modelo del que viene — ese es el
contrato de §10.

**Fase 9 (chat)** además — el badge de no-leídos sigue incrementando, el polling
sigue corriendo, y `clearUnreadMessages()` sigue disparando al cambiar de pestaña
(`proveedor_shell.dart:16-18`).

**Fase 11** — conteos antes/después de `Color(0x`, `fontSize:` y
`BorderRadius.circular(` registrados en `DESIGN.md`; `tools/check_tokens.ps1`
cableado a `deploy.ps1` y **probado fallando** con un literal reintroducido a
propósito.

> **Nota sobre cobertura automatizada:** hay solo 6 archivos de test
> (`api_client`, `format_error`, `guard_helper`, `resena_flow`, `usuario_model`,
> `widget_test`) y **ninguno referencia `AppColors`/`AppTheme`/`ProColors`**.
> Ningún test va a atrapar una regresión visual. Esa es la razón más fuerte de que
> los límites de fase estén trazados por familia de pantalla y sean desplegables
> por separado.

---

## 12. Archivos críticos

| Archivo | Rol |
|---|---|
| `lib/utils/colors.dart` | paleta base, 40 importadores |
| `lib/app/theme.dart` | ThemeData, tipografía, vocabulario de estado |
| `lib/shared/theme/tokens.dart` | Spacing/Radii/Elevation/Motion, 42 importadores |
| `lib/shared/theme/pro_palette.dart` | `ProColors`, re-valorado a claro |
| `lib/features/proveedor/presentation/widgets/pro_ui.dart` | kit mayor + `RolePalette` |
| `lib/features/cliente/presentation/widgets/cli_ui.dart` | kit cliente |
| `lib/shared/layout/app_sidebar.dart` | 3 factories, las 3 shells |
| `lib/app/app.dart` | `themeMode` |
| `lib/shared/theme/ticket_border.dart` | **nuevo** — el motivo |
| `design-concepts/**/*.html` | la especificación |
