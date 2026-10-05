import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/providers/oportunidades_provider.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/features/propuestas/presentation/providers/propuestas_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';

class ProveedorDashboardScreen extends StatefulWidget {
  const ProveedorDashboardScreen({super.key});

  @override
  State<ProveedorDashboardScreen> createState() => _ProveedorDashboardScreenState();
}

class _ProveedorDashboardScreenState extends State<ProveedorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final uid = context.read<AuthProvider>().usuario?.id;
    await Future.wait([
      context.read<ContratacionesProvider>().cargarContrataciones(),
      context.read<PropuestasProvider>().cargarMisPropuestas(),
      context.read<OportunidadesProvider>().loadOportunidades(),
    ]);
  }

  String _formatClp(num monto) {
    final s = monto.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '\$${buf.toString()}';
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contrProv = context.watch<ContratacionesProvider>();
    final propProv = context.watch<PropuestasProvider>();
    final opProv = context.watch<OportunidadesProvider>();

    final isDesktop = Breakpoints.isDesktop(context);

    // Calcular Métricas. "Ingresos" solo cuenta trabajos con payout
    // realmente enviado (payout_status == SENT), no solo status==COMPLETADO
    // (ese status únicamente indica que el trabajo terminó, el payout puede
    // seguir pendiente o haber fallado, ej. sin cuenta bancaria configurada).
    final paidThisMonth = contrProv.contrataciones.where((c) {
      if (c.payoutStatus?.toUpperCase() != 'SENT') return false;
      final date = c.createdAt ?? DateTime.now();
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month;
    });

    final totalRevenues = paidThisMonth.fold<double>(
      0.0,
      (sum, c) => sum + (c.montoAcordado ?? 0.0),
    );

    final activeJobsCount = contrProv.contrataciones.where((c) {
      final statusUpper = c.status.toUpperCase();
      return statusUpper == 'ACEPTADO';
    }).length;

    final pendingProposalsCount = propProv.propuestas.where(
      (p) => p.status.toUpperCase() == 'PENDIENTE',
    ).length;

    final rating = auth.usuario?.avgRating;
    final ratingStr = rating != null ? rating.toStringAsFixed(1) : '—';

    // Listas filtradas para mostrar
    final upcomingJobs = contrProv.contrataciones.where((c) {
      final statusUpper = c.status.toUpperCase();
      return statusUpper == 'ACEPTADO';
    }).take(3).toList();

    final activePropuestas = propProv.propuestas.where(
      (p) => p.status.toUpperCase() == 'PENDIENTE',
    ).take(3).toList();

    final numOportunidades = opProv.items.length;
    final docEstado = auth.usuario?.docEstado ?? 'none';

    return ProScaffold(
      showAppBar: false,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: ProColors.surface,
        color: ProColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProHeader(
                greeting: 'Hola, ${auth.usuario?.nombre ?? 'Proveedor'}',
                subtitle: 'Tu resumen operativo y comercial de hoy.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl2,
                  vertical: Spacing.xl,
                ),
                child: _centered(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- IDENTITY VERIFICATION BANNER (soft gate) ---
                      if (docEstado != 'approved') ...[
                        _buildIdentityBanner(context, docEstado),
                        const SizedBox(height: Spacing.xl2),
                      ],

                      // --- METRICS GRID ---
                      if (contrProv.loading || propProv.loading)
                        _buildMetricsSkeleton(isDesktop)
                      else
                        _buildMetricsGrid(
                          totalRevenues: totalRevenues,
                          activeJobsCount: activeJobsCount,
                          pendingProposalsCount: pendingProposalsCount,
                          ratingStr: ratingStr,
                          isDesktop: isDesktop,
                        ),
                      const SizedBox(height: Spacing.xl2),

                      // --- OPORTUNIDADES CTA BANNER ---
                      _buildOportunidadesBanner(context, numOportunidades, opProv.loading),
                      const SizedBox(height: Spacing.xl2),

                      // --- RESPONSIVE BLOCKS ---
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildAgendaBlock(
                                context,
                                upcomingJobs,
                                contrProv.loading,
                              ),
                            ),
                            const SizedBox(width: Spacing.xl),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildPropuestasBlock(
                                    context,
                                    activePropuestas,
                                    propProv.loading,
                                  ),
                                  const SizedBox(height: Spacing.xl),
                                  _buildQuickActionsBlock(context),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAgendaBlock(
                              context,
                              upcomingJobs,
                              contrProv.loading,
                            ),
                            const SizedBox(height: Spacing.xl2),
                            _buildPropuestasBlock(
                              context,
                              activePropuestas,
                              propProv.loading,
                            ),
                            const SizedBox(height: Spacing.xl2),
                            _buildQuickActionsBlock(context),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSkeleton(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: Spacing.lg,
        mainAxisSpacing: Spacing.lg,
        childAspectRatio: isDesktop ? 1.5 : 0.95,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const ProSkeleton(height: 100),
    );
  }

  Widget _buildMetricsGrid({
    required double totalRevenues,
    required int activeJobsCount,
    required int pendingProposalsCount,
    required String ratingStr,
    required bool isDesktop,
  }) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: Spacing.lg,
        mainAxisSpacing: Spacing.lg,
        childAspectRatio: isDesktop ? 1.5 : 0.95,
      ),
      children: [
        ProMetricTile(
          icon: Icons.attach_money_rounded,
          value: _formatClp(totalRevenues),
          label: 'Ingresos del mes',
          accent: ProColors.success,
        ),
        ProMetricTile(
          icon: Icons.handshake_outlined,
          value: '$activeJobsCount',
          label: 'Trabajos activos',
          accent: ProColors.accent,
        ),
        ProMetricTile(
          icon: Icons.local_offer_outlined,
          value: '$pendingProposalsCount',
          label: 'Propuestas pendientes',
          accent: ProColors.amber,
        ),
        ProMetricTile(
          icon: Icons.star_outline_rounded,
          value: '$ratingStr/5.0',
          label: 'Calificación',
          accent: ProColors.accent,
        ),
      ],
    );
  }

  Widget _buildOportunidadesBanner(BuildContext context, int count, bool loading) {
    final countText = loading
        ? 'Buscando...'
        : count > 0
            ? '$count nuevas solicitudes te esperan'
            : 'Revisa si hay nuevas solicitudes';

    final icon = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.notifications_active_outlined,
        color: ProColors.accent,
        size: 24,
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Oportunidades Comerciales',
          style: TextStyle(
            
            fontWeight: FontWeight.w700,
            color: ProColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          countText,
          style: const TextStyle(
            
            color: ProColors.textSecondary,
          ),
        ),
      ],
    );
    final button = ProButton(
      label: 'Ver oportunidades',
      width: 160,
      onPressed: () {
        context.go('/proveedor/oportunidades');
      },
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: ProColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: ProColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Icono + botón fijo (~48+160+espaciados ≈ 240px) no caben junto
          // al texto en pantallas angostas; ahí se apilan en vez de forzar
          // el Row (causaba wrap letra por letra del título).
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: Spacing.lg),
                    Expanded(child: texts),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                button,
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: Spacing.lg),
              Expanded(child: texts),
              const SizedBox(width: Spacing.md),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentityBanner(BuildContext context, String docEstado) {
    final (String title, String message, String actionLabel) = switch (docEstado) {
      'pending' => (
        'Verificación en revisión',
        'Estamos validando tus documentos. Te avisaremos apenas esté lista.',
        'Ver estado',
      ),
      'rejected' => (
        'Verificación rechazada',
        'Revisa el motivo y vuelve a enviar tus documentos para poder recibir clientes.',
        'Revisar',
      ),
      _ => (
        'Verifica tu identidad',
        'Confirma quién eres para que los clientes puedan contratarte con confianza.',
        'Verificar ahora',
      ),
    };

    final icon = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProColors.amber.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        color: ProColors.amber,
        size: 24,
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: ProColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(message, style: const TextStyle(color: ProColors.textSecondary)),
      ],
    );
    final button = ProButton(
      label: actionLabel,
      width: 160,
      onPressed: () => context.push('/seguridad/identidad'),
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: ProColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: ProColors.amber.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    icon,
                    const SizedBox(width: Spacing.lg),
                    Expanded(child: texts),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                button,
              ],
            );
          }
          return Row(
            children: [
              icon,
              const SizedBox(width: Spacing.lg),
              Expanded(child: texts),
              const SizedBox(width: Spacing.md),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAgendaBlock(
    BuildContext context,
    List<dynamic> jobs,
    bool loading,
  ) {
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProSectionHeader(title: 'Próximos Trabajos'),
          const SizedBox(height: Spacing.md),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: Spacing.md),
              child: ProSkeleton(height: 72),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProSectionHeader(
          title: 'Próximos Trabajos',
          actionLabel: jobs.isNotEmpty ? 'Ver Agenda' : null,
          onAction: () => context.go('/proveedor/contrataciones'),
        ),
        const SizedBox(height: Spacing.md),
        if (jobs.isEmpty)
          ProEmptyState(
            icon: Icons.schedule_rounded,
            title: 'Sin trabajos agendados',
            message: 'No tienes contrataciones activas ni programadas para los próximos días.',
            actionLabel: 'Ver solicitudes',
            onAction: () => context.go('/proveedor/oportunidades'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
            itemBuilder: (context, index) {
              final job = jobs[index];
              return ProCard(
                onTap: () => context.go('/proveedor/contrataciones/detalle/${job.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ProColors.elevated,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: const Icon(
                        Icons.handshake_outlined,
                        color: ProColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.servicioTitulo ?? 'Servicio Contratado',
                            style: const TextStyle(
                              
                              fontWeight: FontWeight.w700,
                              color: ProColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cliente: ${job.clienteNombre ?? '—'}',
                            style: const TextStyle(
                              
                              color: ProColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (job.montoAcordado != null)
                          Text(
                            _formatClp(job.montoAcordado!),
                            style: const TextStyle(
                              
                              fontWeight: FontWeight.w700,
                              color: ProColors.accent,
                            ),
                          ),
                        const SizedBox(height: 2),
                        ProStatusBadge(status: job.status),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPropuestasBlock(
    BuildContext context,
    List<dynamic> propuestas,
    bool loading,
  ) {
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProSectionHeader(title: 'Propuestas Activas'),
          const SizedBox(height: Spacing.md),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: Spacing.md),
              child: ProSkeleton(height: 72),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProSectionHeader(
          title: 'Propuestas Activas',
          actionLabel: propuestas.isNotEmpty ? 'Ver Todas' : null,
          onAction: () => context.go('/proveedor/mis-propuestas'),
        ),
        const SizedBox(height: Spacing.md),
        if (propuestas.isEmpty)
          ProEmptyState(
            icon: Icons.local_offer_outlined,
            title: 'Sin propuestas pendientes',
            message: 'No tienes cotizaciones activas esperando respuesta de clientes.',
            actionLabel: 'Crear propuesta',
            onAction: () => context.go('/proveedor/oportunidades'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: propuestas.length,
            separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
            itemBuilder: (context, index) {
              final prop = propuestas[index];
              return ProCard(
                onTap: () => context.go('/proveedor/mis-propuestas'),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      color: ProColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prop.solicitudTitulo ?? 'Presupuesto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              
                              fontWeight: FontWeight.w700,
                              color: ProColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatClp(prop.precio),
                            style: const TextStyle(
                              
                              color: ProColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    ProStatusBadge(status: prop.status),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickActionsBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProSectionHeader(title: 'Accesos Rápidos'),
        const SizedBox(height: Spacing.md),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: Spacing.md,
            mainAxisSpacing: Spacing.md,
            childAspectRatio: 1.15,
          ),
          children: [
            ProQuickAction(
              icon: Icons.business_center_outlined,
              label: 'Mis Servicios',
              onTap: () => context.go('/proveedor/servicios'),
            ),
            ProQuickAction(
              icon: Icons.person_outline,
              label: 'Mi Perfil',
              onTap: () => context.go('/proveedor/perfil'),
            ),
            ProQuickAction(
              icon: Icons.attach_money_outlined,
              label: 'Cobros',
              accent: ProColors.success,
              onTap: () => context.go('/proveedor/cobros'),
            ),
          ],
        ),
      ],
    );
  }
}
