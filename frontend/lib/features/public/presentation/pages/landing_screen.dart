import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/core/utils/relative_time.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';
import 'package:trabajoya_app/shared/theme/ticket_border.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';
import 'package:trabajoya_app/utils/colors.dart';

const _heroPhotoUrl =
    'https://images.unsplash.com/photo-1717281234297-3def5ae3eee1'
    '?fm=jpg&q=80&w=1200&auto=format&fit=crop';
const _repairsPhotoUrl =
    'https://plus.unsplash.com/premium_photo-1663013675008-bd5a7898ac4f'
    '?fm=jpg&q=80&w=1200&auto=format&fit=crop';
const _transportPhotoUrl =
    'https://images.unsplash.com/photo-1715645948484-da40dd56bc93'
    '?fm=jpg&q=80&w=900&auto=format&fit=crop';
const _clientCtaPhotoUrl =
    'https://plus.unsplash.com/premium_photo-1664035152456-3493c111c7c7'
    '?fm=jpg&q=80&w=900&auto=format&fit=crop';

const _categoryPhotoUrls = <String, String>{
  'arte-diseno':
      'https://images.unsplash.com/photo-1513364776144-60967b0f800f'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'asesoria':
      'https://images.unsplash.com/photo-1556761175-b413da4baf72'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'automotriz':
      'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'belleza':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'clases':
      'https://images.unsplash.com/photo-1522202176988-66273c2fd55f'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'deportes':
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'eventos':
      'https://images.unsplash.com/photo-1519167758481-83f550bb49b3'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'gastronomia':
      'https://images.unsplash.com/photo-1556911220-bff31c812dba'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'mascotas':
      'https://images.unsplash.com/photo-1517849845537-4d257902454a'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'moda':
      'https://images.unsplash.com/photo-1483985988355-763728e1935b'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'musica':
      'https://images.unsplash.com/photo-1511379938547-c1f69419868d'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'reparaciones-hogar': _repairsPhotoUrl,
  'salud-bienestar':
      'https://images.unsplash.com/photo-1505751172876-fa1923c5c528'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'servicios-profesionales':
      'https://images.unsplash.com/photo-1521737711867-e3b97375f902'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'tecnologia':
      'https://images.unsplash.com/photo-1518770660439-4636190af475'
      '?fm=jpg&q=80&w=900&auto=format&fit=crop',
  'transporte': _transportPhotoUrl,
};

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _searchController = TextEditingController();
  final _requestsService = SolicitudesService();
  final _howKey = GlobalKey();
  final _categoriesKey = GlobalKey();
  final _professionalsKey = GlobalKey();
  final _faqKey = GlobalKey();

  List<Solicitud> _requests = const [];
  bool _requestsLoading = true;
  String? _requestsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiciosProvider>()
        ..cargarCategorias()
        ..cargarServicios();
      _loadRequests();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await _requestsService.getSolicitudes(limit: 3);
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _requestsLoading = false;
        _requestsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requestsLoading = false;
        _requestsError = 'No pudimos cargar las solicitudes en este momento.';
      });
    }
  }

  void _goToAccount(AuthProvider auth) {
    if (auth.isAdmin) {
      context.go('/admin');
    } else if (auth.isProveedorMode) {
      context.go('/proveedor');
    } else {
      context.go('/cliente');
    }
  }

  void _search([String? value]) {
    final query = (value ?? _searchController.text).trim();
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    final route = loggedIn ? '/cliente/buscar' : '/buscar';
    final destination = query.isEmpty
        ? route
        : Uri(path: route, queryParameters: {'q': query}).toString();
    context.push(destination);
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: Motion.slow,
      curve: Motion.curve,
      alignment: 0.04,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final services = context.watch<ServiciosProvider>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: CustomScrollView(
        slivers: [
          _LandingHeader(
            auth: auth,
            onHome: () => context.go('/'),
            onAccount: () => _goToAccount(auth),
            onLogin: () => context.push('/login'),
            onRegister: () => context.push('/register'),
            onHow: () => _scrollTo(_howKey),
            onCategories: () => _scrollTo(_categoriesKey),
            onProfessionals: () => _scrollTo(_professionalsKey),
            onFaq: () => _scrollTo(_faqKey),
          ),
          SliverToBoxAdapter(
            child: _HeroSection(
              controller: _searchController,
              categories: services.categoriasRaiz,
              request: _requests.isEmpty ? null : _requests.first,
              requestLoading: _requestsLoading,
              onSearch: _search,
              onCategory: _search,
            ),
          ),
          const SliverToBoxAdapter(child: _TrustStrip()),
          SliverToBoxAdapter(child: _HowItWorksSection(key: _howKey)),
          SliverToBoxAdapter(
            child: _CategoriesSection(
              key: _categoriesKey,
              categories: services.categoriasRaiz,
              loading: services.loading && services.categoriasRaiz.isEmpty,
              error: services.error,
              onCategory: _search,
              onAll: () => context.push(
                auth.isLoggedIn ? '/cliente/categorias' : '/categorias',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ServicesSection(
              services: services.servicios,
              loading: services.loading && services.servicios.isEmpty,
              error: services.error,
              onAll: () =>
                  context.push(auth.isLoggedIn ? '/cliente/buscar' : '/buscar'),
              onService: (service) => context.push('/servicio/${service.id}'),
            ),
          ),
          SliverToBoxAdapter(
            child: _RequestsSection(
              requests: _requests,
              loading: _requestsLoading,
              error: _requestsError,
              onRetry: _loadRequests,
              onRequest: (request) {
                if (auth.isLoggedIn) {
                  context.push('/solicitud/${request.id}');
                } else {
                  context.push('/register?rol=proveedor');
                }
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _DualCtaSection(
              key: _professionalsKey,
              onClient: () => context.push(
                auth.isLoggedIn ? '/crear-solicitud' : '/register?rol=cliente',
              ),
              onProfessional: () => context.push(
                auth.isLoggedIn
                    ? '/proveedor/oportunidades'
                    : '/register?rol=proveedor',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _ConfidenceSection()),
          SliverToBoxAdapter(child: _FaqSection(key: _faqKey)),
          SliverToBoxAdapter(
            child: _FinalCtaSection(
              onClient: () => context.push('/register?rol=cliente'),
              onProfessional: () => context.push('/register?rol=proveedor'),
            ),
          ),
          SliverToBoxAdapter(
            child: _LandingFooter(
              onHome: () => context.go('/'),
              onTerms: () => context.push('/terminos'),
              onPrivacy: () => context.push('/privacidad'),
              onContact: () => context.push('/contacto'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback onHome;
  final VoidCallback onAccount;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onHow;
  final VoidCallback onCategories;
  final VoidCallback onProfessionals;
  final VoidCallback onFaq;

  const _LandingHeader({
    required this.auth,
    required this.onHome,
    required this.onAccount,
    required this.onLogin,
    required this.onRegister,
    required this.onHow,
    required this.onCategories,
    required this.onProfessionals,
    required this.onFaq,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      toolbarHeight: 76,
      backgroundColor: AppColors.paper.withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
      titleSpacing: 0,
      title: _LandingWrap(
        verticalPadding: 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLinks = constraints.maxWidth > 900;
            final compact = constraints.maxWidth < 520;
            return Row(
              children: [
                _BrandMark(onTap: onHome, showWord: constraints.maxWidth > 390),
                if (showLinks) ...[
                  const Spacer(),
                  _HeaderLink(label: 'Cómo funciona', onTap: onHow),
                  _HeaderLink(label: 'Categorías', onTap: onCategories),
                  _HeaderLink(
                    label: 'Para profesionales',
                    onTap: onProfessionals,
                  ),
                  _HeaderLink(label: 'Preguntas', onTap: onFaq),
                ],
                const Spacer(),
                if (auth.isLoggedIn)
                  OutlinedButton(
                    onPressed: onAccount,
                    child: const Text('Mi cuenta'),
                  )
                else ...[
                  if (!compact)
                    OutlinedButton(
                      onPressed: onLogin,
                      child: const Text('Iniciar sesión'),
                    )
                  else
                    TextButton(onPressed: onLogin, child: const Text('Entrar')),
                  const SizedBox(width: Spacing.sm),
                  FilledButton(
                    onPressed: onRegister,
                    child: Text(compact ? 'Crear' : 'Crear cuenta'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
      child: Text(label),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final VoidCallback onTap;
  final bool showWord;
  final bool light;

  const _BrandMark({
    required this.onTap,
    this.showWord = true,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'TrabajoYa, ir al inicio',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Image.asset(
            showWord
                ? light
                      ? 'assets/images/brand/trabajoya-logo-dark.png'
                      : 'assets/images/brand/trabajoya-logo-horizontal.png'
                : 'assets/images/brand/trabajoya-app-icon.png',
            width: showWord ? (light ? 176 : 168) : 34,
            height: showWord ? (light ? 50 : 45) : 34,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final TextEditingController controller;
  final List<Categoria> categories;
  final Solicitud? request;
  final bool requestLoading;
  final ValueChanged<String?> onSearch;
  final ValueChanged<String> onCategory;

  const _HeroSection({
    required this.controller,
    required this.categories,
    required this.request,
    required this.requestLoading,
    required this.onSearch,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    return _LandingWrap(
      verticalPadding: 64,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth > 920;
          final copy = _HeroCopy(
            controller: controller,
            categories: categories,
            onSearch: onSearch,
            onCategory: onCategory,
          );
          final visual = _HeroVisual(request: request, loading: requestLoading);

          if (!desktop) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: Spacing.xl3),
                visual,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 11, child: copy),
              const SizedBox(width: 64),
              Expanded(flex: 9, child: visual),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final TextEditingController controller;
  final List<Categoria> categories;
  final ValueChanged<String?> onSearch;
  final ValueChanged<String> onCategory;

  const _HeroCopy({
    required this.controller,
    required this.categories,
    required this.onSearch,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final headline = theme.textTheme.displayLarge?.apply(
      fontSizeFactor: width > 920
          ? 2.05
          : width < 480
          ? 1.22
          : 1.55,
    );
    final quickCategories = categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow(label: 'Servicios locales · Chile'),
        const SizedBox(height: Spacing.lg),
        Semantics(
          header: true,
          child: RichText(
            text: TextSpan(
              style: headline?.copyWith(
                color: AppColors.ink,
                height: 0.96,
                fontWeight: FontWeight.w900,
              ),
              children: const [
                TextSpan(text: 'ENCUENTRA A QUIEN\n'),
                TextSpan(
                  text: 'SABE',
                  style: TextStyle(color: AppColors.rust),
                ),
                TextSpan(text: ' HACERLO BIEN.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Text(
            'Publica lo que necesitas y compara propuestas de profesionales '
            'de tu zona con precios, perfiles y reseñas reales.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl2),
        _HeroSearchBar(controller: controller, onSubmit: () => onSearch(null)),
        if (quickCategories.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: quickCategories
                .map(
                  (category) => ActionChip(
                    label: Text(category.nombre),
                    onPressed: () => onCategory(category.nombre),
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.line),
                    shape: const StadiumBorder(),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _HeroSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _HeroSearchBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 430;
        final input = TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(
            hintText: '¿Qué necesitas? Ej: gasfitería en Ñuñoa',
            prefixIcon: Icon(Icons.search),
          ),
        );
        final button = FilledButton(
          onPressed: onSubmit,
          child: const Text('Buscar'),
        );

        return Container(
          padding: const EdgeInsets.all(Spacing.xs),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    input,
                    const SizedBox(height: Spacing.xs),
                    button,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: input),
                    const SizedBox(width: Spacing.xs),
                    button,
                  ],
                ),
        );
      },
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final Solicitud? request;
  final bool loading;

  const _HeroVisual({required this.request, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: const _NetworkPhoto(
                url: _heroPhotoUrl,
                semanticLabel:
                    'Profesional pintando una pared interior con rodillo',
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: -24,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: _HeroRequestTicket(request: request, loading: loading),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRequestTicket extends StatelessWidget {
  final Solicitud? request;
  final bool loading;

  const _HeroRequestTicket({required this.request, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const TicketCard(child: LinearProgressIndicator(minHeight: 2));
    }

    final current = request;
    return TicketCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: current == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TABLERO EN VIVO', style: AppTheme.badgeLabel),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Publica una solicitud y recibe propuestas.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge.forStatus(current.status),
                    const Spacer(),
                    Text(
                      _formatBudget(current.presupuestoMax),
                      style: AppTheme.dataSmall,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  current.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _requestMeta(current),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                ),
              ],
            ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: _LandingWrap(
        verticalPadding: Spacing.xl,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          spacing: Spacing.xl2,
          runSpacing: Spacing.md,
          children: const [
            _TrustStripItem(
              icon: Icon(Icons.verified_user_outlined, color: AppColors.rust),
              label: 'Identidad verificada',
            ),
            _TrustStripItem(
              icon: Icon(Icons.lock_outline, color: AppColors.rust),
              label: 'Pago protegido',
            ),
            _TrustStripItem(
              icon: _TrustGlyph(kind: _TrustGlyphKind.compare),
              label: 'Propuestas comparables',
            ),
            _TrustStripItem(
              icon: _TrustGlyph(kind: _TrustGlyphKind.support),
              label: 'Soporte durante el proceso',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStripItem extends StatelessWidget {
  final Widget icon;
  final String label;

  const _TrustStripItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: Spacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

enum _TrustGlyphKind { compare, support }

class _TrustGlyph extends StatelessWidget {
  final _TrustGlyphKind kind;

  const _TrustGlyph({required this.kind});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _TrustGlyphPainter(kind)),
    );
  }
}

class _TrustGlyphPainter extends CustomPainter {
  final _TrustGlyphKind kind;

  const _TrustGlyphPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.rust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (kind == _TrustGlyphKind.compare) {
      canvas.drawLine(Offset(3, 7), Offset(20, 7), stroke);
      canvas.drawLine(Offset(16, 3), Offset(20, 7), stroke);
      canvas.drawLine(Offset(16, 11), Offset(20, 7), stroke);
      canvas.drawLine(Offset(21, 17), Offset(4, 17), stroke);
      canvas.drawLine(Offset(8, 13), Offset(4, 17), stroke);
      canvas.drawLine(Offset(8, 21), Offset(4, 17), stroke);
      return;
    }
    canvas.drawCircle(const Offset(12, 11), 7, stroke);
    canvas.drawLine(const Offset(5, 11), const Offset(5, 17), stroke);
    canvas.drawLine(const Offset(19, 11), const Offset(19, 17), stroke);
    canvas.drawLine(const Offset(19, 17), const Offset(15, 17), stroke);
    canvas.drawLine(const Offset(12, 19), const Offset(16, 19), stroke);
  }

  @override
  bool shouldRepaint(_TrustGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key});

  static const steps = [
    (
      '01 / PUBLICAR',
      'Describe el trabajo',
      'Indica qué necesitas, dónde y cuándo. Agrega fotos cuando ayuden a '
          'explicar mejor el problema.',
    ),
    (
      '02 / COMPARAR',
      'Recibe propuestas reales',
      'Compara precio, perfil y reseñas antes de elegir al profesional que '
          'mejor se ajuste.',
    ),
    (
      '03 / COORDINAR',
      'Cierra el trabajo con respaldo',
      'Coordina desde la app, usa el pago protegido y califica cuando el '
          'servicio termine.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: 'Proceso',
      title: 'Tres pasos, del problema al trabajo terminado.',
      description:
          'Todo queda registrado y comparable para que decidas con información.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 760;
          final children = steps
              .map(
                (step) => _StepCell(
                  number: step.$1,
                  title: step.$2,
                  description: step.$3,
                ),
              )
              .toList();
          if (!horizontal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index < children.length - 1)
                    const SizedBox(height: Spacing.xs),
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  Expanded(child: children[index]),
                  if (index < children.length - 1)
                    const SizedBox(width: Spacing.xs),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepCell extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCell({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: TicketBorder(marks: false),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: AppTheme.dataSmall.copyWith(color: AppColors.rust),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSoft,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Categoria> categories;
  final bool loading;
  final String? error;
  final ValueChanged<String> onCategory;
  final VoidCallback onAll;

  const _CategoriesSection({
    super.key,
    required this.categories,
    required this.loading,
    required this.error,
    required this.onCategory,
    required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      topPadding: 0,
      eyebrow: 'Catálogo real',
      title: 'Un profesional para cada tipo de necesidad.',
      description:
          'Explora las categorías disponibles y sus especialidades actuales.',
      action: OutlinedButton(
        onPressed: onAll,
        child: const Text('Ver todas las categorías'),
      ),
      child: _CategoryBento(
        categories: categories,
        loading: loading,
        error: error,
        onCategory: onCategory,
        onAll: onAll,
      ),
    );
  }
}

class _CategoryBento extends StatelessWidget {
  final List<Categoria> categories;
  final bool loading;
  final String? error;
  final ValueChanged<String> onCategory;
  final VoidCallback onAll;

  const _CategoryBento({
    required this.categories,
    required this.loading,
    required this.error,
    required this.onCategory,
    required this.onAll,
  });

  List<Categoria> get _ordered {
    final ordered = <Categoria>[];
    for (final slug in const ['reparaciones-hogar', 'transporte']) {
      for (final category in categories) {
        if (category.slug == slug) ordered.add(category);
      }
    }
    for (final category in categories) {
      if (!ordered.any((item) => item.id == category.id)) {
        ordered.add(category);
      }
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _LandingLoadingCards(count: 4, height: 150);
    }
    if (categories.isEmpty) {
      return _InlineState(
        icon: error == null
            ? Icons.category_outlined
            : Icons.cloud_off_outlined,
        message: error ?? 'Aún no hay categorías disponibles.',
        action: OutlinedButton(onPressed: onAll, child: const Text('Explorar')),
      );
    }

    final visible = _ordered.take(6).toList();
    final remaining = categories.length - visible.length;
    final nextNames = _ordered
        .skip(visible.length)
        .take(3)
        .map((category) => category.nombre)
        .join(', ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final tiles = [
          for (final category in visible)
            _CategoryTile(
              category: category,
              onTap: () => onCategory(category.nombre),
            ),
          _MoreCategoriesTile(
            remaining: remaining,
            names: nextNames,
            onTap: onAll,
          ),
        ];

        if (constraints.maxWidth <= 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < tiles.length; index++) ...[
                SizedBox(height: 138, child: tiles[index]),
                if (index < tiles.length - 1)
                  const SizedBox(height: Spacing.md),
              ],
            ],
          );
        }

        if (constraints.maxWidth <= 900 || visible.length < 6) {
          return _BentoRows(tiles: tiles, columns: 2);
        }

        return Column(
          children: [
            SizedBox(
              height: 330,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 2, child: tiles[0]),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[1]),
                        const SizedBox(height: Spacing.md),
                        Expanded(child: tiles[2]),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[3]),
                        const SizedBox(height: Spacing.md),
                        Expanded(child: tiles[4]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[5]),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: tiles[6]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BentoRows extends StatelessWidget {
  final List<Widget> tiles;
  final int columns;

  const _BentoRows({required this.tiles, required this.columns});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < tiles.length; index += columns) {
      final rowChildren = <Widget>[];
      for (var offset = 0; offset < columns; offset++) {
        final tileIndex = index + offset;
        rowChildren.add(
          Expanded(
            child: tileIndex < tiles.length
                ? tiles[tileIndex]
                : const SizedBox.shrink(),
          ),
        );
        if (offset < columns - 1) {
          rowChildren.add(const SizedBox(width: Spacing.md));
        }
      }
      rows.add(
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          rows[index],
          if (index < rows.length - 1) const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Categoria category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photoUrl = _categoryPhotoUrls[category.slug];
    if (photoUrl != null) {
      return Material(
        color: AppColors.ink,
        shape: TicketBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _NetworkPhoto(url: photoUrl, semanticLabel: category.nombre),
              Container(color: AppColors.ink.withValues(alpha: 0.58)),
              Positioned(
                left: Spacing.lg,
                right: Spacing.lg,
                bottom: Spacing.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _specialtiesLabel(category),
                      style: AppTheme.badgeLabel.copyWith(
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      category.nombre,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TicketCard(
      onTap: onTap,
      border: TicketBorder(marks: false),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueprintTint,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Text(
              category.icono?.isNotEmpty == true ? category.icono! : '•',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            category.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            _specialtiesLabel(category),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _MoreCategoriesTile extends StatelessWidget {
  final int remaining;
  final String names;
  final VoidCallback onTap;

  const _MoreCategoriesTile({
    required this.remaining,
    required this.names,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      shape: TicketBorder(line: AppColors.ink, ink: Colors.white),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                remaining > 0
                    ? '+$remaining categorías'
                    : 'Ver catálogo completo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  '$names y más →',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final List<Servicio> services;
  final bool loading;
  final String? error;
  final VoidCallback onAll;
  final ValueChanged<Servicio> onService;

  const _ServicesSection({
    required this.services,
    required this.loading,
    required this.error,
    required this.onAll,
    required this.onService,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const _LandingLoadingCards(count: 3, height: 300);
    } else if (services.isEmpty) {
      content = _InlineState(
        icon: error == null ? Icons.work_outline : Icons.cloud_off_outlined,
        message: error ?? 'No hay servicios disponibles en este momento.',
        action: OutlinedButton(
          onPressed: onAll,
          child: const Text('Explorar servicios'),
        ),
      );
    } else {
      final visible = services.take(6).toList();
      content = LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 1040
              ? 3
              : constraints.maxWidth > 680
              ? 2
              : 1;
          final width =
              (constraints.maxWidth - Spacing.lg * (columns - 1)) / columns;
          return Wrap(
            spacing: Spacing.lg,
            runSpacing: Spacing.lg,
            children: visible
                .map(
                  (service) => SizedBox(
                    width: width,
                    height: 310,
                    child: _ServiceTicket(
                      service: service,
                      onTap: () => onService(service),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return _Section(
      topPadding: 0,
      eyebrow: 'Servicios reales',
      title: 'Profesionales disponibles ahora.',
      description:
          'Explora servicios publicados por profesionales independientes.',
      action: TextButton(
        onPressed: onAll,
        child: const Text('Ver todos los servicios →'),
      ),
      child: content,
    );
  }
}

class _ServiceTicket extends StatelessWidget {
  final Servicio service;
  final VoidCallback onTap;

  const _ServiceTicket({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = service.fotosList.isEmpty ? null : service.fotosList.first;
    return TicketCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 110,
            child: photo == null
                ? Container(
                    color: AppColors.blueprintTint,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.handyman_outlined,
                      color: AppColors.blueprint,
                    ),
                  )
                : _NetworkPhoto(
                    url: photo,
                    semanticLabel: 'Imagen de ${service.titulo}',
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        _formatServicePrice(service),
                        style: AppTheme.dataSmall.copyWith(
                          color: AppColors.rustDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    service.descripcion
                        .replaceAll('\n', ' ')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  const Divider(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.blueprintTint,
                        foregroundColor: AppColors.blueprint,
                        child: Text(_initials(service.proveedorNombre)),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          service.proveedorNombre ?? 'Profesional',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      if (service.proveedorDocEstado == 'approved')
                        const Icon(
                          Icons.verified_outlined,
                          color: AppColors.verified,
                        ),
                      if (service.proveedorRating != null) ...[
                        const SizedBox(width: Spacing.xs),
                        Text(
                          '${service.proveedorRating!.toStringAsFixed(1)} ★',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsSection extends StatelessWidget {
  final List<Solicitud> requests;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Solicitud> onRequest;

  const _RequestsSection({
    required this.requests,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const _LandingLoadingCards(count: 3, height: 250);
    } else if (error != null || requests.isEmpty) {
      content = _InlineState(
        icon: error == null
            ? Icons.assignment_outlined
            : Icons.cloud_off_outlined,
        message: error ?? 'No hay solicitudes abiertas en este momento.',
        action: error == null
            ? null
            : OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 900;
          final cards = requests
              .take(3)
              .map(
                (request) => _RequestTicket(
                  request: request,
                  onTap: () => onRequest(request),
                ),
              )
              .toList();
          if (!horizontal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  cards[index],
                  if (index < cards.length - 1)
                    const SizedBox(height: Spacing.lg),
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  Expanded(child: cards[index]),
                  if (index < cards.length - 1)
                    const SizedBox(width: Spacing.lg),
                ],
              ],
            ),
          );
        },
      );
    }

    return _Section(
      topPadding: 0,
      eyebrow: 'Tablero en vivo',
      title: 'Solicitudes que buscan respuesta ahora.',
      description:
          'Datos reales publicados por clientes y disponibles para profesionales.',
      child: content,
    );
  }
}

class _RequestTicket extends StatelessWidget {
  final Solicitud request;
  final VoidCallback onTap;

  const _RequestTicket({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.forStatus(request.status),
              const Spacer(),
              Text(
                _formatBudget(request.presupuestoMax),
                style: AppTheme.dataSmall,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            request.titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            request.descripcion,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          const Divider(),
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.xs,
            children: [
              Text(
                _requestMeta(request),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
              if (request.propuestasCount > 0)
                Text(
                  '${request.propuestasCount} propuestas',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.blueprint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualCtaSection extends StatelessWidget {
  final VoidCallback onClient;
  final VoidCallback onProfessional;

  const _DualCtaSection({
    super.key,
    required this.onClient,
    required this.onProfessional,
  });

  @override
  Widget build(BuildContext context) {
    return _LandingWrap(
      verticalPadding: Spacing.xl3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 820;
          final client = _CtaPanel(
            imageUrl: _clientCtaPhotoUrl,
            overlay: AppColors.blueprint,
            eyebrow: 'Para clientes',
            title: '¿Necesitas resolver algo?',
            description:
                'Publica gratis, compara propuestas y coordina el trabajo '
                'desde un solo lugar.',
            buttonLabel: 'Publicar una solicitud',
            onTap: onClient,
            filled: true,
          );
          final professional = _CtaPanel(
            imageUrl: _transportPhotoUrl,
            overlay: AppColors.rustDark,
            eyebrow: 'Para profesionales',
            title: '¿Vives de tu oficio?',
            description:
                'Crea tu perfil y encuentra solicitudes que coincidan con '
                'tus servicios y cobertura.',
            buttonLabel: 'Buscar oportunidades',
            onTap: onProfessional,
          );
          final panels = horizontal
              ? Row(
                  children: [
                    Expanded(child: client),
                    const SizedBox(
                      width: 1,
                      height: 360,
                      child: ColoredBox(color: AppColors.line),
                    ),
                    Expanded(child: professional),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    client,
                    const SizedBox(
                      height: 1,
                      child: ColoredBox(color: AppColors.line),
                    ),
                    professional,
                  ],
                );
          return ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: panels,
          );
        },
      ),
    );
  }
}

class _CtaPanel extends StatelessWidget {
  final String imageUrl;
  final Color overlay;
  final String eyebrow;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool filled;

  const _CtaPanel({
    required this.imageUrl,
    required this.overlay,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetworkPhoto(url: imageUrl, semanticLabel: ''),
          ColoredBox(color: overlay.withValues(alpha: 0.88)),
          Padding(
            padding: const EdgeInsets.all(Spacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DarkEyebrow(label: eyebrow),
                const SizedBox(height: Spacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                filled
                    ? FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.ink,
                        ),
                        child: Text(buttonLabel),
                      )
                    : OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: Text(buttonLabel),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceSection extends StatelessWidget {
  const _ConfidenceSection();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (
        Icons.badge_outlined,
        'Perfiles con información',
        'Identidad, especialidad, cobertura y reseñas ayudan a comparar antes '
            'de contratar.',
      ),
      (
        Icons.shield_outlined,
        'Pagos protegidos',
        'El pago se gestiona dentro de la plataforma y se libera según el '
            'avance acordado.',
      ),
      (
        Icons.support_agent_outlined,
        'Soporte durante el proceso',
        'Puedes pedir ayuda si tienes dudas o aparece un problema con una '
            'contratación.',
      ),
    ];

    return Container(
      color: AppColors.ink,
      child: _LandingWrap(
        verticalPadding: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DarkEyebrow(label: 'Confianza'),
            const SizedBox(height: Spacing.md),
            Text(
              'Respaldo para ambos lados del trabajo.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Spacing.xl2),
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 760;
                final cards = benefits
                    .map(
                      (benefit) => _BenefitTile(
                        icon: benefit.$1,
                        title: benefit.$2,
                        description: benefit.$3,
                      ),
                    )
                    .toList();
                if (!horizontal) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        cards[index],
                        if (index < cards.length - 1)
                          const SizedBox(height: Spacing.md),
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < cards.length; index++) ...[
                      Expanded(child: cards[index]),
                      if (index < cards.length - 1)
                        const SizedBox(width: Spacing.lg),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.rust),
          const SizedBox(height: Spacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({super.key});

  static const items = [
    (
      '¿Cuánto cuesta publicar una solicitud?',
      'Publicar una solicitud y recibir propuestas es gratis para clientes. '
          'Las condiciones aplicables se muestran antes de cualquier pago.',
    ),
    (
      '¿Qué pasa si el trabajo presenta un problema?',
      'El pago protegido permite revisar el avance acordado. Si necesitas '
          'ayuda, puedes contactar al equipo de soporte desde la app.',
    ),
    (
      '¿Cómo se verifica a los profesionales?',
      'La plataforma valida identidad y permite adjuntar certificaciones. '
          'El estado de verificación se muestra en cada perfil.',
    ),
    (
      '¿Puedo buscar servicios fuera de Santiago?',
      'Puedes indicar tu comuna al buscar o publicar. La disponibilidad de '
          'profesionales depende de la cobertura configurada por cada uno.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      eyebrow: 'Antes de empezar',
      title: 'Preguntas frecuentes',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++)
              _FaqItem(
                question: items[index].$1,
                answer: items[index].$2,
                initiallyOpen: index == 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool initiallyOpen;

  const _FaqItem({
    required this.question,
    required this.answer,
    this.initiallyOpen = false,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  AnimatedRotation(
                    duration: reduceMotion ? Duration.zero : Motion.base,
                    turns: _open ? 0.125 : 0,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkSoft,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  final VoidCallback onClient;
  final VoidCallback onProfessional;

  const _FinalCtaSection({
    required this.onClient,
    required this.onProfessional,
  });

  @override
  Widget build(BuildContext context) {
    return _LandingWrap(
      verticalPadding: Spacing.xl3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.md),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: 72,
              ),
              color: AppColors.ink.withValues(alpha: 0.94),
              child: Column(
                children: [
                  const _DarkEyebrow(label: 'Empieza hoy'),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'EL TRABAJO QUE NECESITAS,\nHECHO POR QUIEN SABE.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.apply(
                      color: Colors.white,
                      fontSizeFactor: 1.2,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Crea tu cuenta gratis y elige cómo quieres usar TrabajoYa.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl2),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: Spacing.md,
                    runSpacing: Spacing.md,
                    children: [
                      FilledButton(
                        onPressed: onClient,
                        child: const Text('Buscar un profesional'),
                      ),
                      OutlinedButton(
                        onPressed: onProfessional,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        child: const Text('Ofrecer mis servicios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gap = 38.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _LandingFooter extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onContact;

  const _LandingFooter({
    required this.onHome,
    required this.onTerms,
    required this.onPrivacy,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ink,
      child: _LandingWrap(
        verticalPadding: Spacing.xl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth > 720;
            final brand = Column(
              crossAxisAlignment: horizontal
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                _BrandMark(onTap: onHome, light: true),
                const SizedBox(height: Spacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Text(
                    'Marketplace de servicios locales en Chile: publica, '
                    'compara y coordina con respaldo.',
                    textAlign: horizontal ? TextAlign.left : TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            );
            final links = Semantics(
              container: true,
              label: 'Enlaces legales',
              child: Column(
                crossAxisAlignment: horizontal
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                children: [
                  Text(
                    'INFORMACIÓN',
                    style: AppTheme.badgeLabel.copyWith(
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    alignment: horizontal
                        ? WrapAlignment.end
                        : WrapAlignment.center,
                    spacing: Spacing.sm,
                    runSpacing: Spacing.xs,
                    children: [
                      _FooterLink(label: 'Términos', onTap: onTerms),
                      _FooterLink(label: 'Privacidad', onTap: onPrivacy),
                      _FooterLink(label: 'Contacto', onTap: onContact),
                    ],
                  ),
                ],
              ),
            );

            return Column(
              children: [
                if (horizontal)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: brand),
                      const SizedBox(width: Spacing.xl2),
                      links,
                    ],
                  )
                else ...[
                  brand,
                  const SizedBox(height: Spacing.xl),
                  links,
                ],
                const SizedBox(height: Spacing.xl),
                Divider(color: Colors.white.withValues(alpha: 0.16)),
                const SizedBox(height: Spacing.md),
                Text(
                  '© 2026 TrabajoYa. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      ),
      child: Text(label),
    );
  }
}

class _Section extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? description;
  final Widget? action;
  final Widget child;
  final double topPadding;

  const _Section({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.description,
    this.action,
    this.topPadding = 88,
  });

  @override
  Widget build(BuildContext context) {
    return _LandingWrap(
      verticalPadding: 0,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = action != null && constraints.maxWidth > 640;
                final heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(label: eyebrow),
                    const SizedBox(height: Spacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: Spacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Text(
                          description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.inkSoft,
                                height: 1.55,
                              ),
                        ),
                      ),
                    ],
                  ],
                );

                if (!horizontal) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      if (action != null) ...[
                        const SizedBox(height: Spacing.md),
                        action!,
                      ],
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: Spacing.xl),
                    action!,
                  ],
                );
              },
            ),
            const SizedBox(height: Spacing.xl2),
            child,
          ],
        ),
      ),
    );
  }
}

class _LandingWrap extends StatelessWidget {
  final Widget child;
  final double verticalPadding;

  const _LandingWrap({required this.child, required this.verticalPadding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 640
                ? Spacing.lg
                : Spacing.xl,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DarkEyebrow extends StatelessWidget {
  final String label;

  const _DarkEyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, color: AppColors.rust),
        const SizedBox(width: Spacing.sm),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: AppTheme.eyebrow.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  final String url;
  final String semanticLabel;

  const _NetworkPhoto({required this.url, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: semanticLabel.isNotEmpty,
      label: semanticLabel.isEmpty ? null : semanticLabel,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => Container(
          color: AppColors.blueprintTint,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, _, _) => Container(
          color: AppColors.blueprintTint,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.blueprint,
          ),
        ),
      ),
    );
  }
}

class _LandingLoadingCards extends StatelessWidget {
  final int count;
  final double height;

  const _LandingLoadingCards({required this.count, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 760;
        final cards = List.generate(
          count,
          (_) => SizedBox(
            height: height,
            child: const TicketCard(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        );
        if (!horizontal) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index < cards.length - 1)
                  const SizedBox(height: Spacing.lg),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index < cards.length - 1) const SizedBox(width: Spacing.lg),
            ],
          ],
        );
      },
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _InlineState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      padding: const EdgeInsets.all(Spacing.xl2),
      child: Column(
        children: [
          Icon(icon, color: AppColors.blueprint),
          const SizedBox(height: Spacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
          ),
          if (action != null) ...[const SizedBox(height: Spacing.lg), action!],
        ],
      ),
    );
  }
}

String _specialtiesLabel(Categoria category) {
  final count = category.subcategorias.length;
  if (count == 0) return 'Categoría disponible';
  return count.toString() + (count == 1 ? ' especialidad' : ' especialidades');
}

String _formatBudget(double? amount) {
  if (amount == null) return 'A convenir';
  return 'Hasta \$${_formatNumber(amount)}';
}

String _formatServicePrice(Servicio service) {
  final minimum = service.precioMin;
  if (minimum == null) return 'A convenir';
  if (service.precioMax == 1) {
    return '\$${_formatNumber(minimum)}/h';
  }
  if (service.precioMax == 2) {
    return '\$${_formatNumber(minimum)}/serv.';
  }
  return 'Desde \$${_formatNumber(minimum)}';
}

String _formatNumber(double value) {
  final digits = value.toInt().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _requestMeta(Solicitud request) {
  final parts = <String>[];
  final location = request.ubicacionTexto?.trim();
  if (location != null && location.isNotEmpty) parts.add(location);
  final relative = formatRelativeTime(request.createdAt);
  if (relative.isNotEmpty) parts.add(relative.toLowerCase());
  return parts.isEmpty ? 'Chile' : parts.join(' · ');
}

String _initials(String? name) {
  final words = (name ?? '').trim().split(RegExp(r'\s+'));
  final initials = words
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.substring(0, 1).toUpperCase())
      .join();
  return initials.isEmpty ? 'P' : initials;
}
