import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';
import 'package:trabajoya_app/shared/widgets/premium_badge.dart';
import 'package:trabajoya_app/shared/widgets/skeleton_loader.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/servicios/data/models/proveedor_top_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/widgets/corner_border_container.dart';

IconData _getIconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('gasfiter') || n.contains('plom')) return Icons.plumbing_rounded;
  if (n.contains('electri')) return Icons.electrical_services_rounded;
  if (n.contains('limp') || n.contains('aseo')) return Icons.cleaning_services_rounded;
  if (n.contains('pint')) return Icons.format_paint_rounded;
  if (n.contains('carpint') || n.contains('mueble')) return Icons.handyman_rounded;
  if (n.contains('clase') || n.contains('prof') || n.contains('educ')) return Icons.school_rounded;
  if (n.contains('jardin')) return Icons.yard_rounded;
  if (n.contains('transp') || n.contains('flete') || n.contains('mudan')) return Icons.local_shipping_rounded;
  if (n.contains('comput') || n.contains('tech') || n.contains('inform')) return Icons.computer_rounded;
  if (n.contains('cuid') || n.contains('niñ')) return Icons.child_care_rounded;
  if (n.contains('mascot') || n.contains('perro')) return Icons.pets_rounded;
  if (n.contains('arte') || n.contains('diseñ')) return Icons.palette_rounded;
  if (n.contains('asesor') || n.contains('consult')) return Icons.cases_rounded;
  if (n.contains('auto') || n.contains('mecani')) return Icons.directions_car_rounded;
  if (n.contains('bellez') || n.contains('cuidad')) return Icons.spa_rounded;
  if (n.contains('deport') || n.contains('fitn')) return Icons.fitness_center_rounded;
  return Icons.build_circle_outlined;
}

class ClienteLandingScreen extends StatefulWidget {
  const ClienteLandingScreen({super.key});

  @override
  State<ClienteLandingScreen> createState() => _ClienteLandingScreenState();
}

