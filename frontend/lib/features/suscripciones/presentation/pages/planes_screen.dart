import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/suscripciones/presentation/providers/suscripciones_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<SuscripcionesProvider>();
      prov.cargarSuscripcion();
      prov.cargarPlanes();
    });
  }

  Future<void> _suscribirse(String planSlug) async {
    final provider = context.read<SuscripcionesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final url = await provider.suscribirse(planSlug);
    if (!mounted) return;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la pasarela de pago')),
        );
      }
    } else if (provider.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  Future<void> _cancelar() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SuscripcionesProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar suscripci\u00f3n'),
        content: const Text(
          'Al cancelar tu suscripci\u00f3n Premium perder\u00e1s los beneficios. \u00bfDeseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('S\u00ed, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await provider.cancelar();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Suscripci\u00f3n cancelada'
              : (provider.error ?? 'Error al cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuscripcionesProvider>();
    final loading = provider.loading;
    final miSuscripcion = provider.miSuscripcion;
    final planActual =
        miSuscripcion?['plan'] as String? ??
        miSuscripcion?['plan_slug'] as String?;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(
          'Planes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (planActual != null) ...[
                  Card(
                    color: AppColors.blueprint.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.blueprint,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Plan actual: ${planActual.toUpperCase()}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blueprint,
                                    ),
                              ),
                            ],
                          ),
                          if (miSuscripcion?['fecha_expiracion'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Expira: ${miSuscripcion!['fecha_expiracion']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (planActual == 'premium') ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: loading ? null : _cancelar,
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Cancelar suscripci\u00f3n'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.danger,
                                side: const BorderSide(color: AppTheme.danger),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (provider.planes.isEmpty && !loading)
                  const Center(child: Text('No hay planes disponibles'))
                else
                  ...provider.planes.map((planData) {
                    final slug = planData['slug'] as String;
                    final isPremium = slug == 'premium';
                    final priceNum = planData['precio_mensual'] as num;
                    final priceText = priceNum == 0
                        ? 'GRATIS'
                        : '\$${priceNum.toInt()} / mes';
                    final features =
                        (planData['beneficios'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPlanCard(
                        title: planData['nombre'] as String? ?? 'Plan',
                        subtitle: planData['descripcion'] as String? ?? '',
                        features: features,
                        price: priceText,
                        isCurrent:
                            planActual == slug ||
                            (planActual == null && slug == 'basico'),
                        isPremium: isPremium,
                        loading: loading,
                        onTap:
                            (planActual == slug || loading || slug == 'basico')
                            ? null
                            : () => _suscribirse(slug),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required List<String> features,
    required String price,
    required bool isCurrent,
    required bool isPremium,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: isPremium ? 4 : 1,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: isPremium
            ? const BorderSide(color: AppTheme.secondary, width: 1.5)
            : BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blueprint, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: const Text(
                  'RECOMENDADO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              price,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPremium
                    ? AppTheme.secondary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 18, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isCurrent)
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Text('Plan actual'),
              )
            else
              ElevatedButton(
                onPressed: loading ? null : onTap,
                style: isPremium
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isPremium ? 'Suscribirse' : 'Gratis'),
              ),
          ],
        ),
      ),
    );
  }
}
