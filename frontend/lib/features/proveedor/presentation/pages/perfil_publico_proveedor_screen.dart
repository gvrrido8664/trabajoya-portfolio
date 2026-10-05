import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/resenas/data/datasources/resenas_remote_datasource.dart';
import 'package:trabajoya_app/features/resenas/data/models/resena_model.dart';
import 'package:trabajoya_app/features/servicios/data/datasources/servicios_remote_datasource.dart';
import 'package:trabajoya_app/features/servicios/data/models/proveedor_top_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/premium_badge.dart';
import 'package:trabajoya_app/shared/widgets/servicio_card.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';
import 'package:trabajoya_app/utils/colors.dart';

/// Perfil público de un proveedor (visto por un cliente): rating, bio,
/// servicios activos y reseñas recibidas. Distinto de `PerfilProveedorScreen`,
/// que es el dashboard privado del proveedor logueado sobre sí mismo.
class PerfilPublicoProveedorScreen extends StatefulWidget {
  final String proveedorId;

  const PerfilPublicoProveedorScreen({super.key, required this.proveedorId});

  @override
  State<PerfilPublicoProveedorScreen> createState() =>
      _PerfilPublicoProveedorScreenState();
}

class _PerfilPublicoProveedorScreenState
    extends State<PerfilPublicoProveedorScreen> {
  final _apiClient = ApiClient();
  final _serviciosService = ServiciosService();
  final _resenasService = ResenasService();

  ProveedorTop? _proveedor;
  List<Servicio> _servicios = [];
  List<Resena> _resenas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiClient.get('/proveedores/${widget.proveedorId}'),
        _serviciosService.getServicios(proveedorId: widget.proveedorId),
        _resenasService.getResenasUsuario(widget.proveedorId, limit: 20),
      ]);
      if (!mounted) return;
      setState(() {
        _proveedor = ProveedorTop.fromJson(results[0] as Map<String, dynamic>);
        _servicios = results[1] as List<Servicio>;
        _resenas = results[2] as List<Resena>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatError(e);
        _loading = false;
      });
    }
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DelayedLoader(
        loading: _loading,
        loader: const SkeletonDetail(),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_error != null || _proveedor == null) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el perfil',
          message: _error ?? 'El proveedor no existe o ya no está activo.',
          actionLabel: 'Reintentar',
          onAction: _cargar,
          variant: EmptyStateVariant.error,
        ),
      );
    }

    final p = _proveedor!;
    final iniciales = p.nombre
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
        .join();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl2),
      child: _centered(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                elevation: 0,
              ),
              child: const Text(
                '← Volver',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: Spacing.xl2),

            CliCard(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight,
                    ),
                    child: Center(
                      child: Text(
                        iniciales,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.nombre,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            if (p.proveedorEsPremium) ...[
                              const SizedBox(width: 8),
                              const PremiumBadge(size: 18),
                            ],
                            if (p.identidadVerificada) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (p.avgRating ?? 0) > 0
                              ? '★ ${p.avgRating!.toStringAsFixed(1)}  ·  ${p.totalContratos} contratos'
                              : 'Nuevo en TrabajoYa  ·  ${p.totalContratos} contratos',
                          style: const TextStyle(
                            color: ProColors.amber,
                            fontWeight: FontWeight.w700,
                            
                          ),
                        ),
                        if ((p.bio ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            p.bio!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl2),

            CliSectionHeader(title: 'Servicios (${_servicios.length})'),
            const SizedBox(height: Spacing.md),
            if (_servicios.isEmpty)
              EmptyStateWidget(
                icon: Icons.build_outlined,
                title: 'Sin servicios publicados',
                message: 'Este proveedor todavía no publicó servicios.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 340,
                      mainAxisExtent: 220,
                      crossAxisSpacing: Spacing.md,
                      mainAxisSpacing: Spacing.md,
                    ),
                itemCount: _servicios.length,
                itemBuilder: (context, i) => ServicioCardShared(
                  servicio: _servicios[i],
                  onTap: () => context.push('/servicio/${_servicios[i].id}'),
                ),
              ),
            const SizedBox(height: Spacing.xl2),

            CliSectionHeader(title: 'Reseñas (${_resenas.length})'),
            const SizedBox(height: Spacing.md),
            if (_resenas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.xl),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      size: 36,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Todavía no hay reseñas para este proveedor.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._resenas.map(
                (r) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: Spacing.sm),
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < r.puntuacion ? Icons.star : Icons.star_border,
                            size: 16,
                            color: ProColors.amber,
                          ),
                        ),
                      ),
                      if ((r.comentario ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          r.comentario!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
