# Plan: Restyle de landing_screen.dart al estilo de landing-ideal.html

> ⚠️ **SUPERSEDIDO (2026-08-05) por `plan-restyle-app-completa.md`.**
> No implementar este plan tal cual. La landing pasó a ser la **Fase 5** del
> restyle completo de la app, y tres de sus pasos ya no aplican porque ahora son
> globales: definir constantes de color privadas al archivo, construir un
> `_TicketDecoration`/`_TicketCard` privado, y aplicar las 3 tipografías con
> `TextStyle(fontFamily:)` literal (ahora `AppTheme` sí se toca).
> Lo que **sigue vigente** de este documento: la tabla de origen de las fuentes,
> las decisiones de datos honestos (testimonios omitidos, solicitudes en vivo con
> datos reales, mapa estático de fotos de categoría con respaldo a ícono), la
> excepción de `CachedNetworkImage` y el paso de verificación de fuentes en
> producción. Ver la Fase 5 del plan nuevo.

_Guardado 2026-08-04. Plan aprobado por el usuario antes de empezar la implementación._

## Contexto

Hoy se construyó `design-concepts/landing-ideal.html`, un mockup estático
("landing ideal") con libertad creativa total, en un lenguaje visual de
"orden de trabajo / plano técnico" (navy + óxido + azul plano, tipografía
Big Shoulders Display + Archivo + IBM Plex Mono, tarjetas con marcas de
esquina tipo plano de arquitecto). El usuario pidió adaptar la landing page
**real** de la app (`lib/features/public/presentation/pages/landing_screen.dart`,
rediseñada hoy mismo antes en la sesión con la paleta azul de marca) a ese
mismo estilo visual — manteniendo intacta toda la funcionalidad (rutas,
providers, comportamiento).

Se investigó con un agente de Planificación (leyó ambos archivos completos +
`categoria_model.dart`, `servicio_card.dart`, `resena_model.dart`,
`solicitudes_remote_datasource.dart`, `pubspec.yaml`) y se verificaron sus
hallazgos clave a mano antes de escribir este plan:
- `Categoria` (modelo real) **no tiene campo de foto**, solo `icono` (emoji).
- `Resena` (modelo real) **solo tiene `calificadorId`**, sin nombre/avatar, y
  el único endpoint es `getResenasUsuario(usuarioId)` (por-usuario, no
  público) — no hay forma honesta de mostrar 3 testimonios con nombre+foto
  reales hoy.
- La convención real de imágenes de red en la app es `Image.network` +
  `errorBuilder` (ver `servicio_card.dart:69-96`) — `cached_network_image` es
  una dependencia declarada en `pubspec.yaml` pero **nunca usada** en
  ninguna pantalla.
- No existe ningún widget de acordeón/expansión reutilizable en `lib/shared`.
- La taxonomía real de categorías de nivel superior (confirmada en rondas de
  QA anteriores de esta sesión, viendo `/buscar` en producción) es más
  amplia que los oficios manuales: incluye "Arte y Diseño", "Asesoría y
  Consultoría", "Clases y Educación", "Mascotas", "Moda y Confección",
  "Música", "Tecnología y Desarrollo", etc. — no solo
  gasfitería/electricidad/pintura/limpieza/carpintería/mudanzas. Las fotos
  reales conseguidas hoy (Unsplash, verificadas) solo cubren estos últimos
  6 oficios.

**Decisiones ya confirmadas con el usuario** (no volver a preguntar):
1. **Paleta:** adopción completa de la paleta del concepto (navy/óxido/azul
   plano) en la landing. Se acepta el salto visual al navegar a
   `/login`/`/register` (que siguen con el azul de marca `AppColors.primary`
   — sin tocar `AppColors`/`tokens.dart`/`theme.dart`, esto es 100%
   scoped a `landing_screen.dart`).
2. **Tipografía:** empaquetar 3 fuentes reales como asset local (igual que
   `InterVariable.ttf` hoy), sin agregar el paquete `google_fonts`.
3. **Fotografía:** sí, usar fotos reales de Unsplash (las mismas URLs ya
   verificadas del concepto).
4. **Testimonios:** omitir la sección en este rediseño — no hay datos reales
   para sostenerla honestamente. Queda anotado como trabajo futuro que
   requiere que el backend exponga un endpoint público de reseñas con
   nombre/foto.
5. **Solicitudes en vivo:** consolidar todo en datos reales. Se reemplaza el
   panel lateral actual del hero (`_RealTimeRequestsPanel`) por una sección
   nueva de ancho completo con 3 tarjetas estilo "ticket", alimentada por el
   mismo `SolicitudesService().getSolicitudes(...)` que ya se usa hoy — nada
   de precios/urgencia inventados como en el mockup.

## Fuentes a empaquetar

Descargar directo de `raw.githubusercontent.com/google/fonts/main/ofl/...`
(licencia OFL, sin auth) y registrar en `pubspec.yaml` bajo `flutter: fonts:`
(sin tocar la entrada existente de `Inter`):

