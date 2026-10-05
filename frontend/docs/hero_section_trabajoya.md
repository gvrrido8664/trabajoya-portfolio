# Hero Section — TrabajoYa (Flutter)

Resultado de ejecutar `prompt_hero_trabajoya.md`. Es un widget **autocontenido**
(`HeroSection`) pensado para encabezar `lib/features/public/screens/landing_screen.dart`.

- **Responsivo:** dos columnas en ancho ≥ 900 px; en móvil colapsa a una sola columna
  (texto/CTAs arriba, mockup abajo).
- **Variables de diseño centralizadas** al inicio (`_HeroTokens`): colores de la marca
  (`#1565C0` / `#FF8F00` / `#F5F5F5` …) y escala de spacing 4/8/12/16/24/32.
- **CTAs cableados a GoRouter:** primario → `/register?rol=cliente`, secundario →
  `/register?rol=proveedor`.
- **Animación implícita** (sin paquetes externos): la tarjeta de proveedor entra con
  fade + slide vía `TweenAnimationBuilder`.

> Único import opcional: `google_fonts` (para Inter). Si no lo tenés, mirá la nota de
> fallback al final.

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Variables de diseño centralizadas (colores + spacing).
/// Espejan `AppColors` de la app; si preferís, reemplazá estas constantes por
/// `AppColors.primary`, `AppColors.secondary`, etc. e importá `utils/colors.dart`.
class _HeroTokens {
  // Paleta de marca
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFFFF8F00);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);

  // Escala de spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  // Radios
  static const double radius = 16;

  // Breakpoint de layout
  static const double wideBreakpoint = 900;
}

/// Hero section de TrabajoYa.
/// Dos columnas en pantallas anchas, una sola columna apilada en móvil.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _HeroTokens.background,
      padding: const EdgeInsets.symmetric(
        horizontal: _HeroTokens.xl,
        vertical: _HeroTokens.xxl,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _HeroTokens.wideBreakpoint;

          final textColumn = _HeroText(isWide: isWide);
          final mockup = const _ProviderMockup();

          if (isWide) {
            // Dos columnas: texto a la izquierda, mockup a la derecha.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: textColumn),
                const SizedBox(width: _HeroTokens.xxl),
                Expanded(flex: 5, child: mockup),
              ],
            );
          }

          // Móvil: una sola columna (texto/CTAs arriba, mockup abajo).
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textColumn,
              const SizedBox(height: _HeroTokens.xxl),
              mockup,
            ],
          );
        },
      ),
    );
  }
}

/// Columna izquierda: headline, body copy y los dos CTAs.
class _HeroText extends StatelessWidget {
  const _HeroText({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Encuentra al profesional\nideal, cerca de ti',
          textAlign: isWide ? TextAlign.start : TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isWide ? 46 : 32,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: _HeroTokens.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: _HeroTokens.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Gasfíteres, electricistas, pintores y más, verificados y a un toque. '
            'Coordina por chat, paga seguro y recibe tu boleta.',
            textAlign: isWide ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isWide ? 18 : 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: _HeroTokens.textLight,
            ),
          ),
        ),
        const SizedBox(height: _HeroTokens.xl),
        // CTAs: se apilan o se alinean según el ancho.
        Wrap(
          spacing: _HeroTokens.md,
          runSpacing: _HeroTokens.md,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () => context.go('/register?rol=cliente'),
              style: FilledButton.styleFrom(
                backgroundColor: _HeroTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: _HeroTokens.xl,
                  vertical: _HeroTokens.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_HeroTokens.md),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Buscar un profesional'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/register?rol=proveedor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _HeroTokens.primary,
                side: const BorderSide(color: _HeroTokens.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: _HeroTokens.xl,
                  vertical: _HeroTokens.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_HeroTokens.md),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Ofrecer mis servicios'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Columna derecha: tarjeta de proveedor mock con entrada animada (fade + slide).
class _ProviderMockup extends StatelessWidget {
  const _ProviderMockup();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          // Slide suave de 24px hacia arriba a medida que aparece.
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(_HeroTokens.xl),
            decoration: BoxDecoration(
              color: _HeroTokens.surface,
              borderRadius: BorderRadius.circular(_HeroTokens.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: _HeroTokens.primary,
                      child: Text(
                        'CP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: _HeroTokens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Carlos Pérez',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _HeroTokens.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: _HeroTokens.sm),
                              // Badge "Verificado".
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _HeroTokens.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _HeroTokens.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(_HeroTokens.sm),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: _HeroTokens.primary,
                                    ),
                                    const SizedBox(width: _HeroTokens.xs),
                                    Text(
                                      'Verificado',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _HeroTokens.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gasfitería · a 1.2 km',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _HeroTokens.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _HeroTokens.lg),
                // Rating en estrellas.
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < 5 ? Icons.star : Icons.star_border,
                        size: 18,
                        color: _HeroTokens.secondary,
                      ),
                    ),
                    const SizedBox(width: _HeroTokens.sm),
                    Text(
                      '4.9 · 80 trabajos',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _HeroTokens.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: _HeroTokens.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go('/register?rol=cliente'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _HeroTokens.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: _HeroTokens.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_HeroTokens.md),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Contratar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Notas de integración

1. **Dónde insertarlo:** dentro del `CustomScrollView` / `Column` de
   `lib/features/public/screens/landing_screen.dart`, como primer bloque debajo del
   `SliverAppBar` (envuelto en `SliverToBoxAdapter` si va en un `CustomScrollView`).
2. **Reutilizar el sistema de diseño:** si querés evitar la duplicación de colores,
   borrá la clase `_HeroTokens` y reemplazá las referencias por `AppColors.*`
   (`import '../../../utils/colors.dart';`). Dejé los tokens locales solo para que el
   widget sea copiable y compile aislado.
3. **Fuente Inter:** usa `google_fonts` (ya está en el proyecto según la auditoría). Si lo
   quitaras, cambiá `GoogleFonts.inter(...)` por `const TextStyle(fontFamily: 'Inter', ...)`
   y declará la fuente en `pubspec.yaml`.
4. **`withValues(alpha:)`** requiere Flutter reciente; en versiones viejas usá
   `.withOpacity(...)`.
