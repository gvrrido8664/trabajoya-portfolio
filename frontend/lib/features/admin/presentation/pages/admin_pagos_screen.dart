import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class AdminPagosScreen extends StatefulWidget {
  final String? initialStatus;
  const AdminPagosScreen({super.key, this.initialStatus});

  @override
  State<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends State<AdminPagosScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarPagos(status: _statusFilter ?? '');
    });
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    exportCsv(
      context,
      'pagos',
      ['ID Contrato', 'Monto', 'Fee', 'Neto', 'Estado', 'Gateway', 'Fecha'],
      admin.pagos
          .map(
            (p) => [
              p['contratacion_id'] as String? ?? '',
              (p['monto'] as num?)?.toStringAsFixed(0) ?? '0',
              (p['fee_plataforma'] as num?)?.toStringAsFixed(0) ?? '0',
              (p['monto_neto'] as num?)?.toStringAsFixed(0) ?? '0',
              p['status'] as String? ?? '',
              p['metodo_pago'] as String? ?? '',
              p['created_at'] as String? ?? '',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Estado:',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ToggleButtons(
                          isSelected: [
                            _statusFilter == null || _statusFilter == '',
                            _statusFilter == 'pendiente',
                            _statusFilter == 'aprobado',
                            _statusFilter == 'cancelado',
                          ],
                          onPressed: (idx) {
                            String? newStatus;
                            if (idx == 1) newStatus = 'pendiente';
                            if (idx == 2) newStatus = 'aprobado';
                            if (idx == 3) newStatus = 'cancelado';
                            setState(() => _statusFilter = newStatus);
                            context.read<AdminProvider>().cargarPagos(
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
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Pendientes')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Aprobados')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Cancelados')),
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
                      onPressed: admin.pagos.isNotEmpty ? _exportCsv : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: admin.loading && admin.pagos.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : admin.pagos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron pagos',
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
                                          'Monto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Fee',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Neto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Gateway',
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
                                    rows: admin.pagos.map((p) {
                                      final monto =
                                          (p['monto'] as num?)?.toDouble() ?? 0;
                                      final fee =
                                          (p['fee_plataforma'] as num?)
                                              ?.toDouble() ??
                                          0;
                                      final neto =
                                          (p['monto_neto'] as num?)
                                              ?.toDouble() ??
                                          0;
                                      final status =
                                          p['status'] as String? ?? '';
                                      final gateway =
                                          p['metodo_pago'] as String? ?? '';
                                      final fecha =
                                          p['created_at'] as String? ?? '';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: AppTheme.statusColor(status).withValues(alpha: 0.15),
                                                  child: Icon(
                                                    Icons.payment,
                                                    color: AppTheme.statusColor(status),
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '\$ ${monto.toStringAsFixed(0)} CLP',
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
                                              '\$${fee.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '\$${neto.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              gateway.toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            itemCount: admin.pagos.length,
                            itemBuilder: (context, index) {
                              final p = admin.pagos[index];
                              final monto =
                                  (p['monto'] as num?)?.toDouble() ?? 0;
                              final fee =
                                  (p['fee_plataforma'] as num?)?.toDouble() ??
                                  0;
                              final neto =
                                  (p['monto_neto'] as num?)?.toDouble() ?? 0;
                              final status = p['status'] as String? ?? '';
                              final gateway = p['metodo_pago'] as String? ?? '';
                              final fecha = p['created_at'] as String? ?? '';

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
                                        Icons.payment,
                                        color: AppTheme.statusColor(status),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      '\$ ${monto.toStringAsFixed(0)} CLP',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fee: \$${fee.toStringAsFixed(0)} | Neto: \$${neto.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '$gateway — ${_formatearFecha(fecha)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: StatusBadge.forStatus(status),
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

  String _formatearFecha(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }
}
