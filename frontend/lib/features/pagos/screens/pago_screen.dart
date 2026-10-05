import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/pagos/presentation/providers/pagos_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

class PagoScreen extends StatefulWidget {
  final String contratacionId;
  const PagoScreen({super.key, required this.contratacionId});

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  Map<String, dynamic>? _pagoResult;
  String? _status;
  bool _loading = false;

  Future<void> _crearPago() async {
    setState(() => _loading = true);
    try {
      final pagos = context.read<PagosProvider>();
      _pagoResult = await pagos.crearPagoMP(widget.contratacionId);
      final initPoint = _pagoResult?['init_point'] ?? _pagoResult?['url'] ?? '';
      if (initPoint.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abriendo MercadoPago...')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _consultarEstado() async {
    setState(() => _loading = true);
    try {
      final pagos = context.read<PagosProvider>();
      final result = await pagos.getEstadoPago(widget.contratacionId);
      _status = result['status'] as String? ?? 'pendiente';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pago')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pago del Servicio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contratacion: ${widget.contratacionId}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_pagoResult != null) ...[
              Card(
                color: AppTheme.success.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.success),
                      const SizedBox(height: 8),
                      Text(
                        'Pago iniciado',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Completa el pago en MercadoPago para continuar.',
                        textAlign: TextAlign.center,
                      ),
                      if (_pagoResult!['init_point'] != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.open_in_browser),
                          label: const Text('Abrir MercadoPago'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _loading ? null : _crearPago,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _pagoResult != null
                    ? 'Reintentar Pago'
                    : 'Pagar con MercadoPago',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueprint,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _consultarEstado,
              child: const Text('Consultar estado del pago'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estado:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(_status!.toUpperCase()),
                        backgroundColor:
                            _status == 'aprobado' || _status == 'approved'
                            ? AppTheme.success.withValues(alpha: 0.15)
                            : AppTheme.secondary.withValues(alpha: 0.15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
