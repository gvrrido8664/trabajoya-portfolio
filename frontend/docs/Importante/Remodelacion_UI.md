# TrabajoYa — Migración Neón → Trust-Blue: Pantallas Restantes

> **Para otra IA ejecutora:** Este documento es completamente autocontenido.
> Sigue cada sección en orden. No necesitas contexto adicional — el patrón,
> los tokens exactos y los casos especiales están descritos aquí.
> Al terminar corre `flutter analyze lib/` y debe devolver "No issues found."

---

## 1. Contexto del proyecto

**App:** TrabajoYa — marketplace P2P de servicios del hogar (Flutter, Material 3).
**Stack:** Flutter + `go_router ^17.3` + `provider` + `google_fonts ^8.1`.
**Ruta del proyecto:** `c:\Users\Nacho\Desktop\Proyectos\TrabajoYa\trabajoya-app\`

### Tokens disponibles (ya existen en el repo, NO los crees de nuevo)

**`lib/utils/colors.dart` — `AppColors`**
```dart
static const Color primary   = Color(0xFF1A73E8); // azul confianza
static const Color primaryDark = Color(0xFF041E49);
static const Color secondary = Color(0xFFE8A317); // ámbar
static const Color success   = Color(0xFF0F9D58); // verde confirmación
static const Color cta       = Color(0xFF0F9D58); // botón transacción
static const Color ctaDark   = Color(0xFF35C77F);
static const Color danger    = Color(0xFFD9304E);
static const Color background = Color(0xFFF0F4F8);
static const Color surface   = Color(0xFFF8FAFB);
static const Color textDark  = Color(0xFF041E2A);
static const Color textLight = Color(0xFF6B7280);  // también textSecondary
static const Color border    = Color(0xFFDADCE0);
```

**`lib/app/theme.dart` — `AppTheme`**
Expone los mismos colores como constantes estáticas (`AppTheme.primary`, etc.).
El `ThemeData` ya configura:
- `ElevatedButton` con `backgroundColor: primary`, `foregroundColor: white`, altura 52px
- `Card` con `color: surface`, `elevation: 0`, `shape: RoundedRectangleBorder(radius: 14)`
- `InputDecoration` con borde gris, `focusedBorder` en `primary`
- `AppBar` con `backgroundColor: Colors.white`, `foregroundColor: textDark`
- **No sobreescribas el tema — úsalo tal cual.**

**`lib/shared/theme/tokens.dart` — `Spacing`, `Radii`, `Elevation`, `Motion`**
```dart
Spacing.xs=4, sm=8, md=12, lg=16, xl=24, xl2=32, xl3=48
Radii.sm=8, md=12, lg=14, xl=20, pill=999
Elevation.e0=[], e1=[BoxShadow(0x0F000000, blur:3, offset:(0,1))], e2=[...], e3=[...]
Motion.fast=150ms, base=200ms, slow=300ms, curve=easeInOut
```

---

## 2. Patrón de migración universal

Cada pantalla con código neón sigue la **misma secuencia de 8 pasos**:

### Paso 1 — Eliminar imports neón
```dart
// BORRAR estas líneas:
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
```

### Paso 2 — Eliminar consts neón locales
```dart
// BORRAR todo bloque como:
const Color sciFiBg    = Color(0xFF070B14);
const Color sciFiCyan  = Color(0xFF00F0FF);
const Color sciFiGreen = Color(0xFF00FF66);
const Color sciFiMagenta = Color(0xFFFF003C);
const Color sciFiGlass = Color(0x99111827);
// (también con prefijos _ o sin prefijo, p.ej. _sciFiBg, _cyan, _bg, etc.)
```

### Paso 3 — Eliminar widgets estructurales neón
Borrar por completo las clases `_GlowOrb`, `_GlassPanel` (y sus usos).

### Paso 4 — Scaffold background
```dart
// ANTES:
Scaffold(backgroundColor: sciFiBg, ...)
// DESPUÉS (déjalo sin especificar — el tema lo pone automáticamente):
Scaffold(...)
// O si la pantalla tiene fondo blanco/card: no poner backgroundColor
```

### Paso 5 — AppBar
```dart
// ANTES: AppBar con backgroundColor: Colors.transparent, foregroundColor: white, título con GoogleFonts.inter(color: white, letterSpacing: X)
// DESPUÉS: AppBar limpio, el tema ya maneja todo
AppBar(
  title: const Text('Título en español normal'),  // sin MAYUSCULAS forzadas
  centerTitle: true,                               // opcional
)
```

### Paso 6 — Textos
```dart
// ANTES:
Text('TEXTO', style: GoogleFonts.inter(color: sciFiCyan, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.w700))
// DESPUÉS (usa el tema):
Text('Texto', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary))
// o simplemente:
Text('Texto')  // si el color del tema es correcto
```

Mapeo rápido de roles:
- Subtítulo / eyebrow → `theme.textTheme.labelMedium?.copyWith(color: AppColors.textLight)`
- Título de sección → `theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)`
- Body → `theme.textTheme.bodyMedium`
- Precio / monto → `theme.textTheme.titleMedium?.copyWith(color: AppColors.cta, fontWeight: FontWeight.w700)`

### Paso 7 — Inputs / formularios
```dart
// ANTES: _inputDecoration() custom con fillColor: negro, borders blancos, errorStyle: GoogleFonts.inter(color: sciFiMagenta)
// DESPUÉS: usa directamente InputDecoration estándar (el tema ya la estiliza):
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Categoría requerida',
    prefixIcon: Icon(Icons.category_outlined),
  ),
  // quitar style: GoogleFonts.inter(color: Colors.white)
)
// SnackBar de error: backgroundColor: AppColors.danger  (no sciFiMagenta)
```

### Paso 8 — Botones
```dart
// ANTES: FilledButton/ElevatedButton con backgroundColor: _sciFiCyan.withValues(alpha:0.1), side: BorderSide(color: _sciFiCyan)
// DESPUÉS:
// Acción principal → ElevatedButton (tema primary azul)
SizedBox(height: 52, child: ElevatedButton(onPressed: fn, child: Text('Publicar solicitud')))

