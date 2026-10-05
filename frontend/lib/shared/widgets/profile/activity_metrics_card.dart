import 'activity_grid_tile.dart';
import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ActivityMetricsCard extends StatelessWidget {
  final int solicitudesCount;
  final int contratacionesCount;
  final int referidosCount;
  final bool isTablet;

  const ActivityMetricsCard({super.key, 
    required this.solicitudesCount,
    required this.contratacionesCount,
    required this.referidosCount,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final width = MediaQuery.of(context).size.width;
    int crossCount = 3;
    if (width < 600) {
      crossCount = 1;
    } else if (width < 1100) {
      crossCount = 2;
    }

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad y métricas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Resumen de tu actividad en la plataforma.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 120,
              ),
              children: [
                ActivityGridTile(
                  label: 'Solicitudes activas',
                  value: '$solicitudesCount',
                  note: 'Esperando propuestas',
                ),
                ActivityGridTile(
                  label: 'Contrataciones',
                  value: '$contratacionesCount',
                  note: 'Historial total',
                ),
                ActivityGridTile(
                  label: 'Referidos',
                  value: '$referidosCount',
                  note: 'Usuarios invitados',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}