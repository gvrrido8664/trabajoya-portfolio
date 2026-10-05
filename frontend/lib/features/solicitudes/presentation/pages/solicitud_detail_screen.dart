import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/propuestas/data/datasources/propuestas_remote_datasource.dart';
import 'package:trabajoya_app/features/propuestas/data/models/propuesta_model.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';

class SolicitudDetailScreen extends StatefulWidget {
  final String solicitudId;
  const SolicitudDetailScreen({super.key, required this.solicitudId});

  @override
  State<SolicitudDetailScreen> createState() => _SolicitudDetailScreenState();
}

class _SolicitudDetailScreenState extends State<SolicitudDetailScreen> {
  final SolicitudesService _solService = SolicitudesService();
  final PropuestasService _propService = PropuestasService();
  Solicitud? _solicitud;
  List<Propuesta> _propuestas = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 20;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _cargar();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pos = _scrollController.position.pixels;
    if (pos >= max - 200) {
      if (_hasMore && !_loadingMore) _cargarMas();
    }
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final sol = await _solService.getSolicitud(widget.solicitudId);
      if (!mounted) return;
      final currentUserId = context.read<AuthProvider>().usuario?.id ?? '';
      final esOwner = currentUserId == sol.clienteId;
      if (esOwner) {
        try {
          final results = await _propService.getPropuestas(
            widget.solicitudId,
            skip: 0,
            limit: _pageSize,
          );
          _propuestas = results;
          _hasMore = results.length >= _pageSize;
          _page = 1;
        } catch (_) {
          _propuestas = [];
        }
      }
      if (mounted) {
        setState(() {
          _solicitud = sol;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarMas() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    setState(() {});
    try {
      final results = await _propService.getPropuestas(
        widget.solicitudId,
        skip: _page * _pageSize,
        limit: _pageSize,
      );
      _propuestas.addAll(results);
      _hasMore = results.length >= _pageSize;
      _page++;
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<bool> _confirm(String title, String msg) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          msg,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _cerrarSolicitud() async {
    final ok = await _confirm(
      'Cerrar solicitud',
      'Una vez cerrada no recibiras mas propuestas. Deseas continuar?',
    );
    if (!ok) return;
    try {
      await _solService.cerrarSolicitud(widget.solicitudId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Solicitud cerrada')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar: ${formatError(e)}')),
      );
    }
  }

  Future<void> _aceptarPropuesta(Propuesta prop) async {
    final ok = await _confirm(
      'Aceptar propuesta',
      'Esta accion creara una contratacion con el proveedor. Deseas continuar?',
    );
    if (!ok) return;
    try {
      final resp = await _propService.aceptarPropuesta(
        widget.solicitudId,
        prop.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Propuesta aceptada')));
      final cid = resp.contratacionId;
      if (cid != null && cid.isNotEmpty) {
        context.push('/contratacion/$cid');
      } else {
        _cargar();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar: ${formatError(e)}')),
      );
    }
  }

  Future<void> _rechazarPropuesta(Propuesta prop) async {
    final ok = await _confirm(
      'Rechazar propuesta',
      'Confirmas que deseas rechazar esta propuesta?',
    );
    if (!ok) return;
    try {
      await _propService.rechazarPropuesta(widget.solicitudId, prop.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Propuesta rechazada')));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar: ${formatError(e)}')),
      );
    }
  }

  void _abrirComparativa() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogWidth = screenWidth > 800 ? 700.0 : screenWidth * 0.95;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          actionsPadding: const EdgeInsets.fromLTRB(10, 10, 20, 15),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Comparar propuestas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Theme(
                  data: theme.copyWith(
                    dividerColor: theme.dividerColor,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      colorScheme.surfaceContainerHighest,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'Proveedor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Precio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tiempo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Valoración',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Acción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    rows: _propuestas.map((p) {
                      final rating = (p.proveedorNombre.hashCode % 15 + 35) / 10.0;
                      final ratingStr = '${rating.toStringAsFixed(1)} ★';
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              p.proveedorNombre ?? '—',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '\$${p.precio.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: CliColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              p.tiempoEstimado,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ratingStr, 
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _aceptarPropuesta(p);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.tertiary,
                                  foregroundColor: colorScheme.onTertiary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Radii.sm),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Aceptar',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1100;
    final isMobileHead = width < 760;

    // Esta pantalla es compartida entre Cliente y Proveedor (se llega tanto
    // desde "Mis solicitudes" como desde "Oportunidades"); ambos comparten
    // el mismo tema claro "orden de trabajo", así que basta con Theme.of(context).
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DelayedLoader(
        loading: _loading,
        loader: const SkeletonDetail(),
        child: _buildBody(context, isDesktop, isMobileHead),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop, bool isMobileHead) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sol = _solicitud;

    if (sol == null) {
      return Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/cliente/mis-solicitudes'),
            ),
          ),
          Expanded(
            child: Center(
              child: EmptyStateWidget(
                icon: Icons.error_outline_rounded,
                variant: EmptyStateVariant.error,
                title: 'Solicitud no encontrada',
                description: 'La solicitud que buscas no existe o ha sido eliminada.',
                actionLabel: 'Volver a mis solicitudes',
                onAction: () => context.canPop()
                    ? context.pop()
                    : context.go('/cliente/mis-solicitudes'),
              ),
            ),
          ),
        ],
      );
    }