// Acción de pago / transacción → FilledButton con color CTA verde:
FilledButton.icon(
  onPressed: fn,
  icon: const Icon(Icons.payments_outlined),
  label: const Text('Pagar con MercadoPago'),
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.cta,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
  ),
)

// Acción secundaria → OutlinedButton o TextButton del tema
// Acción destructiva / cancelar → OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger))
```

---

## 3. Archivo a archivo — instrucciones exactas

### 3.0 — `lib/core/utils/csv_export.dart` (1 línea)
Una sola referencia a `Color(0xFF00FF66)` (sciFiGreen) usada como `backgroundColor` de un `SnackBar`.
**Fix:** reemplaza `Color(0xFF00FF66)` → `AppColors.success`.
Agrega el import `import 'package:trabajoya_app/utils/colors.dart';` si no existe.

---

### 3.1 — `lib/features/splash/splash_screen.dart`
**Estado actual:** fondo negro `sciFiBg`, logo "TY" con `Shadow` neón, spinner cian, texto "VERIFICANDO CREDENCIALES..." en caps con `GoogleFonts.inter`.

**Estructura a mantener:** la lógica de `_checkAuth()` en `initState` es intocable (contiene redirección por rol + deep link handling en web). Solo cambia el `build`.

**Resultado esperado:**
```dart
// Importa: solo flutter/material.dart, go_router, provider, auth_provider
// Quita: google_fonts, const Color sciFi*, _GlowOrb

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Scaffold(
    backgroundColor: AppColors.primaryDark,   // #041E49 — fondo oscuro de marca (no neón)
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TY',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TrabajoYa',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
          const SizedBox(height: 24),
          Text(
            'Verificando sesión...',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
          ),
        ],
      ),
    ),
  );
}
```
**Importes necesarios:** `package:trabajoya_app/utils/colors.dart`.

---

### 3.2 — `lib/features/cliente/presentation/pages/crear_solicitud_screen.dart`
**Estado actual:** fondo negro, `_GlowOrb` + `_GlassPanel` (con `BackdropFilter`), inputs con `_inputDecoration()` custom (fondo negro, bordes blancos), botón "PUBLICAR SOLICITUD" con borde cian.

**Lógica intacta:** `_getLocation()`, `_reverseGeocode()`, `_submit()`, `_categoriaId`, `_formKey`, todos los controllers. El `DropdownButtonFormField` de categorías consulta `ServiciosProvider`. No toques nada de esto.

**Resultado esperado:**
```dart
// Importes: quita dart:ui, google_fonts. Agrega trabajoya_app/utils/colors.dart, shared/theme/tokens.dart
// Quita: sciFi consts, _GlassPanel, _GlowOrb, _inputDecoration()

