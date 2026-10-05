import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';

/// Paleta transitoria del proveedor, alineada al tema claro global
/// ("orden de trabajo"). El rol proveedor ya NO usa un tema oscuro propio —
/// ver [RolePalette] en pro_ui.dart, que unifica ambos roles en claro.
class ProColors {
  ProColors._();

  // Fondos
  static const Color bg = Color(0xFFF2F4F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHi = Color(0xFFF2F4F3);
  static const Color elevated = Color(0xFFF2F4F3);

  // Bordes (sutiles, clave del look "orden de trabajo")
  static const Color border = Color(0xFFD7DCD8);
  static const Color borderStrong = Color(0xFF8E978F);

  // Jerarquía de texto clara con contraste AA sobre papel y tarjetas.
  static const Color textPrimary = Color(0xFF12233D);
  static const Color textSecondary = Color(0xFF3A4A63);
  static const Color textMuted = Color(0xFF3A4A63);

  // Acentos
  static const Color accent = Color(0xFF2B4C7E);
  static const Color accentDim = Color(0xFFDDE6F1);

  /// Blanco sobre `accent`: 8.61:1.
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color amber = Color(0xFF8A6508);
  static const Color success = Color(0xFF3F6B4F);
  static const Color danger = Color(0xFFA32015);

  /// Blanco sobre `danger`: 7.57:1.
  static const Color onDanger = Color(0xFFFFFFFF);

  /// Color para un estado mapeado al vocabulario canónico del tema.
  static Color status(String s) => AppTheme.statusColor(s);
}