    final currentUserId = context.read<AuthProvider>().usuario?.id ?? '';
    final esOwner = currentUserId == sol.clienteId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl2),
      child: _centered(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flex(
              direction: isMobileHead ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isMobileHead ? 0 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle de solicitud',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                                fontFamily: 'Manrope',
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Revisa los datos de tu solicitud y las propuestas recibidas.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.55,
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
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/cliente/mis-solicitudes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      backgroundColor: colorScheme.surface,
                      side: BorderSide(color: colorScheme.outlineVariant),
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
              Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isDesktop ? 12 : 0,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    sol.titulo,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.forStatus(sol.status),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14.0,
                              ),
                              child: Divider(
                                color: colorScheme.outlineVariant,
                                height: 1,
                              ),
                            ),
                            Column(
                              children: [
                                _DetailRow(
                                  label: 'Descripcion',
                                  value: sol.descripcion,
                                ),
                                if (sol.presupuestoMax != null)
                                  _DetailRow(
                                    label: 'Presupuesto max',
                                    value:
                                        '\$${sol.presupuestoMax!.toStringAsFixed(0)}',
                                  ),
                                if (sol.ubicacionTexto != null)
                                  _DetailRow(
                                    label: 'Ubicacion',
                                    value: sol.ubicacionTexto!,
                                  ),
                                if (sol.clienteNombre != null)
                                  _DetailRow(
                                    label: 'Cliente',
                                    value: sol.clienteNombre!,
                                  ),
                                if (sol.createdAt != null)
                                  _DetailRow(
                                    label: 'Creado',
                                    value: DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(sol.createdAt!),
                                  ),
                              ],
                            ),
                            if (esOwner && sol.isAbierta) ...[
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: isMobileHead ? 52 : 54,
                                child: OutlinedButton(
                                  onPressed: _cerrarSolicitud,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.error,
                                    side: BorderSide(
                                      color: colorScheme.error,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Radii.md),
                                    ),
                                  ).copyWith(
                                    overlayColor: WidgetStateProperty.all(
                                      colorScheme.error.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: const Text(
                                    '✕ Cerrar Solicitud',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (esOwner) ...[
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(Radii.pill),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Propuestas recibidas',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_propuestas.length >= 2)
                                    TextButton.icon(
                                      onPressed: _abrirComparativa,
                                      icon: const Icon(
                                        Icons.compare_arrows_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Comparar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_propuestas.isEmpty)
                                EmptyStateWidget(
                                  compact: true,
                                  icon: Icons.inbox_outlined,
                                  title: 'Aún no has recibido propuestas',
                                  description: 'Los proveedores verán tu solicitud y enviarán sus propuestas pronto.',
                                )
                              else
                                ListView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      _propuestas.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _propuestas.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: _loadingMore
                                              ? const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      );
                                    }
                                    return _PropuestaCard(
                                      propuesta: _propuestas[index],
                                      onAceptar: () =>
                                          _aceptarPropuesta(_propuestas[index]),
                                      onRechazar: () => _rechazarPropuesta(
                                        _propuestas[index],
                                      ),
                                    );
                                  },
                                ),
                            ] else ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: () => context.push(
                                    '/solicitud/${widget.solicitudId}/proponer',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(Radii.md),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Enviar Propuesta'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isDesktop)
                    const SizedBox(width: 22)
                  else
                    const SizedBox(height: 22),
                  SizedBox(
                    width: isDesktop ? 330 : double.infinity,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen rápido',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SidebarInfoBox(title: 'Estado', value: sol.status),
                            const SizedBox(height: 12),
                            _SidebarInfoBox(
                              title: 'Presupuesto',
                              value: sol.presupuestoMax != null
                                  ? '\$${sol.presupuestoMax!.toStringAsFixed(0)}'
                                  : 'Sin presupuesto',
                            ),
                            const SizedBox(height: 12),
                            _SidebarInfoBox(
                              title: 'Ubicación',
                              value: sol.ubicacionTexto ?? 'Sin especificar',
                            ),
                            if (sol.categoriaNombre != null) ...[
                              const SizedBox(height: 12),
                              _SidebarInfoBox(
                                title: 'Categoría',
                                value: sol.categoriaNombre!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          if (isMobile)
            const SizedBox(height: 4)
          else
            const SizedBox(width: 14),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                height: 1.55,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropuestaCard extends StatelessWidget {
  final Propuesta propuesta;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _PropuestaCard({
    required this.propuesta,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.2 : 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                      Text(
                        propuesta.proveedorNombre ?? 'Proveedor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            propuesta.tiempoEstimado,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${propuesta.precio.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge.forStatus(propuesta.status),
                  ],
                ),
              ],
            ),
            if (propuesta.descripcion.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                propuesta.descripcion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            if (propuesta.isPendiente) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onAceptar,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.tertiary,
                        foregroundColor: colorScheme.onTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onRechazar,
                      child: const Text(
                        'Rechazar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _SidebarInfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