@override
Widget build(BuildContext context) {
  final categorias = context.watch<ServiciosProvider>().categorias;
  return Scaffold(
    appBar: AppBar(title: const Text('Nueva solicitud')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de datos requeridos
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(children: [
                    DropdownButtonFormField<String>(
                      value: _categoriaId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría requerida',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categorias.map((c) => DropdownMenuItem(
                        value: c.id, child: Text(c.nombre),
                      )).toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título de la solicitud',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción detallada',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              // Card de datos opcionales
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(children: [
                    TextFormField(
                      controller: _presupuestoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Presupuesto referencial (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextFormField(
                      controller: _ubicacionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ubicación o comuna',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        suffixIcon: _loadingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.my_location),
                                tooltip: 'Usar mi ubicación',
                                onPressed: _getLocation,
                              ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: Spacing.xl2),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Publicar solicitud'),
                ),
              ),
              const SizedBox(height: Spacing.xl2),
            ],
          ),
        ),
      ),
    ),
  );
}
```
**SnackBars:** reemplaza `backgroundColor: sciFiMagenta` → `backgroundColor: AppColors.danger`.
**Elimina:** `_inputDecoration()`, `_GlassPanel`, `_GlowOrb`, `Stack` con Positioned.

---

### 3.3 — `lib/features/chat/presentation/pages/chat_screen.dart`
**Estado actual:** wrapper minimalista — fondo negro, `_GlowOrb` decorativo, `SafeArea` → `ChatPanel`. La lógica real está en `ChatPanel`.

**Resultado esperado:**
```dart
// Quita: dart:ui (no lo usa realmente), sciFi consts, _GlowOrb, Stack, Positioned
// El Scaffold sin backgroundColor queda con el fondo del tema

class ChatScreen extends StatelessWidget {
  final String contratacionId;
  const ChatScreen({super.key, required this.contratacionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ChatPanel(
          contratacionId: contratacionId,
          onBack: () => context.pop(),
        ),
      ),
    );
  }
}
// Borra _GlowOrb completamente
```

---

### 3.4 — `lib/features/chat/presentation/pages/chat_panel.dart`
**Estado actual:** el panel de chat más complejo. Tiene:
- Header (barra superior) con fondo `sciFiBg`, ícono "atrás" cian
- Lista de mensajes con fondo `sciFiBg`, spinner cian, empty state con ícono cian
- Input bar con `BackdropFilter` + `sciFiGlass`, botón enviar con borde cian
- `_Bubble` con colores `sciFiCyan`/`sciFiGlass` dependiendo de `isMine`

**Lógica intacta:** todo `initState`, `didUpdateWidget`, `dispose`, `_otro()`, `_sendMessage()`, polling, WebSocket. NO TOCAR.

**Transformación de componentes:**

**Header:**
```dart
Container(
  height: 64,
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border(bottom: BorderSide(color: AppColors.border)),
  ),
  child: Row(children: [
    if (widget.onBack != null)
      IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: widget.onBack,
      ),
    CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
      child: avatar == null
          ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
          : null,
    ),
    const SizedBox(width: 12),
    Expanded(child: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
  ]),
)
```

**Cuerpo / lista de mensajes:**
```dart
Expanded(
  child: ColoredBox(
    color: AppColors.background,
    child: chat.loading && chat.mensajes.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : chat.mensajes.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.forum_outlined, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            Text('Sin mensajes aún', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textLight)),
            Text('Redacta el primero para iniciar la conversación.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textLight)),
          ]))
        : ListView.builder(
            controller: _scrollCtrl,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: chat.mensajes.length,
            itemBuilder: (context, index) {
              final msg = chat.mensajes[index];
              return _Bubble(msg: msg, isMine: msg.emisorId == miId);
            },
          ),
  ),
)
```

**Input bar:**
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border(top: BorderSide(color: AppColors.border)),
  ),
  child: SafeArea(top: false, child: Row(children: [
    Expanded(
      child: TextField(
        controller: _msgCtrl,
        decoration: InputDecoration(
          hintText: 'Escribe un mensaje...',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: 4, minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
      ),
    ),
    const SizedBox(width: 8),
    SizedBox(
      width: 48, height: 48,
      child: ElevatedButton(
        onPressed: _sending ? null : _sendMessage,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        child: _sending
            ? const SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 18),
      ),
    ),
  ])),
)
// Quita BackdropFilter — TextField usa el InputDecoration del tema
```

