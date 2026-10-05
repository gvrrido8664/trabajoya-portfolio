import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/contrataciones/data/models/contratacion_model.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/shared/widgets/corner_border_container.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ContratacionesProveedorScreen extends StatefulWidget {
  const ContratacionesProveedorScreen({super.key});

  @override
  State<ContratacionesProveedorScreen> createState() =>
      _ContratacionesProveedorScreenState();
}

class _ContratacionesProveedorScreenState
    extends State<ContratacionesProveedorScreen> {
  String _filtro = 'Todas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContratacionesProvider>().cargarContrataciones();
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
    final prov = context.watch<ContratacionesProvider>();
    final auth = context.watch<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);
    final isProveedorMode = auth.isProveedorMode;
    final uid = auth.usuario?.id;

    final rawContrataciones = prov.contrataciones
        .where(
          (c) => isProveedorMode ? c.proveedorId == uid : c.clienteId == uid,
        )
        .toList();

    final todasCount = rawContrataciones.length;
    final porPagarCount = rawContrataciones
        .where((c) => (c.pagoStatus == 'PENDIENTE' || c.pagoStatus == null) && c.status != 'CANCELADO' && c.status != 'COMPLETADO')
        .length;
    final enCursoCount = rawContrataciones
        .where((c) => c.status == 'ACEPTADO' || c.status == 'EN_PROGRESO')
        .length;
    final completadasCount = rawContrataciones
        .where((c) => c.status == 'COMPLETADO')
        .length;

    List<Contratacion> filtered = rawContrataciones;
    if (_filtro == 'Por pagar') {
      filtered = rawContrataciones
          .where((c) => (c.pagoStatus == 'PENDIENTE' || c.pagoStatus == null) && c.status != 'CANCELADO' && c.status != 'COMPLETADO')
          .toList();
    } else if (_filtro == 'En curso') {
      filtered = rawContrataciones
          .where((c) => c.status == 'ACEPTADO' || c.status == 'EN_PROGRESO')
          .toList();
    } else if (_filtro == 'Completadas') {
      filtered = rawContrataciones
          .where((c) => c.status == 'COMPLETADO')
          .toList();
    }

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: RefreshIndicator(
        onRefresh: () => prov.cargarContrataciones(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacing.xl2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis contrataciones',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),

                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      _FilterChipItem(
                        label: 'Todas',
                        count: todasCount,
                        isSelected: _filtro == 'Todas',
                        onTap: () => setState(() => _filtro = 'Todas'),
                      ),
                      _FilterChipItem(
                        label: 'Por pagar',
                        count: porPagarCount,
                        isSelected: _filtro == 'Por pagar',
                        onTap: () => setState(() => _filtro = 'Por pagar'),
                      ),
                      _FilterChipItem(
                        label: 'En curso',
                        count: enCursoCount,
                        isSelected: _filtro == 'En curso',
                        onTap: () => setState(() => _filtro = 'En curso'),
                      ),
                      _FilterChipItem(
                        label: 'Completadas',
                        count: completadasCount,
                        isSelected: _filtro == 'Completadas',
                        onTap: () => setState(() => _filtro = 'Completadas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl),

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
                            color: palette.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (!isProveedorMode)
                    _ClienteContratacionesList(
                      items: filtered,
                      palette: palette,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Card(
                          margin: EdgeInsets.zero,
                          color: palette.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                            side: BorderSide(color: palette.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: filtered.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(Spacing.xl3),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: palette.accent.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.handshake_outlined,
                                            color: palette.accent,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: Spacing.lg),
                                        Text(
                                          'No hay contrataciones todavía',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: palette.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: Spacing.xs),
                                        Text(
                                          isProveedorMode
                                              ? 'Cuando un cliente acepte tu propuesta aparecerá aquí.'
                                              : 'Cuando contrates a un proveedor aparecerá aquí.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: palette.textSecondary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : isMobile
                              ? _buildMobileList(
                                  context,
                                  filtered,
                                  palette,
                                  theme,
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      palette.elevated,
                                    ),
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 65,
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'SERVICIO',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: palette.textMuted,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          isProveedorMode
                                              ? 'CLIENTE'
                                              : 'PROVEEDOR',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: palette.textMuted,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'PRECIO',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: palette.textMuted,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'FECHA',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: palette.textMuted,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'ESTADO',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: palette.textMuted,
                                              ),
                                        ),
                                      ),
                                      const DataColumn(
                                        label: Text(
                                          '',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                    rows: filtered
                                        .map((c) => _buildRow(context, c))
                                        .toList(),
                                  ),
                                ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    List<Contratacion> items,
    RolePalette palette,
    ThemeData theme,
  ) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildMobileCard(context, items[i], palette, theme),
          if (i < items.length - 1) Divider(height: 1, color: palette.border),
        ],
      ],
    );
  }

  Widget _buildMobileCard(
    BuildContext context,
    Contratacion c,
    RolePalette palette,
    ThemeData theme,
  ) {
    final statusLabel = switch (c.status.toUpperCase()) {
      'ACEPTADO' => 'Confirmada',
      'COMPLETADO' => 'Finalizada',
      'CANCELADO' => 'Cancelada',
      _ => AppTheme.statusLabel(c.status),
    };
    final precioStr = c.montoAcordado != null
        ? _formatClp(c.montoAcordado!)
        : 'A convenir';
    final fechaStr = _formatFecha(c.createdAt);

    return InkWell(
      onTap: () => context.push('/contratacion/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.servicioTitulo ?? 'Sin título',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                StatusBadge.forStatus(c.status, label: statusLabel),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: palette.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (context.read<AuthProvider>().isProveedorMode
                            ? c.clienteNombre
                            : c.proveedorNombre) ??
                        '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  fechaStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              precioStr,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Contratacion c) {
    final auth = context.read<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);
    final theme = Theme.of(context);

    final statusLabel = switch (c.status.toUpperCase()) {
      'ACEPTADO' => 'Confirmada',
      'COMPLETADO' => 'Finalizada',
      'CANCELADO' => 'Cancelada',
      _ => AppTheme.statusLabel(c.status),
    };
    final precioStr = c.montoAcordado != null
        ? _formatClp(c.montoAcordado!)
        : 'A convenir';
    final fechaStr = _formatFecha(c.createdAt);

    return DataRow(
      cells: [
        DataCell(
          Text(
            c.servicioTitulo ?? 'Sin título',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          onTap: () => context.push('/contratacion/${c.id}'),
        ),
        DataCell(
          Text(
            (auth.isProveedorMode ? c.clienteNombre : c.proveedorNombre) ?? '—',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            precioStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
        DataCell(
          Text(
            fechaStr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        DataCell(StatusBadge.forStatus(c.status, label: statusLabel)),
        DataCell(
          TextButton(
            onPressed: () => context.push('/contratacion/${c.id}'),
            child: Text(
              'Ver',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sidebarBottom : Colors.white,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: isSelected
                ? null
                : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '· $count',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MisContratacionesScreen extends StatelessWidget {
  const MisContratacionesScreen({super.key});

  @override
  Widget build(BuildContext context) => const ContratacionesProveedorScreen();
}

class _ClienteContratacionesList extends StatelessWidget {
  final List<Contratacion> items;
  final RolePalette palette;

  const _ClienteContratacionesList({
    required this.items,
    required this.palette,
  });

  String _formatClp(double monto) {
    final digits = monto.toInt().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '\$${buffer.toString()}';
  }

  String _formatFecha(DateTime? date) {
    if (date == null) return 'en curso';
    const months = [
      '01',
      '02',
      '03',
      '04',
      '05',
      '06',
      '07',
      '08',
      '09',
      '10',
      '11',
      '12',
    ];
    return '${date.day.toString().padLeft(2, '0')}/${months[date.month - 1]}';
  }

  Widget _buildStatusBadge(Contratacion item) {
    final isPorPagar = (item.pagoStatus == 'PENDIENTE' || item.pagoStatus == null) && item.status != 'CANCELADO' && item.status != 'COMPLETADO';
    final isCompletado = item.status == 'COMPLETADO';
    final isEnCurso = item.status == 'ACEPTADO' || item.status == 'EN_PROGRESO';

    Color bg;
    Color fg;
    String label;

    if (isPorPagar) {
      bg = AppColors.rustTint;
      fg = AppColors.rust;
      label = 'POR PAGAR';
    } else if (isEnCurso) {
      bg = AppColors.amberTint;
      fg = AppColors.amber;
      label = 'EN CURSO';
    } else if (isCompletado) {
      bg = AppColors.verifiedTint;
      fg = AppColors.verified;
      label = 'COMPLETADO';
    } else {
      bg = AppColors.border;
      fg = AppColors.inkSoft;
      label = item.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return CornerBorderContainer(
        color: AppColors.border,
        backgroundColor: Colors.white,
        strokeWidth: 2,
        padding: const EdgeInsets.all(Spacing.xl3),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.handshake_outlined, size: 36, color: AppColors.rust),
              const SizedBox(height: Spacing.lg),
              Text(
                'Aún no tienes contrataciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Cuando contrates a un proveedor, el seguimiento aparecerá aquí.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          CornerBorderContainer(
            color: AppColors.border,
            backgroundColor: Colors.white,
            strokeWidth: 2,
            padding: const EdgeInsets.all(Spacing.lg),
            child: GestureDetector(
              onTap: () => context.push('/contratacion/${item.id}'),
              child: Container(
                color: Colors.transparent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;
                    final providerName = item.proveedorNombre ?? 'Proveedor';
                    final amount = item.montoAcordado == null
                        ? 'A convenir'
                        : _formatClp(item.montoAcordado!);
                    final detail = item.servicioTitulo ?? 'Servicio contratado';
                    final dateStr = item.status == 'ACEPTADO'
                        ? 'en curso'
                        : _formatFecha(item.createdAt);

                    final isPorPagar = (item.pagoStatus == 'PENDIENTE' || item.pagoStatus == null) && item.status != 'CANCELADO' && item.status != 'COMPLETADO';
                    final isCompletado = item.status == 'COMPLETADO';

                    final identity = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.sidebarBottom,
                          child: Text(
                            providerName.isNotEmpty
                                ? providerName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                providerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$detail · $dateStr',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final rightActions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusBadge(item),
                        const SizedBox(width: Spacing.md),
                        Text(
                          amount,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        // Action buttons according to mockup
                        OutlinedButton(
                          onPressed: () => context.push('/chat/${item.id}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(40, 34),
                          ),
                          child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        if (isPorPagar) ...[
                          const SizedBox(width: Spacing.sm),
                          ElevatedButton(
                            onPressed: () => context.push('/pago/${item.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rust,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(40, 34),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                            ),
                            child: const Text('Pagar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (isCompletado) ...[
                          const SizedBox(width: Spacing.sm),
                          OutlinedButton(
                            onPressed: () => context.push('/resena/${item.id}'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: const Size(40, 34),
                            ),
                            child: Text(
                              item.hasReviewed ? 'Ver reseña ★5.0' : 'Calificar',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          identity,
                          const SizedBox(height: Spacing.md),
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildStatusBadge(item),
                              Text(
                                amount,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => context.push('/chat/${item.id}'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                  side: BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(40, 32),
                                ),
                                child: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              if (isPorPagar)
                                ElevatedButton(
                                  onPressed: () => context.push('/pago/${item.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.rust,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    minimumSize: const Size(40, 32),
                                  ),
                                  child: const Text('Pagar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              if (isCompletado)
                                OutlinedButton(
                                  onPressed: () => context.push('/resena/${item.id}'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: BorderSide(color: AppColors.border),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: const Size(40, 32),
                                  ),
                                  child: Text(
                                    item.hasReviewed ? 'Ver reseña ★5.0' : 'Calificar',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: Spacing.lg),
                        rightActions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }
}
