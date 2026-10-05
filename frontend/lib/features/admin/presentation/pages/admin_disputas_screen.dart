import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AdminDisputasScreen extends StatefulWidget {
  final String? initialStatus;
  const AdminDisputasScreen({super.key, this.initialStatus});

  @override
  State<AdminDisputasScreen> createState() => _AdminDisputasScreenState();
}

class _AdminDisputasScreenState extends State<AdminDisputasScreen> {
  String? _statusFilter;
  bool _initLoaded = false;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initLoaded) {
        _filter();
        _initLoaded = true;
      }
    });
  }

  void _filter() {
    context.read<AdminProvider>().cargarDisputas(status: _statusFilter);
  }

  void _showResolverDialog(Map<String, dynamic> disputa) {
    final id = disputa['id']?.toString() ?? '';
    final resolucionCtrl = TextEditingController();
    String accion = 'reembolsar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Resolver Disputa',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Motivo: ${disputa['motivo'] ?? 'No especificado'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resolucionCtrl,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Resolución',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  hintText: 'Describe la resolución de la disputa...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    borderSide: BorderSide(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: accion,
                decoration: InputDecoration(
                  labelText: 'Acción',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    borderSide: BorderSide(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                items: const [
                  DropdownMenuItem(
                    value: 'reembolsar',
                    child: Text('Reembolsar al cliente'),
                  ),
                  DropdownMenuItem(
                    value: 'liberar',
                    child: Text('Liberar pago al proveedor'),
                  ),
                ],
                onChanged: (v) => accion = v!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (resolucionCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Escribe una resolución')),
                    );
                    return;
                  }
                  try {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<AdminProvider>().resolverDisputa(
                      id,
                      resolucionCtrl.text.trim(),
                      accion,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Disputa resuelta'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.12),
                  foregroundColor: AppColors.success,
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Resolver',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    exportCsv(
      context,
      'disputas',
      ['ID Contrato', 'Motivo', 'Estado', 'Creado'],
      admin.disputas
          .map(
            (d) => [
              d['contratacion_id']?.toString() ?? '',
              d['motivo'] as String? ?? '',
              d['status'] as String? ?? '',
              d['created_at'] as String? ?? '',
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ToggleButtons(
                          isSelected: [
                            _statusFilter == null || _statusFilter == '',
                            _statusFilter == 'abierta',
                            _statusFilter == 'resuelta',
                          ],
                          onPressed: (idx) {
                            String? newStatus;
                            if (idx == 1) newStatus = 'abierta';
                            if (idx == 2) newStatus = 'resuelta';
                            setState(() => _statusFilter = newStatus);
                            _filter();
                          },
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          selectedColor: AppColors.primary,
                          fillColor: AppColors.primary.withValues(alpha: 0.1),
                          borderColor: AppColors.border,
                          selectedBorderColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(Radii.sm),
                          constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                          children: const [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Todas')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Pendientes')),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Resueltas')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.file_download_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Exportar CSV',
                      onPressed: admin.disputas.isNotEmpty ? _exportCsv : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: admin.loading && admin.disputas.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : admin.disputas.isEmpty
                    ? Center(
                        child: Text(
                          'No hay disputas',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => admin.cargarDisputas(),
                        child: ListView.separated(
                          itemCount: admin.disputas.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final d = admin.disputas[index];
                            final motivo = d['motivo'] as String? ?? '';
                            final contratacionId =
                                d['contratacion_id']?.toString() ?? '-';
                            final status =
                                d['status'] as String? ?? 'ABIERTA';
                            final createdAt =
                                d['created_at'] as String? ??
                                d['createdAt'] as String?;

                            DateTime? date;
                            if (createdAt != null) {
                              try {
                                date = DateTime.parse(createdAt);
                              } catch (_) {}
                            }

                            final isPending = status == 'ABIERTA';
                            final statusColor = isPending
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary;

                            return Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(
                                  motivo.isNotEmpty ? motivo : 'Sin motivo',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contrato: $contratacionId',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (date != null)
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(date),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(Radii.md),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    if (isPending)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: AppColors.primary,
                                        ),
                                        tooltip: 'Resolver disputa',
                                        onPressed: () => _showResolverDialog(d),
                                      ),
                                  ],
                                ),
                                onTap: isPending
                                    ? () => _showResolverDialog(d)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
