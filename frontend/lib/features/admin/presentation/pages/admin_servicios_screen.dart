import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AdminServiciosScreen extends StatefulWidget {
  final String? initialStatus;
  const AdminServiciosScreen({super.key, this.initialStatus});

  @override
  State<AdminServiciosScreen> createState() => _AdminServiciosScreenState();
}

class _AdminServiciosScreenState extends State<AdminServiciosScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarServicios(
        status: _statusFilter ?? '',
      );
    });
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    exportCsv(
      context,
      'servicios',
      ['Título', 'Estado', 'Precio Mín', 'Precio Máx', 'Creado'],
      admin.servicios
          .map(
            (s) => [
              s['titulo'] as String? ?? '',
              s['status'] as String? ?? '',
              (s['precio_min'] as num?)?.toStringAsFixed(0) ?? '',
              (s['precio_max'] as num?)?.toStringAsFixed(0) ?? '',
              s['created_at'] as String? ?? '',
            ],
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _kpiCard(
                        title: 'TOTAL SERVICIOS',
                        value: '${admin.servicios.length}',
                        icon: Icons.design_services,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        title: 'ACTIVOS',
                        value: '${admin.servicios.where((s) => s['status'] == 'ACTIVO').length}',
                        icon: Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiCard(
                        title: 'PAUSADOS',
                        value: '${admin.servicios.where((s) => s['status'] == 'PAUSADO').length}',
                        icon: Icons.pause_circle_outline,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ToggleButtons(
                          isSelected: [
                            _statusFilter == null || _statusFilter == '',
                            _statusFilter == 'activo',
                            _statusFilter == 'pausado',
                            _statusFilter == 'eliminado',
                          ],
                          onPressed: (idx) {
                            String? newStatus;
                            if (idx == 1) newStatus = 'activo';
                            if (idx == 2) newStatus = 'pausado';
                            if (idx == 3) newStatus = 'eliminado';
                            setState(() => _statusFilter = newStatus);
                            context.read<AdminProvider>().cargarServicios(
                                  status: newStatus ?? '',
                                );
                          },
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderColor: Theme.of(context).colorScheme.outlineVariant,
                          selectedBorderColor: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Todos')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Activos')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Pausados')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Eliminados')),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.file_download_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Exportar CSV',
                      onPressed: admin.servicios.isNotEmpty ? _exportCsv : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: admin.loading && admin.servicios.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : admin.servicios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.miscellaneous_services,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron servicios',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 800;

                          if (isDesktop) {
                            return SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Radii.md),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Theme.of(context).colorScheme.surfaceContainerHighest,
                                    ),
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'Servicio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Precio',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Estado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Fecha',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: admin.servicios.map((s) {
                                      final titulo =
                                          s['titulo'] as String? ?? '';
                                      final status =
                                          s['status'] as String? ?? '';
                                      final precioMin = s['precio_min'];
                                      final precioMax = s['precio_max'];
                                      final fecha =
                                          s['created_at'] as String? ?? '';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: AppTheme.statusColor(status).withValues(alpha: 0.15),
                                                  child: Icon(
                                                    Icons.build,
                                                    color: AppTheme.statusColor(status),
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  titulo,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              _formatPrecio(precioMin, precioMax),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            StatusBadge.forStatus(status),
                                          ),
                                          DataCell(
                                            Text(
                                              _formatearFecha(fecha),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: admin.servicios.length,
                            itemBuilder: (context, index) {
                              final s = admin.servicios[index];
                              final titulo = s['titulo'] as String? ?? '';
                              final status = s['status'] as String? ?? '';
                              final precioMin = s['precio_min'];
                              final precioMax = s['precio_max'];
                              final fecha = s['created_at'] as String? ?? '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.statusColor(status).withValues(alpha: 0.15),
                                      child: Icon(
                                        Icons.build,
                                        color: AppTheme.statusColor(status),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      titulo,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      _formatearFecha(fecha),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (precioMin != null)
                                          Text(
                                            _formatPrecio(precioMin, precioMax),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        StatusBadge.forStatus(status),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrecio(dynamic precioMin, dynamic precioMax) {
    if (precioMin == null) return '-';
    final min = (precioMin as num).toStringAsFixed(0);
    if (precioMax == 1.0) return '\$ $min / hora';
    if (precioMax == 2.0) return '\$ $min / servicio';
    return 'Desde \$ $min';
  }

  String _formatearFecha(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
