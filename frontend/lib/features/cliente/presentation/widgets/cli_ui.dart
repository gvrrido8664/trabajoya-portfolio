import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';
import 'package:trabajoya_app/utils/colors.dart';

/// Sistema de diseño "claro premium" para el flujo del cliente.
/// Espeja la estructura de pro_ui.dart pero en colores claros (superficies
/// blancas, bordes sutiles, sombras suaves, acento AppTheme.primary).
class CliColors {
  CliColors._();

  // Constantes de marca / semánticas: idénticas en claro y oscuro.
  static const Color accent = AppColors.rust;
  static const Color secondary = AppTheme.secondary;
  static const Color success = AppTheme.success;

  // Dependientes del brillo: resuelven contra el ColorScheme del tema para que
  // el portal cliente funcione en modo oscuro. En claro devuelven exactamente
  // los mismos valores que antes (surface=blanco, border=#CBD5E1,
  // textPrimary=#0F172A, textSecondary=#64748B): sin regresión visual.
  static Color surface(BuildContext c) => Theme.of(c).colorScheme.surface;
  static Color border(BuildContext c) => Theme.of(c).colorScheme.outline;
  static Color textPrimary(BuildContext c) => Theme.of(c).colorScheme.onSurface;
  static Color textSecondary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurfaceVariant;
}

/// Tarjeta base clara con el motivo compartido de orden de trabajo.
class CliCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const CliCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tarjeta seleccionable',
      button: onTap != null,
      child: TicketCard(
        onTap: onTap,
        padding: padding,
        color: Theme.of(context).cardColor,
        child: child,
      ),
    );
  }
}

/// Encabezado de sección: barrita de acento 3 px + título w700 + acción opcional.
class CliSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CliSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: CliColors.accent,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: CliColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 44),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tarjeta icono+label para accesos rápidos. Fondo blanco, borde sutil.
class CliQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const CliQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? CliColors.accent;
    return Material(
      color: CliColors.surface(context),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: CliColors.border(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(icon, size: 20, color: c),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.15,
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

/// Chip de categoría con icono + label, seleccionable.
class CliCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const CliCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.color,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? CliColors.accent;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? c.withValues(alpha: 0.10)
                  : CliColors.surface(context),
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: selected ? c : CliColors.border(context),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? c
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? c
                        : Theme.of(context).textTheme.bodyLarge?.color,
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

/// Badge/pastilla reutilizable para conteos y estados.
class CliStatPill extends StatelessWidget {
  final String label;
  final Color? color;

  const CliStatPill({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? CliColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: c,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
