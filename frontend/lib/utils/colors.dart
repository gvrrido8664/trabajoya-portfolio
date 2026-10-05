import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // 1. Core Colors (Work-order visual language)
  // ------------------------------------------------------------
  static const Color primary = Color(0xFFC1502E);
  static const Color primaryDark = Color(0xFF9E3D22);
  static const Color primaryLight = Color(0xFFF3E3DC);

  static const Color secondary = Color(0xFF8A6508);

  // ------------------------------------------------------------
  // 2. Semantic Colors
  // ------------------------------------------------------------
  static const Color success = Color(0xFF3F6B4F);
  static const Color successLight = Color(0xFFDEE9E1);

  static const Color danger = Color(0xFFA32015);
  static const Color dangerLight = Color(0xFFF6E3E0);

  static const Color warning = Color(0xFF8A6508);
  static const Color warningLight = Color(0xFFF5EBD6);

  // ------------------------------------------------------------
  // 3. Neutral Colors
  // ------------------------------------------------------------
  static const Color background = Color(0xFFF2F4F3);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textDark = Color(0xFF12233D);
  // Contraste 8.13:1 sobre `background`, por encima del mínimo WCAG AA de
  // 4.5:1 para texto normal (A11Y-02). Se usa como onSurfaceVariant en toda
  // la app (hints, labels secundarios e iconos de campo).
  static const Color textLight = Color(0xFF3A4A63);

  static const Color border = Color(0xFFD7DCD8);

  static const Color ink = textDark;
  static const Color inkSoft = textLight;
  static const Color paper = background;
  static const Color card = surface;
  static const Color line = border;
  static const Color rust = primary;
  static const Color rustDark = primaryDark;
  static const Color rustTint = primaryLight;
  static const Color blueprint = Color(0xFF2B4C7E);
  static const Color blueprintTint = Color(0xFFDDE6F1);
  static const Color verified = success;
  static const Color verifiedTint = successLight;
  static const Color amber = secondary;
  static const Color amberTint = warningLight;
  static const Color sidebarTop = ink;
  static const Color sidebarBottom = Color(0xFF0B1626);
  static const Color borderStrong = Color(0xFF8E978F);
}
