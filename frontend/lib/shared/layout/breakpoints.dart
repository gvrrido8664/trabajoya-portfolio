import 'package:flutter/widgets.dart';

/// Clase de tamaño de pantalla para layouts adaptativos.
enum ScreenClass { mobile, tablet, desktop }

/// Breakpoints responsive de TrabajoYa (fuente única).
///
/// Uso: `Breakpoints.of(context)` o, dentro de un `LayoutBuilder`,
/// `Breakpoints.fromWidth(constraints.maxWidth)`.
abstract final class Breakpoints {
  /// < 600: teléfonos (navegación inferior, 1 columna).
  static const double mobile = 600;

  /// 600–1024: tablets (rail colapsado, 2–3 columnas).
  static const double tablet = 1024;

  static ScreenClass fromWidth(double width) {
    if (width < mobile) return ScreenClass.mobile;
    if (width < tablet) return ScreenClass.tablet;
    return ScreenClass.desktop;
  }

  static ScreenClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenClass.mobile;

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenClass.desktop;

  /// Columnas de grilla de productos sugeridas por clase de pantalla.
  static int gridColumns(ScreenClass sc) => switch (sc) {
    ScreenClass.mobile => 2,
    ScreenClass.tablet => 3,
    ScreenClass.desktop => 4,
  };
}
