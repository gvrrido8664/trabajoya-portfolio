import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AdminSuscripcionesScreen extends StatefulWidget {
  const AdminSuscripcionesScreen({super.key});

  @override
  State<AdminSuscripcionesScreen> createState() =>
      _AdminSuscripcionesScreenState();
}

class _AdminSuscripcionesScreenState extends State<AdminSuscripcionesScreen> {
  String? _statusFilter;
  String _cancelandoId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarSuscripcionesAdmin();
    });
  }

  Future<void> _asignarPlan(String usuarioId, String nombre, String currentPlanSlug) async {
    final admin = context.read<AdminProvider>();
    String selectedPlanSlug = currentPlanSlug.isNotEmpty ? currentPlanSlug.toLowerCase() : 'basico';
    if (selectedPlanSlug != 'basico' && selectedPlanSlug != 'premium') {
      selectedPlanSlug = 'basico';
    }
    
    final newPlan = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Asignar Plan de Suscripción', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Proveedor: $nombre', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  Text('Seleccionar Plan:', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedPlanSlug,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'basico', child: Text('Básico')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() => selectedPlanSlug = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, selectedPlanSlug),
                  child: const Text('Asignar', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPlan == null || newPlan == currentPlanSlug) return;

    setState(() => _cancelandoId = usuarioId);
    final ok = await admin.asignarPlanSuscripcion(usuarioId, newPlan);
    if (mounted) {
      setState(() => _cancelandoId = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Plan asignado exitosamente' : 'Error al asignar plan'),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    final data = admin.suscripciones;
    exportCsv(
      context,
      'suscripciones_proveedores',
      ['Usuario', 'Email', 'Plan', 'Estado', 'Inicio', 'Fin'],
      data
          .map(
            (s) => [
              s['usuario_nombre'] as String? ?? '',
              s['usuario_email'] as String? ?? '',
              s['plan_nombre'] as String? ?? 'Ninguno',
              s['status'] as String? ?? 'INACTIVA',
              s['fecha_inicio'] as String? ?? '',
              s['fecha_vencimiento'] as String? ?? '',
            ],
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final data = admin.suscripciones.where((s) {
      if (_statusFilter == null) return true;
      return s['status'] == _statusFilter;
    }).toList();

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
                      child: DropdownButtonFormField<String?>(
                        initialValue: _statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Filtrar por estado',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              'Todas',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'ACTIVA',
                            child: Text(
                              'Activas',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'INACTIVA',
                            child: Text(
                              'Sin Plan',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'CANCELADA',
                            child: Text(
                              'Canceladas',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.file_download_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Exportar CSV',
                      onPressed: _exportCsv,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Actualizar',
                      onPressed: () => context
                          .read<AdminProvider>()
                          .cargarSuscripcionesAdmin(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: admin.loading && admin.suscripciones.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : data.isEmpty
                    ? Center(
                        child: Text(
                          'No hay suscripciones',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final s = data[index];
                          final id = s['usuario_id']?.toString() ?? '';
                          final nombre = s['usuario_nombre'] as String? ?? '';
                          final email = s['usuario_email'] as String? ?? '';
                          final plan = s['plan_nombre'] as String? ?? 'Ninguno';
                          final planSlug = s['plan_slug'] as String? ?? '';
                          final status = s['status'] as String? ?? 'INACTIVA';
                          final inicio = s['fecha_inicio'] as String? ?? '';
                          final isCancelling = _cancelandoId == id;

                          final hasPlan = planSlug.isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      (hasPlan
                                              ? AppColors.success
                                              : AppColors.border)
                                          .withValues(alpha: 0.15),
                                  child: Text(
                                    nombre.isNotEmpty
                                        ? nombre[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: hasPlan
                                          ? AppColors.success
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  nombre,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          plan.toUpperCase(),
                                          style: TextStyle(
                                            color: hasPlan ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (hasPlan) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Inicio: ${_formatearFecha(inicio)}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
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
                                        color:
                                            (hasPlan
                                                    ? AppColors.success
                                                    : AppColors.border)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(Radii.md),
                                      ),
                                      child: Text(
                                        hasPlan ? status.toUpperCase() : 'SIN PLAN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: hasPlan
                                              ? AppColors.success
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    isCancelling
                                        ? const Padding(
                                            padding: EdgeInsets.only(left: 8),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                            tooltip: 'Asignar plan',
                                            onPressed: () =>
                                                _asignarPlan(
                                              id,
                                              nombre,
                                              planSlug,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
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
      return iso;
    }
  }
}