**`_Bubble` (clase privada):**
```dart
class _Bubble extends StatelessWidget {
  final Mensaje msg;
  final bool isMine;
  const _Bubble({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surface,
          border: Border.all(
            color: isMine ? AppColors.primary.withValues(alpha: 0.25) : AppColors.border,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.contenido,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
```
**SnackBar de error:** `backgroundColor: AppColors.danger`.
**Importes:** quita `dart:ui`, `google_fonts`. Conserva `dart:async`, `intl`, `provider`, `api_client`, `auth_provider`, `mensaje_model`, `chat_provider`.

---

### 3.5 — `lib/features/pagos/presentation/pages/pago_screen.dart`
**Estado actual:** el más complejo (61 refs). Máquina de estados: `_PagoState.{inicial, esperando, aprobado, rechazado, timeout, error}`. Cada estado tiene su propio `_buildXxx()` con `_GlassPanel` y colores neón.

**Lógica intacta:** toda la lógica de pagos (`_iniciarPago`, `_iniciarPolling`, `_consultarEstado`, `_reintentar`, `Timer`, `PagosProvider`). NO TOCAR.

**Estrategia:** reemplaza cada `_buildXxx()` usando `Card` en lugar de `_GlassPanel`, y tokens de `AppColors` en lugar de `_sciFiCyan/Green/Magenta`. El layout interior (Column, Row, Icon, Text) se mantiene igual.

**Mapeo de colores por estado:**
| Estado | Neón original | Trust-blue |
|--------|--------------|------------|
| inicial — icono/acción | `_sciFiCyan` | `AppColors.primary` |
| esperando — spinner/progreso | `_sciFiCyan` | `AppColors.primary` |
| aprobado — icono/texto/botón | `_sciFiGreen` | `AppColors.success` |
| rechazado — icono/texto | `_sciFiMagenta` | `AppColors.danger` |
| rechazado — botón reintentar | `_sciFiCyan` | `AppColors.primary` |
| timeout — icono | `_sciFiCyan` | `AppColors.primary` |
| error — icono/texto | `_sciFiMagenta` | `AppColors.danger` |
| error — botón reintentar | `_sciFiCyan` | `AppColors.primary` |

**AppBar:**
```dart
appBar: AppBar(title: const Text('Pago del servicio')),
// Quita: backgroundColor, foregroundColor, surfaceTintColor, GoogleFonts.inter
```

**`_GlassPanel` → `Card`:**
```dart
// Reemplaza cada: _GlassPanel(glowColor: x, child: Padding(...))
// Por:            Card(margin: EdgeInsets.zero, child: Padding(...))
// Quita glowColor — no tiene equivalente (es neón)
```

**Botón principal de pago (`_buildInicial`):**
```dart
FilledButton.icon(
  onPressed: _creandoPago ? null : _iniciarPago,
  icon: _creandoPago
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : const Icon(Icons.open_in_new, size: 20),
  label: Text(_creandoPago ? 'Conectando...' : 'Pagar con MercadoPago'),
  style: FilledButton.styleFrom(
    backgroundColor: AppColors.cta,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
  ),
)
```

**`_sandboxRow` y `_montoRow`:** quita `GoogleFonts.inter()`, usa `theme.textTheme.bodySmall` / `.bodyMedium`.

**Icono badge (círculo con icono) en cada estado:**
```dart
// ANTES: Container con border sciFiCyan + boxShadow neón
// DESPUÉS:
Container(
  width: 72, height: 72,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: AppColors.primary.withValues(alpha: 0.10),   // o .success / .danger según estado
  ),
  child: Icon(Icons.payments_outlined, color: AppColors.primary, size: 32),
)
// Sin border, sin boxShadow
```

