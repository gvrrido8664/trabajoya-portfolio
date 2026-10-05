import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/features/contrataciones/data/models/contratacion_model.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/confetti_overlay.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';

class ContratacionDetailScreen extends StatefulWidget {
  final String contratacionId;
  const ContratacionDetailScreen({super.key, required this.contratacionId});

  @override
  State<ContratacionDetailScreen> createState() =>
      _ContratacionDetailScreenState();
}

class _ContratacionDetailScreenState extends State<ContratacionDetailScreen> {
  Contratacion? _c;
  bool _loading = true;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant ContratacionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // GoRouter reutiliza este State al navegar de una contratación a otra
    // (mismo tipo de widget, sin Key propia) — sin esto se seguiría
    // mostrando la contratación anterior mientras carga o si el nuevo id no existe.
    if (oldWidget.contratacionId != widget.contratacionId) {
      setState(() {
        _c = null;
        _loading = true;
      });
      _cargar();
    }
  }

  Future<void> _cargar() async {
    final prov = context.read<ContratacionesProvider>();
    await prov.getContratacion(widget.contratacionId);
    if (mounted) {
      setState(() {
        _c = prov.selected;
        _loading = false;
      });
    }
  }

  Future<bool> _confirm(String title, String msg) async {
    final auth = context.read<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _accion(
    Future<bool> Function() fn,
    String okMsg,
    String errMsg, {
    bool triggerConfetti = false,
  }) async {
    final ok = await fn();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(okMsg)));
      if (triggerConfetti) {
        setState(() {
          _showConfetti = true;
        });
      }
      await _cargar();
    } else {
      final prov = context.read<ContratacionesProvider>();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(prov.error ?? errMsg)));
    }
  }

  void _showAbrirDisputaDialog(String contratacionId) {
    final motivoCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir disputa'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Describe el motivo...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final motivo = motivoCtrl.text.trim();
              if (motivo.isEmpty) return;
              Navigator.pop(ctx);
              final prov = context.read<ContratacionesProvider>();
              final res = await prov.abrirDisputa(
                contratacionId: contratacionId,
                motivo: motivo,
              );
              if (!mounted) return;
              if (res != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Disputa creada')));
                await _cargar();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al crear disputa')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showCancelarDialog(String id) async {
    final ok = await _confirm(
      'Cancelar contratacion',
      'Esta acción no se puede deshacer. ¿Deseas continuar?',
    );
    if (!ok) return;
    if (!mounted) return;
    final prov = context.read<ContratacionesProvider>();
    await _accion(
      () => prov.cancelar(id),
      'Contratación cancelada',
      'Error al cancelar',
    );
  }

  void _showEditarMontoDialog(String id, double montoActual) {
    final montoCtrl = TextEditingController(
      text: montoActual.toInt().toString(),
    );
    final auth = context.read<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Actualizar Precio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el nuevo monto para el trabajo:'),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: 'Ej. 25000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(montoCtrl.text.trim());
              if (val == null || val <= 0) return;
              Navigator.pop(ctx);
              final prov = context.read<ContratacionesProvider>();
              await _accion(
                () => prov.actualizarMonto(id, val),
                'Precio actualizado con éxito',
                'Error al actualizar el precio',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Ruta top-level (/contratacion/:id) fuera de ambos shells; cliente y
    // proveedor comparten el mismo tema claro "orden de trabajo" vía
    // Theme.of(context) ambiente, así que no hace falta forzar nada acá.
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final isMobileHead = Breakpoints.isMobile(context);
    final currentUserId = context.read<AuthProvider>().usuario?.id ?? '';
    final esProveedor = _c != null && currentUserId == _c!.proveedorId;
    final esCliente = _c != null && currentUserId == _c!.clienteId;
    final palette = RolePalette(esProveedor, context);

    if (_loading) {
      return Scaffold(
        backgroundColor: palette.scaffold,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: palette.accent,
          ),
        ),
      );
    }

    final c = _c;
    if (c == null) {
      return Scaffold(
        backgroundColor: palette.scaffold,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar la contratación',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargar,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl2),
            child: _centered(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABECERA ---
                  Flex(
                    direction: isMobileHead ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConditionalExpanded(
                        expand: !isMobileHead,
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.servicioTitulo ?? 'Contratación',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMobileHead)
                        const SizedBox(height: Spacing.md)
                      else
                        const SizedBox(width: Spacing.xl),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          backgroundColor: palette.surface,
                          side: BorderSide(color: palette.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          '← Volver',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xl2),

                  // --- LAYOUT RESPONSIVE ---
                  Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bloque Principal
                      _ConditionalExpanded(
                        expand: isDesktop,
                        flex: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: palette.border),
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const CliSectionHeader(title: 'Servicio'),
                                  StatusBadge.forStatus(c.status),
                                ],
                              ),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                c.servicioTitulo ?? '—',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18.0),
                                child: Divider(
                                  color: palette.border,
                                  height: 1,
                                ),
                              ),

                              // Detalles
                              Column(
                                children: [
                                  _DetailRow(
                                    label: 'Cliente',
                                    value: c.clienteNombre ?? c.clienteId,
                                  ),
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: 'Proveedor',
                                    value: c.proveedorNombre ?? c.proveedorId,
                                  ),
                                  const SizedBox(height: 10),
                                  _DetailRow(
                                    label: 'Categoría',
                                    value:
                                        '${c.categoriaIcono ?? ''} ${c.categoriaNombre ?? '—'}',
                                  ),
                                  if (c.subcategoriaNombre != null) ...[
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: 'Subcategoría',
                                      value:
                                          '${c.subcategoriaIcono ?? ''} ${c.subcategoriaNombre!}',
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  if (c.montoAcordado != null)
                                    _DetailRow(
                                      label: 'Monto',
                                      value:
                                          '\$${c.montoAcordado!.toStringAsFixed(0)}',
                                    ),
                                  if (c.mensajeSolicitud != null) ...[
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: 'Mensaje',
                                      value: c.mensajeSolicitud!,
                                    ),
                                  ],
                                  if (c.fechaProgramada != null) ...[
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: 'Fecha',
                                      value: DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(c.fechaProgramada!),
                                    ),
                                  ],
                                  if (c.createdAt != null) ...[
                                    const SizedBox(height: 10),
                                    _DetailRow(
                                      label: 'Creado',
                                      value: DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(c.createdAt!),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Chips
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (c.mensajeSolicitud != null)
                                    _ActionChip(
                                      label:
                                          '💬 Mensaje enviado por el ${esCliente ? "cliente" : "proveedor"}',
                                    ),
                                  if (c.fechaProgramada != null)
                                    _ActionChip(
                                      label:
                                          '📅 Fecha programada: ${DateFormat('dd/MM/yyyy').format(c.fechaProgramada!)}',
                                    ),
                                  _ActionChip(
                                    label:
                                        '🔒 Estado: ${_statusText(c.status)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Botonera
                              Column(
                                children: [
                                  if (c.isPendiente && esProveedor) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: FilledButton(
                                        onPressed: () async {
                                          final ok = await _confirm(
                                            'Aceptar contratación',
                                            '¿Confirmás que deseas aceptar esta contratación?',
                                          );
                                          if (!ok) return;
                                          if (!context.mounted) return;
                                          final prov = context
                                              .read<ContratacionesProvider>();
                                          await _accion(
                                            () => prov.aceptar(c.id),
                                            'Contratación aceptada',
                                            'Error al aceptar',
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: palette.accent,
                                          foregroundColor: palette.onAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Aceptar contratación',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: palette.onAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final ok = await _confirm(
                                            'Rechazar contratación',
                                            '¿Confirmás que deseas rechazar esta contratación?',
                                          );
                                          if (!ok) return;
                                          if (!context.mounted) return;
                                          final prov = context
                                              .read<ContratacionesProvider>();
                                          await _accion(
                                            () => prov.rechazar(c.id),
                                            'Contratación rechazada',
                                            'Error al rechazar',
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: palette.danger,
                                          side: BorderSide(color: palette.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                        ),
                                        child: const Text(
                                          'Rechazar contratación',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (c.isAceptada) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: FilledButton(
                                        onPressed: () async {
                                          final ok = await _confirm(
                                            'Finalizar trabajo',
                                            '¿Confirmás que el trabajo ha sido completado?',
                                          );
                                          if (!ok) return;
                                          if (!context.mounted) return;
                                          final prov = context
                                              .read<ContratacionesProvider>();
                                          await _accion(
                                            () => prov.finalizar(c.id),
                                            'Trabajo finalizado y pago en transferencia',
                                            'Error al finalizar',
                                            triggerConfetti: true,
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: palette.success,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Finalizar trabajo',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            context.push('/chat/${c.id}'),
                                        icon: const Icon(
                                          Icons.chat_outlined,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Abrir chat',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: palette.accent,
                                          side: BorderSide(
                                            color: palette.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (esCliente &&
                                        c.pagoStatus != 'APROBADO') ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              context.push('/pago/${c.id}'),
                                          icon: const Icon(
                                            Icons.payment,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Pagar ahora',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: palette.accent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(Radii.md),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'El pago se procesa de forma segura y se transfiere directamente al proveedor.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: palette.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (c.pagoStatus == 'APROBADO') ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: palette.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            Radii.md,
                                          ),
                                          border: Border.all(
                                            color: palette.success.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: palette.success,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Esta contratación ya está pagada.',
                                                style: TextStyle(
                                                  color: palette.success,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                  if ((c.isPendiente && !esProveedor) ||
                                      c.isAceptada) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showCancelarDialog(c.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: palette.danger,
                                          side: BorderSide(color: palette.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancelar contratación',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (!c.isEnDisputa) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showAbrirDisputaDialog(c.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: palette.danger,
                                          side: BorderSide(color: palette.border),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                        ),
                                        child: const Text(
                                          'Abrir disputa',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (c.isCompletada && !c.hasReviewed) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final creada = await context
                                              .push<bool>('/resena/${c.id}');
                                          if (creada == true) await _cargar();
                                        },
                                        icon: const Icon(
                                          Icons.star_outline,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Dejar reseña para ${esCliente ? (c.proveedorNombre ?? 'el proveedor') : (c.clienteNombre ?? 'el cliente')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: palette.accent,
                                          side: BorderSide(
                                            color: palette.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(Radii.md),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(width: 22)
                      else
                        const SizedBox(height: 22),

                      // Sidebar
                      SizedBox(
                        width: isDesktop ? 340 : double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: palette.border),
                          ),
                          padding: const EdgeInsets.all(22.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CliSectionHeader(title: 'Resumen'),
                              const SizedBox(height: Spacing.lg),
                              Column(
                                children: [
                                  _SidebarInfoBox(
                                    label: 'Servicio',
                                    value: c.servicioTitulo ?? '—',
                                  ),
                                  const SizedBox(height: 12),
                                  _SidebarInfoBox(
                                    label: 'Proveedor',
                                    value: c.proveedorNombre ?? '—',
                                  ),
                                  const SizedBox(height: 12),
                                  _SidebarInfoBox(
                                    label: 'Categoría',
                                    value:
                                        '${c.categoriaIcono ?? ''} ${c.categoriaNombre ?? '—'}',
                                  ),
                                  if (c.subcategoriaNombre != null) ...[
                                    const SizedBox(height: 12),
                                    _SidebarInfoBox(
                                      label: 'Subcategoría',
                                      value:
                                          '${c.subcategoriaIcono ?? ''} ${c.subcategoriaNombre!}',
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  if (c.fechaProgramada != null) ...[
                                    const SizedBox(height: 12),
                                    _SidebarInfoBox(
                                      label: 'Fecha',
                                      value: DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(c.fechaProgramada!.toLocal()),
                                    ),
                                  ],
                                  if (c.montoAcordado != null) ...[
                                    const SizedBox(height: 12),
                                    _SidebarInfoBox(
                                      label: 'Monto a pagar',
                                      value: NumberFormat.currency(
                                        locale: 'es_CL',
                                        symbol: '\$',
                                        decimalDigits: 0,
                                      ).format(c.montoAcordado!),
                                      trailing:
                                          (esProveedor &&
                                              c.pagoStatus != 'APROBADO' &&
                                              !c.isFinalizada &&
                                              !c.isRechazada &&
                                              !c.isCancelada)
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: palette.accent,
                                              ),
                                              onPressed: () =>
                                                  _showEditarMontoDialog(
                                                    c.id,
                                                    c.montoAcordado!,
                                                  ),
                                              tooltip: 'Editar precio',
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            )
                                          : null,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _SidebarInfoBox(
                                    label: 'Estado',
                                    value: _statusText(c.status),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ConfettiOverlay(
            show: _showConfetti,
            onFinished: () => setState(() => _showConfetti = false),
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'ACEPTADO':
        return 'Aceptado';
      case 'RECHAZADO':
        return 'Rechazado';
      case 'COMPLETADO':
        return 'Completado';
      case 'CANCELADO':
        return 'Cancelado';
      case 'DISPUTA':
        return 'En disputa';
      default:
        return status;
    }
  }
}

// --- SUB-WIDGETS ---

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final auth = context.watch<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);

    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isMobile ? double.infinity : 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
        if (isMobile) const SizedBox(height: 4) else const SizedBox(width: 14),
        _ConditionalExpanded(
          expand: !isMobile,
          flex: 1,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  const _ActionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.elevated,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SidebarInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _SidebarInfoBox({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final palette = RolePalette.of(auth.activeMode, context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _ConditionalExpanded extends StatelessWidget {
  final bool expand;
  final int flex;
  final Widget child;

  const _ConditionalExpanded({
    required this.expand,
    required this.flex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return expand ? Expanded(flex: flex, child: child) : child;
  }
}