| Familia | Archivo(s) | Pesos usados |
|---|---|---|
| Big Shoulders Display | `BigShouldersDisplay[wght].ttf` (variable) | 700, 900 — solo titular hero + wordmark del logo |
| Archivo | `Archivo[wdth,wght].ttf` (variable, **sin** el itálico — no se usa realmente en el concepto, `.hero h1 em` cancela el itálico) | 400–800 |
| IBM Plex Mono | `IBMPlexMono-Regular.ttf` (400), `-Medium.ttf` (500), `-SemiBold.ttf` (600) | sin variante variable disponible upstream, 3 archivos estáticos |

Guardar en `assets/fonts/` junto a `InterVariable.ttf`. Como `app/theme.dart`
no se toca, la pantalla debe aplicar estas 3 familias con `TextStyle(fontFamily: ...)`
literal (no vía `Theme.of(context).textTheme`) — definir un puñado de
helpers de estilo privados al tope de `landing_screen.dart`.

Verificar el font-loading con un `Text` de prueba en cualquier pantalla ya
existente ANTES de tocar la landing, para aislar problemas de fuente de
problemas de layout.

## Widgets nuevos a construir (dentro de landing_screen.dart, privados)

- **`_TicketDecoration`/`_TicketCard`**: `Decoration`/`BoxPainter` a medida
  que pinta relleno + borde de 1px + 2 marcas de esquina en forma de L
  (`Path` + `Paint(style: stroke)`) — reemplaza el uso de `Card`/sombra en
  las tarjetas tipo "ticket" (tarjeta flotante del hero, 3 tarjetas de
  solicitudes).
- **`_Eyebrow`**: widget standalone (hoy es un método privado del `State`,
  hay que extraerlo porque se necesita en widgets que no son ese `State`) —
  punto cuadrado + texto IBM Plex Mono mayúscula con tracking.
- **`_BrandMark`**: badge cuadrado ink con ícono (usar `Icons.handyman_rounded`,
  el más cercano en Material a la llave inglesa del concepto), compartido
  entre header y footer.
- **`_StepGrid`/`_StepCell`**: reconstrucción completa de "Cómo funciona" —
  el concepto NO usa círculos conectados (eso es lo que ya existe hoy en
  `_StepTimeline`/`_StepNode`, agregado en una ronda anterior de hoy), usa
  una fila de 3 celdas con borde/línea fina entre ellas y etiqueta mono
  "01 / PUBLICAR". Reusar solo la lógica de breakpoint (fila en desktop,
  columna en mobile).
- **`_CatPhotoTile` / `_CatPlainTile` / `_CatMoreTile`**: bento grid de
  categorías. Dado que `Categoria` no tiene foto, mantener un mapa estático
  slug/nombre→URL de foto SOLO para las categorías reales que tengan una
  foto conseguida hoy (probablemente bajo "Reparaciones del Hogar" y
  "Transporte y Mudanzas" en la taxonomía real) — el resto de categorías
  reales caen a `_CatPlainTile` (ícono + nombre + conteo), igual que
  "Pintura" en el concepto. Layout: NO usar `GridView` genérico (CSS bento
  con spans arbitrarios no es expresable con los delegates de Flutter sin
  agregar un paquete de grid escalonado, fuera de alcance) — componer a
  mano con `Row`/`Column`/`Expanded` el layout específico de 6-7 celdas del
  concepto.
- **`_FaqItem`**: acordeón a medida (`AnimatedSize` + `InkWell`, usando
  `Motion.fast`/`Motion.curve` de `tokens.dart`) — no existe nada reusable
  en `lib/shared` para esto. 4 preguntas genéricas de política (mismo
  contenido del concepto), sin riesgo de datos falsos.
- **`_GridTexturePainter`**: textura de líneas tipo plano técnico para el
  fondo del CTA final (`CustomPaint` + `ShaderMask` con `RadialGradient`
  para el desvanecido hacia los bordes).

## Mapeo de secciones

| Sección | Acción |
|---|---|
| Header | Reskin: `_BrandMark`, paleta nueva, radio de botón 4px en vez de 12px |
| Hero | Reconstrucción: fondo claro `_kPaper` (hoy es gradiente navy oscuro), layout asimétrico, foto real del pintor + `_TicketCard` flotante con datos reales de la primera solicitud fetched (no inventados) |
| Cómo funciona | Reconstrucción completa como `_StepGrid` |
| Categorías | Reconstrucción como bento compuesto a mano + mapa estático de fotos + fallback a ícono |
| Servicios destacados | Reskin only: mismos datos/lógica de precio (`_formatPrecio`), solo paleta/tipografía/radio |
| Solicitudes en vivo | Nueva sección de ancho completo, 3 `_TicketCard` con datos reales (reemplaza `_RealTimeRequestsPanel`) |
| CTA proveedor | Reemplazado por el dual-CTA de 2 paneles (cliente + proveedor) con foto de fondo |
| Confianza (oscura) | Reskin only: estructura ya reusable, solo cambia paleta/tipografía de los `_BenefitTile` |
| Testimonios | **Omitido** (ver decisiones arriba) |
| CTA final | Reskin + `_GridTexturePainter` de fondo |
| Footer | Reskin, MISMO alcance de enlaces reales (Términos/Privacidad/Contacto) — no agregar columnas "Producto"/"Compañía" con links falsos ni íconos sociales sin URL real |