**`LinearProgressIndicator` (estado esperando):**
```dart
LinearProgressIndicator(
  value: progreso,
  borderRadius: BorderRadius.circular(4),
  // quita backgroundColor y color explícitos — usa los del tema
)
```

**Elimina:** `dart:ui`, `google_fonts`, consts `_sciFi*`, `_GlassPanel`, `_GlowOrb`, `Stack` con `Positioned` orbes.

---

### 3.6 — `lib/features/pagos/presentation/pages/pago_resultado_screen.dart`
**Estado actual:** pantalla de resultado post-pago (13 refs neón). Similar a los estados de `pago_screen`.

Aplica el mismo patrón que 3.5:
- Quita `dart:ui`, `google_fonts`, consts `_sciFi*`, `_GlassPanel`, `_GlowOrb`
- `Scaffold` sin `backgroundColor`
- `AppBar` limpio
- `_GlassPanel` → `Card`
- Colores: `_sciFiGreen` → `AppColors.success`, `_sciFiMagenta` → `AppColors.danger`, `_sciFiCyan` → `AppColors.primary`
- Textos sin `GoogleFonts.inter()` — usa el tema
- Botones: `FilledButton.styleFrom(backgroundColor: AppColors.cta)` para acciones de confirmación

---

### 3.7 — `lib/features/contrataciones/presentation/pages/contratacion_detail_screen.dart`
**Estado actual:** detalle de contratación (22 refs). Fondo negro, `_GlassPanel` para secciones de info, estados de contratación con colores neón.

Aplica patrón universal:
- `Scaffold` sin `backgroundColor`
- `AppBar` limpio (quita fondo transparente + texto blanco)
- `_GlassPanel` → `Card`
- Estados de contratación (activa/completada/cancelada): usa `AppColors.success` / `AppColors.primary` / `AppColors.danger`
- Chips de estado: `Chip(label: Text(...), backgroundColor: AppColors.success.withValues(alpha: 0.12), labelStyle: TextStyle(color: AppColors.success))`
- Etiquetas de monto: `AppColors.cta`
- Botones de acción (Pagar, Completar, Cancelar): ElevatedButton del tema / danger outline
- Quita `dart:ui`, `google_fonts`, consts `_sciFi*`, `_GlassPanel`, `_GlowOrb`

---

### 3.8 — `lib/features/suscripciones/presentation/pages/planes_screen.dart`
**Estado actual:** 35 refs, el más visual de los pendientes. Cards de planes con glassmorphism y glow de colores diferentes por plan.

**Estrategia especial para cards de planes:**
Cada plan (básico/pro/premium) tenía un glow de color diferente. En trust-blue:
- Plan básico / gratuito → card normal sin acento
- Plan profesional (el más popular) → card con `border: Border.all(color: AppColors.primary, width: 2)` + chip "Recomendado" en `AppColors.primary`
- Plan premium → card con `border: Border.all(color: AppColors.secondary, width: 2)` + chip "Premium" en `AppColors.secondary`

```dart
// Card de plan con acento:
Card(
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.lg),
    side: BorderSide(color: AppColors.primary, width: 2),  // solo en plan destacado
  ),
  child: Padding(
    padding: const EdgeInsets.all(Spacing.xl),
    child: Column(children: [
      // nombre del plan, precio, lista de features, botón
    ]),
  ),
)
```

Patrón universal aplica para todo lo demás: quita `dart:ui`, `google_fonts`, `_sciFi*`, `_GlassPanel`, `_GlowOrb`.

---

### 3.9 — Pantallas admin internas (6 archivos)

Todas las pantallas admin internas siguen el mismo patrón neón con consts locales `_bg`, `_cyan`, `_green`, `_magenta`, `_glass`. El admin_shell ya fue migrado a trust-blue, así que el contenido de estas pantallas debe coincidir con el look del shell.

**Regla para las 6 pantallas admin:**
```
lib/features/admin/presentation/pages/admin_full_dashboard_screen.dart
lib/features/admin/presentation/pages/admin_usuarios_screen.dart
lib/features/admin/presentation/pages/admin_pagos_screen.dart
lib/features/admin/presentation/pages/admin_servicios_screen.dart
lib/features/admin/presentation/pages/admin_disputas_screen.dart
lib/features/admin/presentation/pages/admin_suscripciones_screen.dart
```

