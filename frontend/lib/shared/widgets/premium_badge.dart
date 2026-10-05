import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';

/// Sello visual de proveedor Premium.
///
/// Marca única para todo el marketplace: medalla ámbar (`AppTheme.secondary`),
/// deliberadamente distinta de la estrella de rating (`RatingBadge`) y del check
/// de identidad verificada (`Icons.verified`), para que "Premium" no se confunda
/// con "mejor calificado" ni con "verificado". No usar colores literales aquí.
class PremiumBadge extends StatelessWidget {
  final double size;

  const PremiumBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Proveedor Premium',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium,
          color: AppTheme.secondary,
          size: size,
        ),
      ),
    );
  }
}
