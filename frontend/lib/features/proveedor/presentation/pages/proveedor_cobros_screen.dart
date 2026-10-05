import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ProveedorCobrosScreen extends StatefulWidget {
  const ProveedorCobrosScreen({super.key});

  @override
  State<ProveedorCobrosScreen> createState() => _ProveedorCobrosScreenState();
}

class _ProveedorCobrosScreenState extends State<ProveedorCobrosScreen> {
  bool _loadingUrl = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contr = context.read<ContratacionesProvider>();
      if (contr.contrataciones.isEmpty) contr.cargarContrataciones();
    });
  }

  Future<void> _conectarMercadoPago() async {
    setState(() => _loadingUrl = true);
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.usuario?.id;
      if (userId == null) return;

      final resp = await apiClient.get('/mercadopago/auth-url?user_id=$userId');
      final urlStr = resp['url'] as String;
      final uri = Uri.parse(urlStr);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede abrir el enlace.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar con MercadoPago: $e'),
          backgroundColor: ProColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingUrl = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final contr = context.watch<ContratacionesProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    final usuario = auth.usuario;
    if (usuario == null) return const SizedBox.shrink();

    final mpConfigured = usuario.mpConfigured;

    double pagado = 0, enCurso = 0;
    int pagadoCount = 0, enCursoCount = 0;
    for (final c in contr.contrataciones) {
      final st = c.status.toUpperCase();
      final monto = c.montoAcordado ?? 0;
      if (c.payoutStatus?.toUpperCase() == 'COMPLETADO') {
        pagado += monto;
        pagadoCount++;
      } else if (st == 'ACEPTADO' || (st == 'COMPLETADO' && c.payoutStatus != 'COMPLETADO')) {
        enCurso += monto;
        enCursoCount++;
      }
    }

    return ProScaffold(
      title: 'Cobros',
      body: RefreshIndicator(
        onRefresh: () async {
          final contrProvider = context.read<ContratacionesProvider>();
          await auth.checkAuth();
          await contrProvider.cargarContrataciones();
        },
        backgroundColor: ProColors.surface,
        color: ProColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Spacing.xl2),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para recibir el pago de tus trabajos, debes vincular tu cuenta de MercadoPago. '
                    'El dinero se depositará automáticamente en tu billetera de MercadoPago de forma instantánea al finalizar un trabajo.',
                    style: TextStyle(
                      color: ProColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl2),
                  _mpCard(mpConfigured),
                  const SizedBox(height: Spacing.xl2),
                  const ProSectionHeader(title: 'Tus cobros (Pagos Online)'),
                  const SizedBox(height: Spacing.md),
                  if (contr.loading && contr.contrataciones.isEmpty)
                    const Row(
                      children: [
                        Expanded(child: ProSkeleton(height: 100)),
                        SizedBox(width: Spacing.lg),
                        Expanded(child: ProSkeleton(height: 100)),
                      ],
                    )
                  else
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: Spacing.lg,
                        mainAxisSpacing: Spacing.lg,
                        childAspectRatio: isDesktop ? 2.2 : 1.5,
                      ),
                      children: [
                        ProMetricTile(
                          icon: Icons.check_circle_outline_rounded,
                          value: _formatClp(pagado),
                          label: 'Pagado · $pagadoCount trabajos',
                          accent: ProColors.success,
                        ),
                        ProMetricTile(
                          icon: Icons.schedule_rounded,
                          value: _formatClp(enCurso),
                          label: 'En curso · $enCursoCount trabajos',
                          accent: ProColors.amber,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mpCard(bool configured) {
    if (configured) {
      return ProCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ProColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: ProColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                const Expanded(
                  child: Text(
                    'Cuenta MercadoPago Vinculada',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ProColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            const Text(
              '¡Listo! Recibirás los pagos de tus clientes de forma instantánea y segura directamente a tu cuenta de MercadoPago.',
              style: TextStyle(color: ProColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ProCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: Spacing.md),
              const Expanded(
                child: Text(
                  'Falta vincular tu cuenta',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ProColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Text(
            'Sin MercadoPago no podrás aceptar pagos online de los clientes en la plataforma.',
            style: TextStyle(color: ProColors.textSecondary),
          ),
          const SizedBox(height: Spacing.xl),
          ProButton(
            label: 'Vincular con MercadoPago',
            loading: _loadingUrl,
            onPressed: _loadingUrl ? null : _conectarMercadoPago,
            icon: Icons.account_balance_wallet_rounded,
          ),
        ],
      ),
    );
  }
}
