import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

/// Insignia de estado: píldora tintada + punto/icono + etiqueta.
///
/// Render accesible (WCAG AA): el fondo es una versión tenue del color de
/// estado y el texto es una variante del mismo matiz con luminosidad ajustada
/// al modo claro/oscuro, de modo que el contraste supere 4.5:1 en ambos —
/// nunca texto blanco sobre un color de baja luminancia (ámbar/verde).
///
/// El estado nunca se comunica solo por color: siempre lleva etiqueta y, cuando
/// se construye con [StatusBadge.forStatus], también un icono.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  /// Construye el badge desde un estado del backend usando el vocabulario único
  /// de [AppTheme] (color + etiqueta + icono). Fuente de verdad única de estado.
  ///
  /// [label] permite una etiqueta más cercana para el contexto (p.ej.
  /// "Esperando respuesta" en vez de "Pendiente") sin romper la unidad de
  /// color/icono — el color y el icono siempre salen del vocabulario canónico.
  factory StatusBadge.forStatus(
    String status, {
    Key? key,
    String? label,
    EdgeInsets? padding,
  }) {
    return StatusBadge(
      key: key,
      label: label ?? AppTheme.statusLabel(status),
      color: AppTheme.statusColor(status),
      icon: AppTheme.statusIcon(status),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(color);
    // Texto legible: oscurecemos el matiz en claro, lo aclaramos en oscuro.
    final textColor = isDark
        ? hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 0.80)).toColor()
        : hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 0.32)).toColor();
    final bg = color.withValues(alpha: isDark ? 0.22 : 0.14);

    return Semantics(
      label: 'Estado: $label',
      container: true,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 13, color: textColor)
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: AppTheme.badgeLabel.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