Además, pasada final obligatoria: barrer TODOS los botones del archivo
(~10 definiciones) de `BorderRadius.circular(12)`/`AppColors.primary` a los
nuevos tokens locales (`_kRadiusSm = 4.0`, `_kRust`, etc.) — fácil de dejar
alguno sin tocar si no se hace como paso explícito al final.

Definir constantes de color/radio privadas al tope del archivo
(`_kInk`, `_kInkSoft`, `_kPaper`, `_kCard`, `_kLine`, `_kRust`, `_kRustDark`,
`_kRustTint`, `_kBlueprint`, `_kBlueprintTint`, `_kVerified`,
`_kVerifiedTint`, `_kRadiusSm`, `_kRadiusMd`), reemplazando
`_kWarmAccent`/`_kHeroDeep` de hoy. Seguir importando `Spacing`/`Motion` de
`tokens.dart` (escala genérica, no colores); dejar de usar `Radii`/`Elevation`
en favor de los radios nuevos y bordes finos (`Border.all(color: _kLine)`)
en vez de elevación con sombra.

**Decisión de carga de imágenes:** introducir `CachedNetworkImage` (ya es
dependencia declarada, hoy sin uso real en ningún lado) específicamente en
esta pantalla — hay bastantes fotos repetidas/grandes como para justificar
el caché. Documentarlo con un comentario corto explicando que es una
excepción deliberada a la convención de `Image.network` cruda del resto de
la app. El placeholder/error debe verse igual que en `servicio_card.dart`
(caja gris + ícono), no algo distinto.

## Orden de implementación sugerido

1. Fuentes: descargar, registrar en `pubspec.yaml`, `flutter pub get`,
   probar en una pantalla existente.
2. Tokens locales + `_TicketDecoration`/`_TicketCard` + `_Eyebrow` +
   `_BrandMark` (todo lo demás depende de esto).
3. Header + hero (incluye resolver el diseño de la tarjeta flotante con
   datos reales).
4. Cómo funciona.
5. Categorías bento (verificar el mapeo de fotos contra los nombres/slugs
   REALES de `/categorias` en producción antes de darlo por terminado, no
   solo contra `mock_data.dart`).
6. Sección de solicitudes en vivo (con datos reales).
7. Dual CTA.
8. Confianza (reskin, bajo riesgo).
9. CTA final + textura.
10. Footer.
11. Pasada final: barrido de radios/colores de botones en todo el archivo.

## Verificación

- `flutter analyze` limpio después de cada sección grande, no solo al final.
- Build local + captura de pantalla en 320 / 390 / 768 / 1024 / 1440px para:
  header, hero, bento de categorías (tiene sus propios breakpoints internos
  a 520/900px), fila de solicitudes, dual CTA (breakpoint a 820px), CTA
  final, footer.
- Estados logueado/no logueado del header (funcionalidad sin cambios, pero
  hay que reverificar visualmente con la paleta nueva).
- 0 errores de consola — chequear en particular que las URLs de Unsplash
  carguen de verdad en el momento de implementar (re-confirmar, no asumir
  que siguen sirviendo lo mismo que cuando se verificaron para el mockup).
- Click-through real (no solo inspección visual) de todas las rutas:
  `/login`, `/register` (+ `?rol=cliente`/`?rol=proveedor`), `/buscar`,
  `/cliente/buscar`, `/categorias`, `/cliente/categorias`, `/terminos`,
  `/privacidad`, `/contacto`.
- **Chequeo de fuentes post-deploy en producción real** (misma lección
  aprendida hoy con el bug de caché de Cloudflare en `MaterialIcons-Regular.otf`):
  después de desplegar, cargar la URL de producción en un contexto de
  navegador nuevo y confirmar visualmente que Big Shoulders Display /
  Archivo / IBM Plex Mono se ven de verdad (no cayendo silenciosamente a
  Inter) — un build local exitoso no es evidencia suficiente.
- Confirmar el mapeo de categorías del bento contra la taxonomía REAL de
  producción (no solo `mock_data.dart`) — es el punto con más riesgo de
  romperse en silencio si el backend tiene nombres/slugs distintos a los
  asumidos.

### Archivos críticos
- `lib/features/public/presentation/pages/landing_screen.dart`
- `pubspec.yaml`
- `design-concepts/landing-ideal.html` (referencia de diseño)
- `lib/features/servicios/data/models/categoria_model.dart`
- `lib/shared/widgets/servicio_card.dart` (convención de imágenes a seguir)
- `lib/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart`
- `lib/shared/theme/tokens.dart` (`Spacing`, `Motion` — sí se reusan; `Radii`/`Elevation` no)
