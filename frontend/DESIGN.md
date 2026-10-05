---
name: TrabajoYa
description: Marketplace de servicios verificados en Chile
# Fuente de verdad: lib/utils/colors.dart (AppColors) + lib/app/theme.dart
# (ColorSchemes). Estos valores están sincronizados con el código — si cambian
# en el código, actualizar aquí. NO editar aquí y esperar que el código siga.
colors:
  primary: "#1D4ED8"        # AppColors.primary
  primary-dark: "#1E3A8A"   # AppColors.primaryDark
  primary-light: "#DBEAFE"  # AppColors.primaryLight
  primary-on-dark: "#60A5FA" # darkColorScheme.primary (tint por contraste)
  secondary: "#F59E0B"      # AppColors.secondary (ámbar)
  success: "#10B981"        # AppColors.success
  error: "#EF4444"          # AppColors.danger
  warning: "#F59E0B"        # AppColors.warning
  cta: "#10B981"            # verde transaccional = success
  background: "#F1F5F9"     # AppColors.background
  surface: "#FFFFFF"        # AppColors.surface
  text-primary: "#0F172A"   # AppColors.textDark
  text-secondary: "#64748B" # AppColors.textLight
  border: "#CBD5E1"         # AppColors.border
  surface-dark: "#131C2E"   # darkColorScheme.surface
  background-dark: "#0B1120" # scaffold dark
  text-primary-dark: "#E2E8F0"   # darkColorScheme.onSurface
  text-secondary-dark: "#94A3B8" # darkColorScheme.onSurfaceVariant
typography:
  display:
    fontFamily: "BigShouldersDisplay, sans-serif"
    fontSize: "36px"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: "Archivo, sans-serif"
    fontSize: "24px"
    fontWeight: 800
    lineHeight: 1.3
  title:
    fontFamily: "Archivo, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "Archivo, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "IBMPlexMono, monospace"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.3
rounded:
  sm: "8px"
  md: "12px"
  lg: "14px"
  xl: "20px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xl2: "32px"
  xl3: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 32px"
    height: "52px"
  button-primary-hover:
    backgroundColor: "{colors.primary-dark}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 32px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    padding: "16px 32px"
  button-cta:
    backgroundColor: "{colors.cta}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "16px 32px"
  card-default:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  input-default:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "{spacing.md} {spacing.lg}"
  chip-default:
    backgroundColor: "transparent"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm} {spacing.md}"
  chip-selected:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm} {spacing.md}"
---

# Design System: TrabajoYa

## 1. Overview

**Creative North Star: "El Refugio Confiable"**

Un marketplace que abriga al usuario en cada paso: desde que busca un servicio hasta que paga con tranquilidad. La interfaz es un espacio sereno, profesional y predecible — nunca sorprende negativamente. Cada interacción refuerza la certeza de que está en buenas manos.

El sistema rechaza explícitamente la estética sci-fi, el neón, el glassmorphism y cualquier efecto decorativo sin función. No hay gradientes llamativos ni oscuridad forzada. La confianza se comunica con claridad tipográfica, azul primario sólido y suficiente espacio para respirar.

**Key Characteristics:**
- Sereno pero profesional — ni frío ni juvenil
- Azul confianza como ancla visual, verde para acciones transaccionales
- Completamente funcional: nada decorativo sin propósito
- Consistente en mobile, tablet y desktop (Material 3)
- Accesible desde el primer píxel (WCAG AA)

## 2. Colors

Palabra funcional sobre atmósfera: los nombres describen el rol, no la emoción.

> Valores exactos y única fuente de verdad: `lib/utils/colors.dart` (`AppColors`)
> y los `ColorScheme` de `lib/app/theme.dart`. Los hex de abajo reflejan ese código.

