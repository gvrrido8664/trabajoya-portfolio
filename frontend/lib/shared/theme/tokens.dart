import 'package:flutter/material.dart';

/// Tokens de diseño de TrabajoYa.
///
/// Fuente única de espaciado, radios y elevación, derivados del sistema de
/// diseño "marketplace trust-first" (Flat / Soft UI). Mantener la UI plana:
/// como máximo [Elevation.e1] sobre contenido.
abstract final class Spacing {
  /// Base de 4px.
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xl2 = 32;
  static const double xl3 = 48;
}

/// Radios de borde. Coincide con el uso actual (12 botones/inputs, 14 cards).
abstract final class Radii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 8;
  static const double xl = 12;

  /// Pastilla / círculo.
  static const double pill = 999;

  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);
  static const Radius rXl = Radius.circular(xl);
}

/// Sombras planas. Reservar [e0]/[e1] para contenido; [e2]/[e3] sólo para
/// navegación, menús y diálogos.
abstract final class Elevation {
  static const List<BoxShadow> e0 = [];

  /// Cards.
  static const List<BoxShadow> e1 = [];

  /// Navegación / menús.
  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color(0x14000000), // negro 8%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Diálogos.
  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color(0x1F000000), // negro 12%
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Duraciones de animación recomendadas (150–300ms). Respetar
/// [MediaQueryData.disableAnimations] / `prefers-reduced-motion`.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeInOut;
}
