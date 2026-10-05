import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class AdminDisputasScreen extends StatefulWidget {
  const AdminDisputasScreen({super.key});

  @override
  State<AdminDisputasScreen> createState() => _AdminDisputasScreenState();
}

class _AdminDisputasScreenState extends State<AdminDisputasScreen> {
  String? _statusFilter;
  bool _initLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initLoaded) {
        context.read<AdminProvider>().cargarDisputas();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Resolver Disputa',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Motivo: ${disputa['motivo'] ?? 'No especificado'}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resolucionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resolucion',
                  hintText: 'Describe la resolucion de la disputa...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: accion,
                decoration: const InputDecoration(labelText: 'Accion'),
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
                      const SnackBar(content: Text('Escribe una resolucion')),
                    );
                    return;
                  }
                  try {
                    await context.read<AdminProvider>().resolverDisputa(
                      id,
                      resolucionCtrl.text.trim(),
                      accion,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Disputa resuelta')),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Resolver'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Disputas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por estado',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todas')),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendientes'),
                      ),
                      DropdownMenuItem(
                        value: 'resuelta',
                        child: Text('Resueltas'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _filter();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: admin.loading && admin.disputas.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.disputas.isEmpty
                ? const Center(child: Text('No hay disputas'))
                : RefreshIndicator(
                    onRefresh: () => admin.cargarDisputas(),
                    child: ListView.separated(
                      itemCount: admin.disputas.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (context, index) {
                        final d = admin.disputas[index];
                        final motivo = d['motivo'] as String? ?? '';
                        final contratacionId =
                            d['contratacion_id']?.toString() ?? '-';
                        final status = d['status'] as String? ?? 'pendiente';
                        final createdAt =
                            d['created_at'] as String? ??
                            d['createdAt'] as String?;

                        DateTime? date;
                        if (createdAt != null) {
                          try {
                            date = DateTime.parse(createdAt);
                          } catch (_) {}
                        }

                        return ListTile(
                          title: Text(
                            motivo.isNotEmpty ? motivo : 'Sin motivo',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contrato: $contratacionId'),
                              if (date != null)
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(date),
                                  style: const TextStyle(fontSize: 12),
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
                                  color: status == 'pendiente'
                                      ? AppTheme.secondary.withValues(
                                          alpha: 0.2,
                                        )
                                      : AppTheme.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'pendiente'
                                        ? AppTheme.secondary
                                        : AppTheme.success,
                                  ),
                                ),
                              ),
                              if (status == 'pendiente')
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.primary,
                                  ),
                                  onPressed: () => _showResolverDialog(d),
                                ),
                            ],
                          ),
                          onTap: status == 'pendiente'
                              ? () => _showResolverDialog(d)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