### Primary
- **Primary Blue** (#1D4ED8 · `AppColors.primary`): Botones principales, enlaces, navegación activa, acentos confiables. Es el color que el usuario asocia con "TrabajoYa". En modo oscuro se aclara a #60A5FA (`darkColorScheme.primary`) por contraste.
- **Primary Dark** (#1E3A8A · `AppColors.primaryDark`): Hover de botones primarios, hero/splash, fondos oscuros institucionales.

### Secondary
- **Amber Accent** (#F59E0B · `AppColors.secondary`): Ratings (estrellas), badges de advertencia, elementos premium o destacados. Usar con moderación — su saturación compite con el primary. **Nunca** como fondo con texto blanco (contraste insuficiente): usar `StatusBadge` (píldora tintada con texto oscurecido legible).

### Success / CTA
- **Success Green** (#10B981 · `AppColors.success`): Acciones transaccionales (Comprar, Pagar, Contratar), estados de éxito, confirmaciones. Nunca usar para acciones destructivas.

### Error / Danger
- **Danger Red** (#EF4444 · `AppColors.danger`): Errores, validación fallida, acciones destructivas, cancelaciones, disputas. Acompañado siempre de texto o icono — nunca solo color.

### Neutral (modo claro)
- **Page Background** (#F1F5F9 · `AppColors.background`): Lienzo de la aplicación.
- **Card Surface** (#FFFFFF · `AppColors.surface`): Tarjetas, inputs, contenedores elevados.
- **Text Primary** (#0F172A · `AppColors.textDark`): Titulares y cuerpo principal. Alto contraste.
- **Text Secondary** (#64748B · `AppColors.textLight`): Subtítulos, metadata, textos de ayuda.
- **Border** (#CBD5E1 · `AppColors.border`): Divisores, bordes de inputs, líneas de separación.

### Neutral (modo oscuro)
- **Scaffold** (#0B1120) · **Surface** (#131C2E · `darkColorScheme.surface`) · **Texto** (#E2E8F0 / #94A3B8). Nunca hardcodear estos valores en pantallas: usar `Theme.of(context).colorScheme` o el kit `CliColors.*(context)`.

### The One Voice Rule
El azul primario ocupa ≤20% de cualquier pantalla. Su rareza relativa es lo que le da peso. Los CTAs verdes son aún más escasos: máximo 1-2 por vista. Si todo compite por atención, nada la gana.

### Fuente única de color (regla dura)
El color de marca es **#1D4ED8** (`AppColors.primary` en `lib/utils/colors.dart`) — **única** fuente. Prohibido introducir azules/teales paralelos (histórico a eliminar: teal `#0F766E`, azul `#1A73E8`). Sobre superficie oscura del proveedor se usa el tint `#4FA9EC` (`ProColors.accent`) **solo** por contraste — es un derivado documentado, no un color nuevo.

## 2.b Sistema por rol (dirección visual)

TrabajoYa usa **un sistema con tres tiers deliberados**, no tres estilos accidentales. Todos comparten tokens (color de marca, `Spacing`, `Radii`, `Elevation` de `tokens.dart`) y componentes de confianza.

- **Cliente → Marketplace premium minimal + trust-first** (claro). Superficies blancas, aire, jerarquía tipográfica fuerte, profundidad sutil, señales de confianza con **dato real** (nunca `★★★★★` fijo). Kit: `cli_ui.dart` (`CliCard`, `CliSectionHeader`, …).
- **Proveedor → SaaS operativo (workspace oscuro), plano.** Lienzo `#0B1016`, tarjetas con borde sutil, **sin glows ni gradientes decorativos**. Densidad de trabajo. Kit: `pro_ui.dart` (`ProColors`, `ProCard`, `ProScaffold`, …). El oscuro es identidad "Pro" deliberada, no dark-forzado genérico.
- **Admin → SaaS operativo claro denso.** Sidebar navy + contenido claro, tablas/listas densas y legibles. Kit: `admin_shell.dart` + `AppTheme.light`.

Los tres shells comparten el **mismo** sidebar navy y el **mismo** color activo de marca (azul) — nunca colores activos arbitrarios por rol.

## 3. Typography

El sistema utiliza tres familias tipográficas distintas, cada una con un rol semántico inquebrantable. Se deroga explícitamente la regla "Inter-Only" anterior.

**Familias y Roles:**
1. **Big Shoulders Display:** Exclusivo para Display (`displayLarge`, `displayMedium`). Usado en el wordmark y H1 de la landing. No se usa in-app.
2. **Archivo:** Títulos y cuerpo de lectura (`headline*`, `title*`, `body*`). Funcional, técnica pero accesible.
3. **IBM Plex Mono:** Etiquetas, datos, badges y metadatos técnicos (`label*`, `eyebrow`, `dataLarge`, `dataSmall`, `badgeLabel`). Ideal para lectura de cifras y estados.

### Hierarchy
- **Display** (Big Shoulders, w700, 36px, 1.2): Hero, splash, landing. Solo en superficies de marca.
- **Headline** (Archivo, w800, 24px → 20px, 1.3): Títulos de sección, pantallas principales. Escala responsive.
- **Title** (Archivo, w600, 18px → 16px, 1.4): Títulos de tarjeta, encabezados de lista.
- **Body** (Archivo, w400, 16px, 1.5): Texto de lectura. Cap en 75 caracteres por línea.
- **Label / Data** (IBMPlexMono, w600, 14px, 1.3): Botones, chips, badges, cifras tabulares, metadata. Usar weight 600/700 y `letterSpacing` ajustado.

### La regla de las 3 Familias
Queda estrictamente prohibido introducir una cuarta familia. Las tres familias cubren el 100% de las necesidades del sistema visual "orden de trabajo".

## 4. Elevation

Profundidad ligera pero presente. El sistema usa sombras suaves para crear una jerarquía espacial sutil sin caer en capas innecesarias.

### Shadow Vocabulary
- **e0** / **e1** (ninguna): Elementos planos por defecto. El lenguaje "orden de trabajo" es plano con bordes finos de 1px. **Las tarjetas y contenedores NO usan sombra (`Elevation.e1 == []`).**
- **e2** (0 4px 12px rgba(0,0,0,0.08)): Navegación inferior, menús desplegables. Capas flotantes.
- **e3** (0 8px 24px rgba(0,0,0,0.12)): Diálogos, modales, bottom sheets. La elevación más alta.

### The Flat-At-Rest Rule
Los elementos de contenido son planos. La separación se logra con margen y borde `--line` (`AppColors.border`). Las sombras (`e2` / `e3`) aparecen solo como respuesta a estado (overalays, menús flotantes). Sin sombras decorativas en elementos estáticos.

## 5. Components

### Buttons
- **Shape:** Bordes suavemente curvados (radius 12px). Altura fija de 52px. Padding horizontal generoso (16px/32px).
- **Primary (Blue):** Fondo Primary Blue, texto blanco. Hover: Primary Dark. Transición 200ms easeInOut.
- **Secondary (Outline):** Borde Primary Blue, texto Primary Blue, fondo transparente. Hover: fondo Primary Blue al 8%.
- **CTA (Green):** Fondo Success Green, texto blanco. Reservado exclusivamente para acciones transaccionales (Comprar, Pagar, Contratar).
- **Disabled:** Opacidad 0.38, sin sombra, sin hover.
- **Loading:** Botón mantiene width, muestra indicador circular reemplazando el texto.

### Cards / Containers
- **Corner Style:** Bordes redondeados (radius 14px).
- **Background:** Card Surface (#F8FAFB).
- **Shadow Strategy:** e1 en reposo.
- **Border:** Ninguno. La separación se logra con margen + sombra.
- **Internal Padding:** Spacing.lg (16px).

### Inputs / Fields
- **Style:** Borde Border (#DADCE0), fondo Surface (#F8FAFB), radius 12px.
- **Focus:** Borde Primary Blue, sin glow. Transición 200ms.
- **Error:** Borde Raspberry Red, mensaje de error obligatorio con icono.
- **Disabled:** Opacidad 0.38, fondo ligeramente más gris.

### Chips
- **Style:** Sin borde en reposo. Background transparente para no seleccionados.
- **Selected:** Fondo Primary Blue, texto blanco.
- **Filter Chips:** Con icono de checkmark cuando están seleccionados.

### Navigation
- **Mobile (NavigationBar):** Fondo Surface. Labels con punto de color cuando activos (≥14px). Icono + texto. Altura estándar M3.
- **Tablet/Desktop (NavigationRail):** Colapsado en tablet, extendido en desktop (>1024px). Labels siempre visibles en escritorio.
- **Top AppBar:** Fondo transparente, sin elevación. Título en weight 700, alineado a la izquierda. Altura estándar.

### Status Badge
- **Shape:** Píldora (border-radius 999px), fondo semitransparente del color del estado.
- **Content:** Punto de color (6px) + etiqueta textual. Nunca solo color.
- **Padding:** Horizontal Spacing.sm, vertical 4px.

## 6. Do's and Don'ts

### Do:
- **Do** usar Primary Blue como el color ancla de confianza. ≤20% de la pantalla.
- **Do** acompañar cada estado con texto o icono — nunca solo color.
- **Do** mantener 52px de altura en botones para consistencia táctil.
- **Do** usar text-wrap balance en títulos para evitar huérfanos.
- **Do** preferir flat por defecto, sombras solo en estado interactivo.
- **Do** usar Inter como fuente única en toda la aplicación.

### Don't:
- **Don't** usar neón, glassmorphism, gradientes decorativos ni efectos llamativos — TrabajoYa no es sci-fi.
- **Don't** usar border-left/stripe de color como acento decorativo en tarjetas o listas.
- **Don't** anidar tarjetas. Una tarjeta dentro de otra siempre es incorrecta.
- **Don't** usar texto gris claro sobre fondo tintado — verifica contraste 4.5:1.
- **Don't** poner gradiente en texto (background-clip: text). Usa peso o tamaño para énfasis.
- **Don't** mezclar dos fuentes sans-serif similares. Inter es suficiente.
- **Don't** ocultar contenido detrás de animaciones de entrada. Revelar mejoras sobre un estado ya visible.
- **Don't** mostrar un badge de estado sin etiqueta textual.

## 7. Tokens y Variables
Todas las variables de diseño están mapeadas uno a uno en código a través de `tokens.dart` y `colors.dart`.
El código es la fuente de verdad técnica. Si un valor no existe en tokens, no debe usarse hardcodeado.

## 8. Barrido de Deriva (Drift Sweep)
La "Deriva de Diseño" (Design Drift) ocurre cuando la implementación técnica se desvía de los lineamientos establecidos (por ejemplo, cargar fuentes estáticas en `pubspec.yaml` cuando la directriz indica usar `Google Fonts`, o hardcodear `EdgeInsets.all(16)` en lugar de `Spacing.lg`).

**Reglas para evitar la deriva:**
1. **Auditorías continuas:** Ejecutar barridos periódicos (como la Fase 11) para erradicar configuraciones obsoletas o código hardcodeado.
2. **Single Source of Truth:** Nunca declarar recursos redundantes. Si la tipografía base es `Inter` obtenida vía `google_fonts`, debe eliminarse cualquier asset local `.ttf` de `pubspec.yaml` para aligerar el bundle y prevenir colisiones.
3. **Restricción de dependencias:** Solo los módulos compartidos (`shared/`) y la capa de tokens deben tener la responsabilidad de proveer estilos. Las pantallas consumen, nunca definen.

### Conteos de Deriva (Auditoría Fase 11)
El script de prevención asegura que estos valores permanezcan en cero (para los hexes) y rastreados (para radii/fonts) en el directorio `/lib` (excluyendo tokens):
- **Color(0x):** ~115 antes -> **0 después**
- **BorderRadius.circular():** ~351 antes -> **0 después** (reemplazados por `Radii.sm`, `Radii.md`, `Radii.pill`).
- **fontSize:** 400 antes -> **169 después** (se barren pantalla por pantalla, delegando a `textTheme`).

## 9. Contrastes Críticos y A11Y
Garantías WCAG documentadas en el código base, probadas manualmente para asegurar la accesibilidad visual:

| Relación | Ratio | Status |
|----------|-------|--------|
| `ink` / `paper` | 14.26:1 | ✓ AAA |
| `ink` / `card` | 15.75:1 | ✓ AAA |
| `inkSoft` / `paper` | 8.13:1 | ✓ AAA |
| `inkSoft` / `card` | 8.98:1 | ✓ AAA |
| `rust` / `card` | 4.71:1 | ✓ AA |
| `rustDark` / `card` | 6.68:1 | ✓ AA |
| `blueprint` / `card`| 8.61:1 | ✓ AAA |
| `verified` / `card` | 6.13:1 | ✓ AA |

> **Advertencia de contraste (`rust/paper`):** El color `--rust` sobre `--paper` da un ratio de **4.27:1**, lo cual reprueba el umbral AA. El texto óxido (ej. un precio o CTA sin fondo) debe ir **siempre** sobre tarjeta blanca (`card`), nunca directo sobre el fondo papel.
