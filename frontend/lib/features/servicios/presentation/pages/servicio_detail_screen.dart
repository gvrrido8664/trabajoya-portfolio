import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/servicios/data/datasources/servicios_remote_datasource.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/usuarios/data/models/certificacion_model.dart';
import 'package:trabajoya_app/features/usuarios/data/datasources/usuarios_remote_datasource.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/premium_badge.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';

class ServicioDetailScreen extends StatefulWidget {
  final String servicioId;

  const ServicioDetailScreen({super.key, required this.servicioId});

  @override
  State<ServicioDetailScreen> createState() => _ServicioDetailScreenState();
}

class _ServicioDetailScreenState extends State<ServicioDetailScreen> {
  final _service = ServiciosService();
  final _usuariosService = UsuariosService();
  Servicio? _servicio;
  List<Certificacion> _certificaciones = [];
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
      final s = await _service.getServicio(widget.servicioId);
      final certs = await _usuariosService.getCertificacionesUsuario(s.proveedorId);
      if (mounted) {
        setState(() {
          _servicio = s;
          _certificaciones = certs.where((c) => c.estado == 'approved').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = formatError(e);
          _loading = false;
        });
      }
    }
  }

  String _formatPrecio(Servicio s) {
    if (s.precioMin == null) return 'A convenir';
    final monto = _fmt(s.precioMin!);
    if (s.precioMax == 1.0) return '\$$monto / hora';
    if (s.precioMax == 2.0) return '\$$monto / servicio';
    return '\$$monto';
  }

  void _intentarSolicitar(BuildContext context, String servicioId) {
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    
    if (!isLoggedIn) {
      context.push('/login');
      return;
    }

    final emailVerificado = auth.usuario?.emailVerificado ?? false;
    if (!emailVerificado) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Verificación requerida',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Debes verificar tu correo electrónico antes de poder solicitar un servicio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  
                  height: 1.5,
                ),
              ),
              const SizedBox(height: Spacing.xl2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/perfil');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ir a mi perfil',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600, ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    context.push('/solicitar/$servicioId');
  }

  String _fmt(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DelayedLoader(
        loading: _loading,
        loader: const SkeletonDetail(),
        child: _buildContent(context, isMobile),
      ),
      bottomNavigationBar: _loading || _error != null || _servicio == null
          ? null
          : _buildBottomNav(context, isMobile),
    );
  }

  Widget _buildContent(BuildContext context, bool isMobile) {
    if (_error != null || _servicio == null) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el servicio',
          message: _error ?? 'El servicio no existe o fue eliminado.',
          actionLabel: 'Reintentar',
          onAction: _cargar,
          variant: EmptyStateVariant.error,
        ),
      );
    }

    final s = _servicio!;
    final iniciales = (s.proveedorNombre ?? '?')
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
        .join();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.xl2),
      child: _centered(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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

                // Hero card
                Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  elevation: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner
                      SizedBox(
                        height: isMobile ? 200 : 260,
                        width: double.infinity,
                        child: s.fotosList.isNotEmpty
                            ? Image.network(
                                s.fotosList.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, e, _) => _heroBanner(s),
                              )
                            : _heroBanner(s),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.categoriaNombre != null)
                              Text(
                                '${s.categoriaIcono ?? ''} ${s.categoriaNombre!.toUpperCase()}',
                                style: const TextStyle(
                                  
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              s.titulo,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatPrecio(s),
                              style: const TextStyle(
                                
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MetaPill(
                                  label:
                                      '📍 Cobertura: ${s.radioCoberturaKm} km',
                                ),
                                if (s.direccionTexto != null &&
                                    s.direccionTexto!.isNotEmpty)
                                  _MetaPill(label: '🏠 ${s.direccionTexto!}'),
                                if (s.categoriaNombre != null)
                                  _MetaPill(
                                    label:
                                        '${s.categoriaIcono ?? '🧩'} ${s.categoriaNombre!}',
                                  ),
                                if (s.subcategoriaNombre != null)
                                  _MetaPill(
                                    label:
                                        '${s.subcategoriaIcono ?? '•'} ${s.subcategoriaNombre!}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl2),

                // Card principal (ancho completo)
                Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CliSectionHeader(title: 'Descripción'),
                        const SizedBox(height: Spacing.md),
                        Text(
                          s.descripcion,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.7,
                            
                          ),
                        ),
                        const SizedBox(height: Spacing.xl),

                        const CliSectionHeader(title: 'Proveedor'),
                        const SizedBox(height: Spacing.md),
                        CliCard(
                          padding: const EdgeInsets.all(Spacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
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
                              const SizedBox(width: Spacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        s.proveedorNombre ?? 'Proveedor',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      if (s.proveedorEsPremium) ...[
                                        const SizedBox(width: 6),
                                        const PremiumBadge(size: 16),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    s.proveedorRating != null &&
                                            s.proveedorRating! > 0
                                        ? '★ ${s.proveedorRating!.toStringAsFixed(1)}'
                                        : '★ Nuevo',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                      
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_certificaciones.isNotEmpty) ...[
                          const SizedBox(height: Spacing.xl),
                          Text(
                            'Certificaciones',
                            style: TextStyle(
                              
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacing.sm),
                          ..._certificaciones.map((c) => Container(
                                margin: const EdgeInsets.only(top: Spacing.sm),
                                padding: const EdgeInsets.all(Spacing.md),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest, // Light blue background
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  border: Border.all(color: AppColors.primaryLight),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: Spacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.titulo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                          Text(
                                            c.institucion,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        const SizedBox(height: Spacing.xl),

                        const CliSectionHeader(title: 'Reseñas'),
                        const SizedBox(height: Spacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Spacing.xl),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(Radii.lg),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.star_border_rounded,
                                size: 36,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
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
                        ),
                        const SizedBox(height: 22),

                        // Botón contratar (solo en desktop/tablet)
                        if (!isMobile) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => _intentarSolicitar(context, s.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '🤝 Contratar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  
                                ),
                              ),
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

  Widget _buildBottomNav(BuildContext context, bool isMobile) {
    final s = _servicio!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : Spacing.xl2,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio estimado:',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPrecio(s),
                          style: TextStyle(
                            color: AppColors.primary,
                            
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    height: isMobile ? 50 : 54,
                    child: ElevatedButton(
                      onPressed: () => _intentarSolicitar(context, s.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 40,
                        ),
                      ),
                      child: Text(
                        '🤝 Contratar Ahora',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBanner(Servicio s) {
    final icono = s.subcategoriaIcono ?? s.categoriaIcono;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, Theme.of(context).colorScheme.surfaceContainerHigh, Theme.of(context).colorScheme.surface],
        ),
      ),
      child: Center(
        child: icono != null && icono.isNotEmpty
            ? Text(icono, style: const TextStyle(fontSize: 72))
            : const Icon(
                Icons.build_circle_outlined,
                size: 64,
                color: AppColors.primary,
              ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
