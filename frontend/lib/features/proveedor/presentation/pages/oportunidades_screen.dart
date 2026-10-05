import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/utils/relative_time.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/providers/oportunidades_provider.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';

class OportunidadesScreen extends StatefulWidget {
  const OportunidadesScreen({super.key});

  @override
  State<OportunidadesScreen> createState() => _OportunidadesScreenState();
}

class _OportunidadesScreenState extends State<OportunidadesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OportunidadesProvider>().loadOportunidades();
      final uid = context.read<AuthProvider>().usuario?.id;
      context.read<ServiciosProvider>().cargarServicios(proveedorId: uid);
    });
  }

  String _formatClp(num monto) {
    final s = monto.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'CLP ${buf.toString()}';
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Breakpoints.isDesktop(context);

    final auth = context.watch<AuthProvider>();
    final opProv = context.watch<OportunidadesProvider>();
    final servProv = context.watch<ServiciosProvider>();

    final serviciosActivos = servProv.servicios.where((s) => s.isActivo).length;
    final rating = auth.usuario?.avgRating;
    final ratingStr = rating != null ? '${rating.toStringAsFixed(1)} ★' : '— ★';
    final oportunidades = opProv.items;

    return ProScaffold(
      title: 'Oportunidades',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Volver al inicio',
        onPressed: () => context.canPop()
            ? context.pop()
            : context.go('/proveedor/dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await opProv.loadOportunidades();
          final uid = auth.usuario?.id;
          await servProv.cargarServicios(proveedorId: uid);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacing.xl2),
          child: _centered(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VerificationBanner(),
                const SizedBox(height: Spacing.md),
                // --- HERO BANNER ---
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ProColors.accent, ProColors.surface],
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Flex(
                    direction: isDesktop ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isDesktop ? 6 : 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Haz crecer tu trabajo con mejores oportunidades',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            const Text(
                              'Esta sección combina una visión rápida de las métricas clave de tu negocio junto con el acceso directo a solicitudes relevantes del mercado.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: Spacing.xl),
                            Wrap(
                              spacing: Spacing.md,
                              runSpacing: Spacing.md,
                              children: [
                                ProButton(
                                  label: 'Ver mis servicios',
                                  compact: true,
                                  onPressed: () =>
                                      context.go('/proveedor/servicios'),
                                ),
                                ProButton(
                                  label: 'Revisar propuestas',
                                  isOutline: true,
                                  compact: true,
                                  onPressed: () =>
                                      context.go('/proveedor/mis-propuestas'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop)
                        const SizedBox(width: Spacing.xl)
                      else
                        const SizedBox(height: Spacing.xl),
                      Expanded(
                        flex: isDesktop ? 4 : 0,
                        child: Column(
                          children: [
                            _MiniHeroKpi(
                              title: 'Servicios activos',
                              value: '$serviciosActivos',
                            ),
                            const SizedBox(height: Spacing.sm),
                            _MiniHeroKpi(
                              title: 'Rating promedio',
                              value: ratingStr,
                            ),
                            const SizedBox(height: Spacing.sm),
                            _MiniHeroKpi(
                              title: 'Oportunidades nuevas',
                              value: '${oportunidades.length}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl2),

                // --- GRID DE METRICAS ---
                // Columnas según el ancho LOCAL disponible, no
                // Breakpoints.isMobile (ancho total de ventana): con sidebar
                // visible (>=600px) esta columna sigue angosta hasta bien
                // pasado los 600px, zona muerta donde 3 columnas truncaban
                // las etiquetas ("SERVI...", "OPOR...").
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 420
                        ? 1
                        : (constraints.maxWidth < 640 ? 2 : 3);
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 110,
                      ),
                      children: [
                        _MetricCard(
                          label: 'Servicios activos',
                          value: '$serviciosActivos',
                        ),
                        _MetricCard(
                          label: 'Rating',
                          value: rating?.toStringAsFixed(1) ?? '—',
                        ),
                        _MetricCard(
                          label: 'Oportunidades',
                          value: '${oportunidades.length}',
                        ),
                        _MetricCard(
                          label: 'Identidad',
                          value: switch (auth.usuario?.docEstado) {
                            'approved' => 'Verificada',
                            'pending' => 'En revisión',
                            'rejected' => 'Rechazada',
                            _ => 'Sin verificar',
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Spacing.xl2),

                // --- LISTADO DE OPORTUNIDADES ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oportunidades para ti',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ProColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compara requerimientos, presupuestos y urgencias rápido.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ProColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.lg),

                if (opProv.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(Spacing.xl2),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (opProv.error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl2),
                      child: Text(
                        opProv.error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ProColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (oportunidades.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl2),
                      child: Text(
                        'No hay oportunidades disponibles por ahora.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ProColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < oportunidades.length; i++) ...[
                        if (i > 0) const SizedBox(height: Spacing.lg),
                        _OpportunityItemDynamic(
                          item: oportunidades[i] as Map<String, dynamic>,
                          tiempoRelativo: formatRelativeTime,
                          formatClp: _formatClp,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityItemDynamic extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic) tiempoRelativo;
  final String Function(num) formatClp;

  const _OpportunityItemDynamic({
    required this.item,
    required this.tiempoRelativo,
    required this.formatClp,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final compactAction = isMobile;
    final docEstado = context.watch<AuthProvider>().usuario?.docEstado;

    final id = item['id']?.toString() ?? '';
    final titulo = item['titulo'] as String? ?? 'Sin título';
    final descripcion = item['descripcion'] as String? ?? '';
    final categoria = item['categoria_nombre'] as String? ?? 'General';
    final ubicacion = item['ubicacion_texto'] as String? ?? 'Sin ubicación';
    final presupuesto = item['presupuesto_max'];
    final presupuestoStr = presupuesto != null
        ? formatClp(presupuesto as num)
        : 'A convenir';
    final tiempo = tiempoRelativo(item['created_at']);

    final theme = Theme.of(context);
    return ProCard(
      onTap: null,
      padding: const EdgeInsets.all(22),
      child: Flex(
        direction: compactAction ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: compactAction
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: compactAction ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(
                      label: categoria,
                      color: ProColors.accent,
                      bg: ProColors.accent.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ProColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  descripcion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ProColors.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.lg,
                  children: [
                    _MetaRowItem(
                      icon: Icons.attach_money,
                      label: 'Presupuesto: $presupuestoStr',
                    ),
                    _MetaRowItem(
                      icon: Icons.location_on_outlined,
                      label: 'Comuna: $ubicacion',
                    ),
                    if (tiempo.isNotEmpty)
                      _MetaRowItem(icon: Icons.access_time, label: tiempo),
                  ],
                ),
              ],
            ),
          ),
          if (compactAction)
            const SizedBox(height: 18)
          else
            const SizedBox(width: Spacing.xl),
          SizedBox(
            width: compactAction ? double.infinity : 180,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ProButton(
                    label: 'Enviar propuesta',
                    onPressed: id.isEmpty
                        ? null
                        : () {
                            if (docEstado != 'approved') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Para garantizar la seguridad de la comunidad, espera a que validemos tu identidad para contactar clientes.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.push('/solicitud/$id/proponer');
                          },
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: ProButton(
                    label: 'Ver detalle',
                    isOutline: true,
                    onPressed: id.isNotEmpty
                        ? () => context.push('/solicitud/$id')
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniHeroKpi extends StatelessWidget {
  final String title;
  final String value;
  const _MiniHeroKpi({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProCard(
      onTap: null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: ProColors.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ProColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    if (!auth.isLoggedIn) {
      return const SizedBox.shrink();
    }
    final usuario = auth.usuario!;
    final needsEmail = !usuario.isVerified;
    final needsIdentity = usuario.docEstado != 'approved';
    if (!needsEmail && !needsIdentity) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: ProColors.amber.withValues(alpha: 0.15),
        border: Border.all(color: ProColors.amber.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Text(
            needsEmail
                ? 'Verifica tu email para recibir oportunidades y publicar servicios'
                : 'Verifica tu identidad para poder enviar propuestas a los clientes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ProColors.amber,
              fontWeight: FontWeight.w600,
            ),
          );
          final actionButtonStyle = TextButton.styleFrom(
            foregroundColor: ProColors.amber,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
          final resendButton = needsEmail
              ? TextButton(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final ok = await auth.resendVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok ? 'Correo reenviado' : auth.error ?? 'Error',
                          ),
                          backgroundColor: ok
                              ? ProColors.success
                              : ProColors.danger,
                        ),
                      );
                    }
                  },
                  style: actionButtonStyle,
                  child: const Text(
                    'Reenviar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : TextButton(
                  onPressed: () => context.push('/seguridad/identidad'),
                  style: actionButtonStyle,
                  child: const Text(
                    'Verificar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
          // El texto de aviso es largo; en pantallas angostas el botón
          // "Reenviar" al lado lo apretaba a una columna muy angosta y
          // envolvía en 5-6 líneas. Se apila debajo en vez de al costado.
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: ProColors.amber),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: text),
                  ],
                ),
                Align(alignment: Alignment.centerRight, child: resendButton),
              ],
            );
          }
          return Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: ProColors.amber),
              const SizedBox(width: Spacing.sm),
              Expanded(child: text),
              resendButton,
            ],
          );
        },
      ),
    );
  }
}

class _MetaRowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRowItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: ProColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ProColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