class _ClienteLandingScreenState extends State<ClienteLandingScreen> {
  final _searchCtrl = TextEditingController();
  final _solicitudesService = SolicitudesService();
  final _apiClient = ApiClient();
  List<Solicitud> _misSolicitudes = [];
  List<ProveedorTop> _topProveedores = [];
  bool _loadingSolicitudes = true;
  bool _loadingTopProveedores = true;
  String _lastQuery = '';
  final List<String> _recentSearches = ['Pintor', 'Electricista', 'Plomero'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      context.read<ServiciosProvider>().cargarCategorias();
      context.read<ServiciosProvider>().cargarServicios();
      if (isLoggedIn) {
        _cargarSolicitudes();
      } else {
        setState(() {
          _loadingSolicitudes = false;
        });
      }
      _cargarTopProveedores();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    if (query != _lastQuery) {
      _lastQuery = query;
      _searchCtrl.text = query;
      Future.microtask(() {
        if (mounted) {
          context.read<ServiciosProvider>().cargarServicios(
            q: query.isEmpty ? null : query,
          );
        }
      });
    }
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _loadingSolicitudes = true);
    try {
      final data = await _solicitudesService.getMisSolicitudes(limit: 2);
      if (mounted) setState(() => _misSolicitudes = data);
    } catch (_) {}
    if (mounted) setState(() => _loadingSolicitudes = false);
  }

  Future<void> _cargarTopProveedores() async {
    setState(() => _loadingTopProveedores = true);
    try {
      final response = await _apiClient.get(
        '/proveedores/top',
        queryParams: {'limit': '4'},
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      if (mounted) {
        setState(
          () => _topProveedores = data
              .map((e) => ProveedorTop.fromJson(e))
              .toList(),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingTopProveedores = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _executeSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
      final route = isLoggedIn ? '/cliente/buscar' : '/buscar';
      context.go('$route?q=$query');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 1100;
    final isTablet = MediaQuery.of(context).size.width > 700;
    final query = GoRouterState.of(context).uri.queryParameters['q'] ?? '';
    final isMobile = MediaQuery.of(context).size.width < 600;
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    final sections = [
      if (!isLoggedIn)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              Text(
                'Búsqueda de servicios',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      const _VerificationBanner(),
      _buildHeroSection(theme, isLargeScreen, isTablet),
      const SizedBox(height: Spacing.xl3),
      CliSectionHeader(
        title: 'Categorías',
        actionLabel: 'Ver todas',
        onAction: () {
          if (isLoggedIn) {
            context.push('/cliente/categorias');
          } else {
            context.push('/categorias');
          }
        },
      ),
      const SizedBox(height: Spacing.md),
      const _CategoryGrid(),
      const SizedBox(height: Spacing.xl3),
      const CliSectionHeader(title: 'Servicios destacados cerca de ti', actionLabel: 'Ver todos →'),
      const SizedBox(height: Spacing.md),
      _ServiceLayoutGrid(query: query),
      const SizedBox(height: Spacing.xl3),
      const CliSectionHeader(title: 'Proveedores destacados', actionLabel: 'Ver todos →'),
      const SizedBox(height: Spacing.md),
      _loadingTopProveedores
          ? Shimmer.fromColors(
              baseColor: theme.brightness == Brightness.dark
                  ? Colors.white10
                  : AppColors.border,
              highlightColor: theme.brightness == Brightness.dark
                  ? Colors.white24
                  : AppColors.background,
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: 4,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: Spacing.md),
                  itemBuilder: (_, __) => Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                ),
              ),
            )
          : _topProveedores.isEmpty
          ? Text(
              'Todavía no hay proveedores destacados en tu zona.',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            )
          : _ProveedoresDestacadosGrid(proveedores: _topProveedores),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.builder(
        padding: EdgeInsets.all(isMobile ? Spacing.lg : Spacing.xl2),
        itemCount: sections.length,
        itemBuilder: (context, index) => sections[index],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, bool isLargeScreen, bool isTablet) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.usuario?.nombreCompleto.split(' ').first.toUpperCase() ?? 'INVITADO';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.sidebarBottom,
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -100,
            top: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.rust.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? Spacing.xl : Spacing.xl2),
            child: Flex(
              direction: isLargeScreen ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isLargeScreen
                    ? Expanded(
                        flex: 135,
                        child: _buildHeroText(isMobile, userName, isTablet, _searchCtrl),
                      )
                    : _buildHeroText(isMobile, userName, isTablet, _searchCtrl),
                if (isLargeScreen)
                  const SizedBox(width: Spacing.xl3)
                else
                  const SizedBox(height: Spacing.xl2),
                isLargeScreen
                    ? Expanded(
                        flex: 85,
                        child: _buildHeroPanel(theme),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: _buildHeroPanel(theme),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText(bool isMobile, String userName, bool isTablet, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.square, size: 8, color: AppColors.rust),
            const SizedBox(width: 8),
            Text(
              'HOLA, $userName',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '¿Qué necesitas resolver hoy?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 28 : 36,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Publica una solicitud o busca directo entre los profesionales verificados de tu zona.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            height: 1.5,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: Spacing.xl2),
        _buildSearchBar(isTablet),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            _HeroChip(
              label: 'Gasfiter',
              iconData: Icons.plumbing,
              onTap: () => controller.text = 'Gasfiter',
            ),
            _HeroChip(
              label: 'Electricista',
              iconData: Icons.electrical_services,
              onTap: () => controller.text = 'Electricista',
            ),
            _HeroChip(
              label: 'Limpieza',
              iconData: Icons.cleaning_services,
              onTap: () => controller.text = 'Limpieza',
            ),
            _HeroChip(
              label: 'Clases',
              iconData: Icons.school,
              onTap: () => controller.text = 'Clases',
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }

  Widget _buildHeroPanel(ThemeData theme) {
    return context.watch<AuthProvider>().isLoggedIn
        ? _buildSolicitudesPanel(theme)
        : _buildRegisterCTA(theme);
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _executeSearch(),
              decoration: const InputDecoration(
                hintText: 'Ej: electricista para instalar 3 enchufes',
                hintStyle: TextStyle(color: Colors.black54),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _executeSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rust,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudesPanel(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 4,
              color: AppColors.sidebarBottom,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solicitudes activas',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lo que está pasando ahora',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    DelayedLoader(
                      loading: _loadingSolicitudes,
                      loader: const Column(
                        children: [
                          Row(
                            children: [
                              ShimmerContainer(width: 32, height: 32, borderRadius: 16),
                              SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerContainer(width: 120, height: 14),
                                    SizedBox(height: 6),
                                    ShimmerContainer(width: 80, height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Spacing.md),
                          Row(
                            children: [
                              ShimmerContainer(width: 32, height: 32, borderRadius: 16),
                              SizedBox(width: Spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerContainer(width: 140, height: 14),
                                    SizedBox(height: 6),
                                    ShimmerContainer(width: 60, height: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_misSolicitudes.isEmpty)
                            AppEmptyState(
                              icon: Icons.explore_outlined,
                              title: 'Nada por aquí',
                              description:
                                  'Aún no tienes solicitudes activas. Publica lo que necesitas hoy.',
                              compact: true,
                              actionLabel: 'Crear solicitud',
                              onAction: () => context.push('/crear-solicitud'),
                            )
                          else
                            ..._misSolicitudes.take(2).map((sol) {
                              final precio = sol.presupuestoMax != null
                                  ? 'CLP ${_formatClp(sol.presupuestoMax!)}'
                                  : 'A convenir';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Spacing.sm),
                                child: _LiveRequestPanel(
                                  title: sol.titulo,
                                  meta: sol.ubicacionTexto ?? sol.categoriaNombre ?? '',
                                  price: precio,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/cliente/mis-solicitudes'),
                        child: Text(
                          'Ver mis solicitudes →',
                          style: TextStyle(
                            color: AppColors.rust,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCTA(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 4,
              color: AppColors.sidebarBottom,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, color: AppColors.rust, size: 32),
                    const SizedBox(height: Spacing.sm),
                    const Text(
                      'Únete a TrabajoYa',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    const Text(
                      'Regístrate gratis para publicar tus necesidades, contactar profesionales y comparar presupuestos.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rust,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.md),
                          ),
                        ),
                        child: const Text(
                          'Registrarse gratis',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            color: AppColors.rust,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatClp(double monto) {
    final s = monto.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn || auth.usuario!.isVerified) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.warning),
          const SizedBox(width: Spacing.sm),
          const Expanded(
            child: Text(
              'Verifica tu email para activar tu cuenta',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final ok = await auth.resendVerification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Correo reenviado' : auth.error ?? 'Error',
                    ),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Reenviar',
              style: TextStyle(fontWeight: FontWeight.w700, ),
            ),
          ),
        ],
      ),
    );
  }
}


class _LiveRequestPanel extends StatelessWidget {
  final String title;
  final String meta;
  final String price;

  const _LiveRequestPanel({
    required this.title,
    required this.meta,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: AppColors.rust,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  Color _getCategoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('gasfiter')) return AppColors.blueprintTint;
    if (n.contains('electri')) return AppColors.amberTint;
    if (n.contains('limp')) return AppColors.verifiedTint;
    if (n.contains('pint')) return AppColors.rustTint;
    if (n.contains('carpint')) return AppColors.rustTint;
    if (n.contains('clase')) return AppColors.blueprintTint;
    if (n.contains('arte')) return AppColors.rustTint;
    if (n.contains('asesor')) return AppColors.blueprintTint;
    if (n.contains('auto')) return AppColors.amberTint;
    if (n.contains('bellez')) return AppColors.verifiedTint;
    if (n.contains('deport')) return AppColors.blueprintTint;
    return AppColors.background;
  }

  Color _getCategoryIconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('gasfiter')) return AppColors.blueprint;
    if (n.contains('electri')) return AppColors.amber;
    if (n.contains('limp')) return AppColors.verified;
    if (n.contains('pint')) return AppColors.rust;
    if (n.contains('carpint')) return AppColors.rust;
    if (n.contains('clase')) return AppColors.blueprint;
    if (n.contains('arte')) return AppColors.rust;
    if (n.contains('asesor')) return AppColors.blueprint;
    if (n.contains('auto')) return AppColors.amber;
    if (n.contains('bellez')) return AppColors.verified;
    if (n.contains('deport')) return AppColors.blueprint;
    return AppColors.inkSoft;
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ServiciosProvider>(context);
    final categorias = prov.categoriasRaiz.take(12).toList();

    if (prov.loading) {
      return Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : AppColors.border,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : AppColors.background,
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: Spacing.md),
            itemBuilder: (_, __) => Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: Spacing.md,
      runSpacing: Spacing.md,
      children: categorias.map((cat) {
        final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
        return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (isLoggedIn) {
                  context.go('/cliente/buscar?q=${cat.nombre}');
                } else {
                  context.go('/buscar?q=${cat.nombre}');
                }
              },
              child: Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(cat.nombre),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: (cat.icono != null && cat.icono!.trim().isNotEmpty)
                            ? Text(
                                cat.icono!,
                                style: const TextStyle(fontSize: 20),
                              )
                            : Icon(
                                _getIconForCategory(cat.nombre),
                                size: 20,
                                color: _getCategoryIconColor(cat.nombre),
                              ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      cat.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
      }).toList(),
    );
  }
}

class _ServiceLayoutGrid extends StatelessWidget {
  final String query;
  const _ServiceLayoutGrid({required this.query});

  static String _formatPrecio(Servicio srv) {
    if (srv.precioMin == null) return 'A convenir';
    if (srv.precioMax == 1.0) return 'CLP ${_fmt(srv.precioMin!)} / hora';
    if (srv.precioMax == 2.0) return 'CLP ${_fmt(srv.precioMin!)} / servicio';
    return 'Desde CLP ${_fmt(srv.precioMin!)}';
  }

  static String _fmt(double monto) {
    final s = monto.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ServiciosProvider>(context);

    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isLoggedIn;

    if (prov.loading) {
      return Shimmer.fromColors(
        baseColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white10
            : AppColors.border,
        highlightColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : AppColors.background,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: Spacing.lg,
            crossAxisSpacing: Spacing.lg,
            mainAxisExtent: 220,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
        ),
      );
    }

    final filteredServicios = prov.servicios.where((s) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      String clean(String str) {
        return str
            .toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ñ', 'n');
      }

      final cleanQ = clean(q);
      final cleanTitle = clean(s.titulo);
      final cleanDesc = clean(s.descripcion);
      final cleanCat = clean(s.categoriaNombre ?? '');
      return cleanTitle.contains(cleanQ) ||
          cleanDesc.contains(cleanQ) ||
          cleanCat.contains(cleanQ);
    }).toList();

    if (filteredServicios.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: query.isEmpty
            ? 'No hay servicios disponibles'
            : 'Sin resultados para "$query"',
        description: query.isEmpty
            ? 'Aún no existen servicios registrados en esta categoría.'
            : 'Prueba con otra palabra o categoría.',
      );
    }

    final items = filteredServicios.take(5).map((srv) {
      final rating = srv.proveedorRating;
      return <String, dynamic>{
        'id': srv.id,
        'title': srv.titulo,
        'type': srv.categoriaNombre ?? 'Servicio',
        'price': _formatPrecio(srv),
        'cat': srv.categoriaNombre ?? '',
        'rate': rating != null ? '${rating.toStringAsFixed(1)} ★' : 'Nuevo',
        'status': 'Disponible',
        'desc': srv.descripcion
            .replaceAll('\n', ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
        'provider': isLoggedIn
            ? (srv.proveedorNombre ?? 'Proveedor')
            : 'Profesional verificado',
        'es_premium': srv.proveedorEsPremium,
      };
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: Spacing.xl,
        crossAxisSpacing: Spacing.xl,
        mainAxisExtent: 160,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final isPremium = item['es_premium'] as bool? ?? false;
        
        final initial = item['provider']!.substring(0, 1).toUpperCase();
        
        return CornerBorderContainer(
          color: AppColors.border,
          backgroundColor: Colors.white,
          strokeWidth: 2,
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () {
              if (!isLoggedIn) {
                context.push('/register');
              } else if (item['id'] != null) {
                context.push('/servicio/${item['id']}');
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['type']!,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        item['price']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.rust,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const _DottedLine(color: AppColors.border),
                  const Spacer(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.ink,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['provider']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontSize: 13,
                                ),
                              ),
                              if (isPremium) ...[
                                const SizedBox(width: 4),
                                const PremiumBadge(size: 12),
                              ],
                            ],
                          ),
                          Text(
                            item['rate']! == 'Nuevo' ? 'Nuevo' : '${item['rate']} · Verificado',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DottedLine extends StatelessWidget {
  final Color color;
  const _DottedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DottedLinePainter(color: color),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    double dashWidth = 3, dashSpace = 3, startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProveedoresDestacadosGrid extends StatelessWidget {
  final List<ProveedorTop> proveedores;

  const _ProveedoresDestacadosGrid({required this.proveedores});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<AuthProvider>(context).isLoggedIn;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: proveedores.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, i) {
          final p = proveedores[i];
          final displayName = isLoggedIn ? p.nombre : 'Pro. Verificado';
          final initial = displayName.substring(0, 1).toUpperCase();
          
          return CornerBorderContainer(
            color: AppColors.border,
            backgroundColor: Colors.white,
            strokeWidth: 2,
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () {
                if (!isLoggedIn) {
                  context.push('/register');
                } else {
                  context.push('/proveedor/${p.id}');
                }
              },
              child: Container(
                width: 140,
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.ink,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (p.proveedorEsPremium) ...[
                          const SizedBox(width: 4),
                          const PremiumBadge(size: 12),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.avgRating != null ? '${p.avgRating!.toStringAsFixed(1)} ★' : 'Nuevo',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData? iconData;
  final VoidCallback? onTap;
  const _HeroChip({required this.label, this.iconData, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconData != null) ...[
                Icon(iconData, color: Colors.white, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
