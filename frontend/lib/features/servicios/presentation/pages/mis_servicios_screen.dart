import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';

class MisServiciosScreen extends StatefulWidget {
  const MisServiciosScreen({super.key});

  @override
  State<MisServiciosScreen> createState() => _MisServiciosScreenState();
}

class _MisServiciosScreenState extends State<MisServiciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().usuario?.id;
      context.read<ServiciosProvider>().cargarServicios(proveedorId: uid);
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

  void _intentarCrearServicio(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final docEstado = auth.usuario?.docEstado ?? 'none';
    
    if (docEstado != 'approved') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verificación requerida'),
          content: const Text(
            'Por seguridad de la comunidad, debes verificar tu identidad antes de publicar un servicio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ProButton(
              label: 'Verificar ahora',
              compact: true,
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/seguridad/identidad');
              },
            ),
          ],
        ),
      );
      return;
    }
    
    context.push('/crear-servicio').then((_) {
      if (!context.mounted) return;
      final uid = auth.usuario?.id;
      context.read<ServiciosProvider>().cargarServicios(proveedorId: uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final prov = context.watch<ServiciosProvider>();

    int crossCount = 3;
    if (Breakpoints.isMobile(context)) {
      crossCount = 1;
    } else if (MediaQuery.sizeOf(context).width < Breakpoints.tablet) {
      crossCount = 2;
    }

    return ProScaffold(
      showAppBar: false,
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = context.read<AuthProvider>().usuario?.id;
          await prov.cargarServicios(proveedorId: uid);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacing.xl2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    direction: Breakpoints.isMobile(context) ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: Breakpoints.isMobile(context)
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: Breakpoints.isMobile(context) ? 0 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis servicios',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: ProColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Revisa tus ofertas activas y administra tus publicaciones en el marketplace.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: ProColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!Breakpoints.isMobile(context) && prov.servicios.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        ProButton(
                          label: 'Crear nuevo servicio',
                          icon: Icons.add_rounded,
                          compact: true,
                          onPressed: () => _intentarCrearServicio(context),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacing.xl2),

                  if (prov.loading)
                    SkeletonServicioGrid(
                      crossCount: crossCount,
                      mainAxisExtent: 400,
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
                  else if (prov.servicios.isEmpty)
                    AppEmptyState(
                      icon: Icons.construction_outlined,
                      title: 'Sin servicios publicados',
                      description:
                          'Crea tu primer servicio para empezar a recibir solicitudes de clientes.',
                      actionLabel: 'Crear servicio',
                      onAction: () => _intentarCrearServicio(context),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 400,
                      ),
                      itemCount: prov.servicios.length,
                      itemBuilder: (context, i) {
                        final srv = prov.servicios[i];
                        final catIcono = prov.categoriasRaiz
                            .where((c) => c.id == srv.categoriaId)
                            .map((c) => c.icono)
                            .firstOrNull;
                        return _ServiceCard(
                          servicio: srv,
                          categoriaIcono: catIcono,
                          formatClp: _formatClp,
                          onEditar: () async {
                            await context.push('/editar-servicio/${srv.id}');
                            if (!context.mounted) return;
                            final uid = context
                                .read<AuthProvider>()
                                .usuario
                                ?.id;
                            context.read<ServiciosProvider>().cargarServicios(
                              proveedorId: uid,
                            );
                          },
                          onToggle: () => prov.togglePausar(srv.id),
                          onEliminar: () =>
                              _confirmarEliminar(context, prov, srv),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Oculto si la lista está vacía: el empty state ya trae su propio CTA
      // "Crear servicio" en el mismo lugar, y el FAB flotaba encima
      // (dos botones superpuestos, uno semitransparente sobre el otro).
      floatingActionButton: Breakpoints.isMobile(context) && prov.servicios.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/crear-servicio');
                if (!context.mounted) return;
                final uid = context.read<AuthProvider>().usuario?.id;
                context.read<ServiciosProvider>().cargarServicios(
                  proveedorId: uid,
                );
              },
              backgroundColor: ProColors.accent,
              foregroundColor: ProColors.onAccent,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Publicar Servicio',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              elevation: 6,
            )
          : null,
    );
  }

  void _confirmarEliminar(
    BuildContext ctx,
    ServiciosProvider prov,
    Servicio srv,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        title: const Text(
          'Eliminar servicio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('¿Estás seguro de eliminar "${srv.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ProButton(
            label: 'Eliminar',
            isDanger: true,
            compact: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await prov.eliminarServicio(srv.id);
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Servicio servicio;
  final String? categoriaIcono;
  final String Function(double) formatClp;
  final VoidCallback onEditar;
  final VoidCallback onToggle;
  final VoidCallback onEliminar;

  const _ServiceCard({
    required this.servicio,
    this.categoriaIcono,
    required this.formatClp,
    required this.onEditar,
    required this.onToggle,
    required this.onEliminar,
  });

  Widget _defaultBanner() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [ProColors.accent.withValues(alpha: 0.15), ProColors.surfaceHi],
      ),
    ),
    child: Center(
      child: categoriaIcono != null && categoriaIcono!.isNotEmpty
          ? Text(categoriaIcono!, style: const TextStyle())
          : const Icon(
              Icons.build_circle_outlined,
              size: 40,
              color: ProColors.accent,
            ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final srv = servicio;
    final isActivo = srv.isActivo;
    String precioStr;
    if (srv.precioMin == null) {
      precioStr = 'A convenir';
    } else if (srv.precioMax == 1.0) {
      precioStr = '${formatClp(srv.precioMin!)}/hora';
    } else if (srv.precioMax == 2.0) {
      precioStr = '${formatClp(srv.precioMin!)}/servicio';
    } else {
      precioStr = 'Desde ${formatClp(srv.precioMin!)}';
    }

    final theme = Theme.of(context);
    return ProCard(
      onTap: null,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: srv.fotosList.isNotEmpty
                      ? Image.network(
                          srv.fotosList.first,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => _defaultBanner(),
                        )
                      : _defaultBanner(),
                ),
                Positioned(
                  top: 12,
                  right: -24,
                  child: Transform.rotate(
                    angle: 0.785398, // 45 degrees
                    child: Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: isActivo ? ProColors.success : ProColors.textMuted,
                      child: Text(
                        isActivo ? 'ACTIVO' : 'PAUSADO',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ProColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  srv.categoriaNombre ?? '—',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ProColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: ProColors.amber,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    srv.proveedorRating != null
                        ? srv.proveedorRating!.toStringAsFixed(1)
                        : 'Nuevo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ProColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            srv.titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ProColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              srv.descripcion.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ProColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                precioStr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ProColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Editar servicio',
                  child: ProButton(
                    label: 'Editar',
                    onPressed: onEditar,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: isActivo ? 'Pausar servicio' : 'Activar servicio',
                  child: FilledButton(
                    onPressed: onToggle,
                    style: FilledButton.styleFrom(
                      backgroundColor: isActivo
                          ? ProColors.amber
                          : ProColors.success,
                      foregroundColor: ProColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: Text(
                      isActivo ? 'Pausar' : 'Activar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (v) {
                  if (v == 'eliminar') onEliminar();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: ProColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar',
                          style: TextStyle(
                            color: ProColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: ProColors.border),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: ProColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
