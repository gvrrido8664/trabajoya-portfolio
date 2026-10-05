import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class SecurityItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeLabel;
  final bool isWarning;

  const SecurityItemRow({super.key, 
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? colorScheme.secondary.withValues(alpha: 0.15)
            : colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        badgeLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isWarning ? colorScheme.secondary : colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      // Títulos largos ("Verificación de identidad") + el badge fijo al
      // lado no dejaban ancho suficiente en móvil y envolvían letra por
      // letra; se apila el badge debajo del texto cuando no entra junto.
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 260) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                const SizedBox(height: 10),
                badge,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: textBlock),
              const SizedBox(width: 16),
              badge,
            ],
          );
        },
      ),
    );
  }
}