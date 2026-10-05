import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/solicitudes/presentation/providers/solicitudes_provider.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';
import 'package:trabajoya_app/shared/widgets/corner_border_container.dart';
import 'package:trabajoya_app/utils/colors.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  String _filtro = 'Todas';
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudesProvider>().cargarMisSolicitudes();
    });
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
      final provider = context.read<SolicitudesProvider>();
      if (provider.hasMore && !provider.loadingMore) {
        provider.cargarMasMisSolicitudes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SolicitudesProvider>();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 650;

    final allList = prov.misSolicitudes;
    final todasCount = allList.length;
    final abiertasCount = allList.where((s) => s.status == 'ABIERTA').length;
    final enProgresoCount = allList
        .where((s) => s.status == 'EN_PROGRESO' || s.status == 'EN_EVALUACION')
        .length;
    final cerradasCount = allList.where((s) => s.status == 'CERRADA').length;

    List<Solicitud> solicitudes = allList;
    if (_filtro == 'Abiertas') {
      solicitudes = allList.where((s) => s.status == 'ABIERTA').toList();
    } else if (_filtro == 'En progreso') {
      solicitudes = allList
          .where((s) => s.status == 'EN_PROGRESO' || s.status == 'EN_EVALUACION')
          .toList();
    } else if (_filtro == 'Cerradas') {
      solicitudes = allList.where((s) => s.status == 'CERRADA').toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => prov.cargarMisSolicitudes(),
        child: DelayedLoader(
          loading: prov.loading,
          loader: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? Spacing.lg : Spacing.xl2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShimmerContainer(width: 180, height: 28),
                        ShimmerContainer(
                          width: 140,
                          height: 44,
                          borderRadius: BorderRadius.circular(Radii.md).topLeft.x,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl2),
                    Row(
                      children: [
                        ShimmerContainer(width: 80, height: 36, borderRadius: Radii.pill),
                        const SizedBox(width: 8),
                        ShimmerContainer(width: 90, height: 36, borderRadius: Radii.pill),
                        const SizedBox(width: 8),
                        ShimmerContainer(width: 100, height: 36, borderRadius: Radii.pill),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    const SkeletonListLoader(itemCount: 4),
                  ],
                ),
              ),
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? Spacing.lg : Spacing.xl2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Mis solicitudes',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isMobile ? 22 : 28,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => context.push('/crear-solicitud'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rust,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.xl,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                            ),
                            child: const Text(
                              '+ Nueva solicitud',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          label: 'Abiertas',
                          count: abiertasCount,
                          isSelected: _filtro == 'Abiertas',
                          onTap: () => setState(() => _filtro = 'Abiertas'),
                        ),
                        _FilterChipItem(
                          label: 'En progreso',
                          count: enProgresoCount,
                          isSelected: _filtro == 'En progreso',
                          onTap: () => setState(() => _filtro = 'En progreso'),
                        ),
                        _FilterChipItem(
                          label: 'Cerradas',
                          count: cerradasCount,
                          isSelected: _filtro == 'Cerradas',
                          onTap: () => setState(() => _filtro = 'Cerradas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),

                    if (prov.error != null)
                      AppEmptyState(
                        icon: Icons.cloud_off,
                        title: 'No pudimos cargar tus solicitudes',
                        description: prov.error!,
                        actionLabel: 'Reintentar',
                        onAction: () => prov.cargarMisSolicitudes(),
                        variant: EmptyStateVariant.error,
                      )
                    else if (solicitudes.isEmpty)
                      AppEmptyState(
                        icon: Icons.assignment_add,
                        title: _filtro == 'Todas'
                            ? 'Empieza tu primer proyecto'
                            : 'Sin resultados para "$_filtro"',
                        description: _filtro == 'Todas'
                            ? 'Publica lo que necesitas y recibe presupuestos de profesionales verificados en tu zona.'
                            : 'Actualmente no tienes solicitudes en estado $_filtro. Cambia el filtro para ver otras solicitudes o crea una nueva.',
                        actionLabel: _filtro == 'Todas' ? 'Explorar servicios' : 'Ver todas',
                        onAction: _filtro == 'Todas'
                            ? () => context.push('/cliente/buscar')
                            : () => setState(() => _filtro = 'Todas'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: solicitudes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacing.md),
                        itemBuilder: (context, index) {
                          final sol = solicitudes[index];
                          return _RequestListItem(solicitud: sol);
                        },
                      ),
                    if (prov.loadingMore)
                      const Padding(
                        padding: EdgeInsets.only(top: Spacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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

class _RequestListItem extends StatelessWidget {
  final Solicitud solicitud;

  const _RequestListItem({required this.solicitud});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'hace ${diff.inMinutes} h';
    } else if (diff.inHours < 24) {
      return 'hace ${diff.inHours} h';
    } else if (diff.inDays < 7) {
      return 'hace ${diff.inDays} d';
    } else {
      return 'el ${dt.day}/${dt.month}';
    }
  }

  Widget _buildStatusBadge() {
    final status = solicitud.status.toUpperCase();
    Color bg;
    Color fg;
    String label;

    if (status == 'ABIERTA') {
      bg = AppColors.blueprintTint;
      fg = AppColors.blueprint;
      label = 'ABIERTA';
    } else if (status == 'EN_PROGRESO' || status == 'EN_EVALUACION') {
      bg = AppColors.amberTint;
      fg = AppColors.amber;
      label = 'EN PROGRESO';
    } else {
      bg = AppColors.border;
      fg = AppColors.inkSoft;
      label = 'CERRADA';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = solicitud.categoriaNombre ?? 'General';
    final loc = solicitud.ubicacionTexto ?? 'Santiago';
    final timeStr = solicitud.isAbierta
        ? 'Publicada ${_timeAgo(solicitud.createdAt)}'
        : 'Completada el ${solicitud.createdAt?.day ?? 1}/${solicitud.createdAt?.month ?? 1}';
    final subline = '$cat  ·  $loc  ·  $timeStr';

    return CornerBorderContainer(
      color: AppColors.border,
      backgroundColor: Colors.white,
      strokeWidth: 2,
      padding: const EdgeInsets.all(Spacing.lg),
      child: GestureDetector(
        onTap: () => context.push('/solicitud/${solicitud.id}'),
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      solicitud.titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subline,
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusBadge(),
                  if (solicitud.isAbierta) ...[
                    const SizedBox(width: Spacing.md),
                    Text(
                      '${solicitud.propuestasCount} propuestas',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(width: Spacing.md),
                  TextButton(
                    onPressed: () => context.push('/solicitud/${solicitud.id}'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rust,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Ver solicitud →',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

