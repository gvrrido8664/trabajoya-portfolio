import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

/// Botón segmentado Cliente/Proveedor. Compartido entre login y registro
/// (antes vivía como `_RoleToggleButton` privado dentro de register_screen.dart).
class RoleToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeLightColor;
  final VoidCallback onTap;

  const RoleToggleButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeLightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: isActive ? activeLightColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
            side: isActive ? BorderSide(color: activeColor) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // scaleDown mantiene el texto en una línea y solo lo encoge cuando no
        // cabe (p. ej. "🧰 Proveedor" a 320px), evitando que se corte.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: isActive
                  ? activeColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