**Mapeo de consts locales → `AppColors`:**
```dart
// ANTES → DESPUÉS
_bg / sciFiBg    → (eliminar, Scaffold usa tema)
_cyan / sciFiCyan  → AppColors.primary
_green / sciFiGreen → AppColors.success
_magenta / sciFiMagenta → AppColors.danger
_glass / sciFiGlass → AppColors.surface
_premium → AppColors.secondary  (solo en admin_suscripciones)
```

**Para cada pantalla:**
1. Elimina imports `dart:ui`, `google_fonts`
2. Elimina todos los consts `_bg`, `_cyan`, `_green`, `_magenta`, `_glass`, `_premium`
3. Elimina `_GlowOrb`, `_GlassPanel`
4. `Scaffold(backgroundColor: _bg)` → `Scaffold()` sin backgroundColor
5. Agrega import `package:trabajoya_app/utils/colors.dart`
6. Reemplaza cada color local con su equivalente en `AppColors`
7. `GoogleFonts.inter(...)` → `Theme.of(context).textTheme.*` o `const TextStyle(...)`
8. Las tablas de datos admin (`DataTable`, `Table`, listas) solo cambian colores de encabezado y selección:
   - encabezado seleccionado → `AppColors.primary.withValues(alpha: 0.08)`
   - fila seleccionada → `AppColors.primary.withValues(alpha: 0.05)`
   - estado "activo/online" → `AppColors.success`
   - estado "inactivo/suspendido" → `AppColors.danger`
   - estado "pendiente" → `AppColors.secondary`

**admin_suscripciones_screen.dart (caso especial):**
Tiene tab "premium" y colores especiales para suscripciones. Mapeo:
- `_premium` (ámbar/magenta neón) → `AppColors.secondary` (#E8A317 ámbar)
- Chip de suscripción activa → `AppColors.success`
- Chip expirada → `AppColors.danger`

---

## 4. Verificación

Después de migrar **todos** los archivos, ejecuta:

```bash
flutter analyze lib/
```
Debe retornar `No issues found.` (0 errores, 0 warnings).

Si hay errores:
- `Undefined name 'sciFiCyan'` → encontraste una referencia que no se reemplazó. Busca con grep.
- `The method 'GoogleFonts' isn't defined` → quedó un `google_fonts` import o uso.
- `dart:ui not found` → quedó un `import 'dart:ui'` o `BackdropFilter`/`ImageFilter`.

Grep de validación (debe devolver 0 resultados):
```bash
grep -r "sciFi\|_sciFi\|sciFiBg\|sciFiCyan\|GlowOrb\|GlassPanel\|BackdropFilter\|GoogleFonts\." lib/ --include="*.dart" -l
```
Excepción: `lib/app/theme.dart` puede tener `GoogleFonts.inter` — ese es correcto.

---

## 5. Orden de ejecución recomendado

1. `csv_export.dart` — 1 línea, valida el patrón
2. `splash_screen.dart` — más simple, verifica `flutter analyze` limpio
3. `chat_screen.dart` — wrapper, 10 líneas de cambio
4. `chat_panel.dart` — más complejo del grupo chat
5. `crear_solicitud_screen.dart` — form estándar
6. `contratacion_detail_screen.dart` — detalle con estados
7. `pago_resultado_screen.dart` — resultado post-pago
8. `pago_screen.dart` — máquina de estados compleja
9. `planes_screen.dart` — cards visuales con variantes
10. Las 6 pantallas admin (en cualquier orden, siguen el mismo patrón)

**Corre `flutter analyze lib/` después de cada archivo** para detectar errores de inmediato.

---

## 6. Resumen: qué no tocar

- `lib/app/theme.dart` — NO modificar
- `lib/app/router.dart` — NO modificar
- `lib/utils/colors.dart` — NO modificar (ya tiene los tokens que necesitas)
- `lib/shared/theme/tokens.dart` — NO modificar
- `lib/shared/layout/breakpoints.dart` — NO modificar
- `lib/shared/widgets/` — NO modificar
- **Toda la lógica de negocio** (providers, datasources, repositories) — NO tocar
- **Los IDs de rutas** en `context.go(...)` — NO cambiar
