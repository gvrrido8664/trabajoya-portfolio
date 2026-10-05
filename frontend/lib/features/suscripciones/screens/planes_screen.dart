import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/services/suscripciones_service.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  final SuscripcionesService _service = SuscripcionesService();
  Map<String, dynamic>? _miSuscripcion;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarSuscripcion();
  }

  Future<void> _cargarSuscripcion() async {
    setState(() => _loading = true);
    try {
      _miSuscripcion = await _service.getMiSuscripcion();
    } catch (_) {
      _miSuscripcion = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _suscribirse(String planSlug) async {
    setState(() => _loading = true);
    try {
      final result = await _service.crearSuscripcion(planSlug);
      final initPoint = result['init_point'] ?? result['url'] ?? '';
      if (initPoint.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo checkout de pago...')),
        );
      }
      await _cargarSuscripcion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planActual =
        _miSuscripcion?['plan'] as String? ??
        _miSuscripcion?['plan_slug'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (planActual != null) ...[
              Card(
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Plan actual: ${planActual.toUpperCase()}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                          ),
                        ],
                      ),
                      if (_miSuscripcion?['fecha_expiracion'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expira: ${_miSuscripcion!['fecha_expiracion']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildPlanCard(
              title: 'Basico',
              subtitle: 'Gratis',
              features: const [
                'Publica hasta 2 servicios',
                'Chat con clientes',
                'Soporte por email',
              ],
              price: 'GRATIS',
              isCurrent: planActual == 'basic' || planActual == null,
              isPremium: false,
              onTap: null,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'Premium',
              subtitle: 'Para profesionales',
              features: const [
                'Servicios ilimitados',
                'Chat con clientes',
                'Soporte prioritario 24/7',
                'Destacado en busquedas',
                'Sin comision por transaccion',
              ],
              price: '\$4.990 / mes',
              isCurrent: planActual == 'premium',
              isPremium: true,
              onTap: planActual == 'premium'
                  ? null
                  : () => _suscribirse('premium'),
            ),
          ],
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
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: isPremium ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: isPremium
            ? const BorderSide(color: AppTheme.secondary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: const Text(
                  'RECOMENDADO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                  backgroundColor: Colors.grey.shade300,
                ),
                child: const Text('Plan actual'),
              )
            else
              ElevatedButton(
                onPressed: _loading ? null : onTap,
                style: isPremium
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: _loading
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
