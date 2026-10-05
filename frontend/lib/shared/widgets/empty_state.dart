import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

enum EmptyStateVariant {
  primary,
  error,
  success,
  warning,
}

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateVariant variant;
  final bool compact;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    String? message,
    String? description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.variant = EmptyStateVariant.primary,
    this.compact = false,
  })  : description = description ?? message ?? '',
        assert(icon != null || illustration != null,
            'Debes proveer un icono o una ilustración');

  Color _getVariantColor() {
    switch (variant) {
      case EmptyStateVariant.error:
        return AppColors.danger;
      case EmptyStateVariant.success:
        return AppColors.success;
      case EmptyStateVariant.warning:
        return AppColors.warning;
      case EmptyStateVariant.primary:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getVariantColor();

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? Spacing.lg : Spacing.xl3,
        horizontal: compact ? Spacing.lg : Spacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Ilustración o Icono ──
            if (illustration != null)
              illustration!
            else
              Container(
                padding: EdgeInsets.all(compact ? Spacing.md : Spacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                  
                ),
                child: Container(
                  padding: EdgeInsets.all(compact ? Spacing.sm : Spacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, size: compact ? 32 : 48, color: color),
                ),
              ),
            SizedBox(height: compact ? Spacing.lg : Spacing.xl2),

            // ── Título ──
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.5,
                fontSize: compact ? 16 : null,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? Spacing.sm : Spacing.md),

            // ── Descripción ──
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                  fontSize: compact ? 13 : 14.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: compact ? Spacing.lg : Spacing.xl2),

            // ── Acciones (Botones) ──
            if (actionLabel != null && onAction != null ||
                secondaryActionLabel != null && onSecondaryAction != null)
              Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  if (secondaryActionLabel != null && onSecondaryAction != null)
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xl2,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                      ),
                      child: Text(
                        secondaryActionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (actionLabel != null && onAction != null)
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xl2,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        elevation: 0,
                        
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

typedef AppEmptyState = EmptyStateWidget;
