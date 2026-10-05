import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/propuestas/data/models/propuesta_model.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/features/propuestas/presentation/providers/propuestas_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class MisPropuestasScreen extends StatefulWidget {
  const MisPropuestasScreen({super.key});

  @override
  State<MisPropuestasScreen> createState() => _MisPropuestasScreenState();
}

class _MisPropuestasScreenState extends State<MisPropuestasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropuestasProvider>().cargarMisPropuestas();
    });
  }

  String _formatClp(double monto) {
    final s = monto.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '\$${buf.toString()}';
  }

  String _formatFecha(DateTime? dt) {
    if (dt == null) return '—';
    const meses = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<PropuestasProvider>();

    return ProScaffold(
      showAppBar: false,
      body: RefreshIndicator(
        onRefresh: () => prov.cargarMisPropuestas(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacing.xl2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProSectionHeader(title: 'Mis propuestas'),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Revisa el estado de cada propuesta enviada a oportunidades de clientes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ProColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl2),

                  if (prov.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(Spacing.xl2),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (prov.error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl2),
                        child: Text(
                          prov.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ProColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (prov.propuestas.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Spacing.xl3,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: ProColors.accent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_outlined,
                                color: ProColors.accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            Text(
                              'Todavía no enviaste propuestas',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ProColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Explora las oportunidades disponibles y envía tu primera propuesta.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ProColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (int i = 0; i < prov.propuestas.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          _buildCard(prov.propuestas[i]),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Propuesta p) {
    // Copy cercano para el pendiente; el color/icono salen del vocabulario único.
    final statusLabel =
        p.isPendiente ? 'Esperando respuesta' : AppTheme.statusLabel(p.status);
    final montoStr = _formatClp(p.precio);
    final fechaStr = _formatFecha(p.createdAt);
    final tipoStr = p.tiempoEstimado;

    final theme = Theme.of(context);
    return ProCard(
      onTap: null,
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ProColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          'Enviada',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ProColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.solicitudTitulo ?? 'Solicitud sin título',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ProColors.textPrimary,
                        ),
                      ),
                      Text(
                        p.descripcion,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ProColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.forStatus(p.status, label: statusLabel),
              ],
            ),
            const SizedBox(height: 18),
            // 2-4 columnas no dan ancho suficiente para etiquetas como
            // "TIEMPO ESTIMADO" o valores como "$45.000": envuelven
            // letra/dígito por medio y desbordan la altura fija de la
            // celda, "sangrando" sobre la descripción de abajo. Basado en
            // el ancho LOCAL de la tarjeta (no en Breakpoints.isMobile,
            // que solo mira el ancho total de ventana): con sidebar visible
            // (>=600px) la tarjeta puede seguir angosta hasta ~800px de
            // ventana, zona muerta donde isMobile ya da false pero 4
            // columnas igual no caben.
            LayoutBuilder(
              builder: (context, constraints) {
                final compactGrid = constraints.maxWidth < 520;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compactGrid ? 1 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: compactGrid ? 56 : 78,
                  ),
                  children: [
                    _CellMetric(label: 'Monto ofrecido', value: montoStr, compact: compactGrid),
                    _CellMetric(label: 'Tiempo estimado', value: tipoStr, compact: compactGrid),
                    _CellMetric(label: 'Fecha propuesta', value: fechaStr, compact: compactGrid),
                    _CellMetric(label: 'Estado', value: statusLabel, compact: compactGrid),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              p.descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ProColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
  }
}

class _CellMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  const _CellMetric({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: ProColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: ProColors.textPrimary,
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: ProColors.surfaceHi,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: ProColors.border),
      ),
      // En "compact" (móvil, celda a ancho completo) van lado a lado en una
      // sola línea cada uno; en el grid de 4 columnas de escritorio siguen
      // apiladas verticalmente como antes.
      child: compact
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                labelText,
                const SizedBox(width: 12),
                valueText,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                labelText,
                const SizedBox(height: 4),
                valueText,
              ],
            ),
    );
  }
}
