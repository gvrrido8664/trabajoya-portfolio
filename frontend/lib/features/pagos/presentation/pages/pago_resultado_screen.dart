import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:trabajoya_app/features/pagos/presentation/providers/pagos_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class PagoResultadoScreen extends StatefulWidget {
  final String contratacionId;
  final String status;

  const PagoResultadoScreen({
    super.key,
    required this.contratacionId,
    required this.status,
  });

  @override
  State<PagoResultadoScreen> createState() => _PagoResultadoScreenState();
}

class _PagoResultadoScreenState extends State<PagoResultadoScreen> {
  Map<String, dynamic>? _estadoPago;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    try {
      final pagos = context.read<PagosProvider>();
      final resultado = await pagos.getEstadoPago(widget.contratacionId);
      if (mounted) {
        setState(() {
          _estadoPago = resultado;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Color get _colorForStatus => switch (widget.status) {
    'success' => AppColors.success,
    'failure' => AppColors.danger,
    _ => AppColors.primary,
  };

  IconData get _iconForStatus => switch (widget.status) {
    'success' => Icons.check_circle_outline,
    'failure' => Icons.cancel_outlined,
    _ => Icons.hourglass_empty,
  };

  String get _titleForStatus => switch (widget.status) {
    'success' => 'Pago aprobado',
    'failure' => 'Pago rechazado',
    _ => 'Pago en proceso',
  };

  String get _messageForStatus => switch (widget.status) {
    'success' =>
      'Tu pago fue procesado exitosamente. El proveedor ha sido notificado y puede iniciar el trabajo.',
    'failure' =>
      'El pago no pudo completarse. Puedes intentarlo nuevamente desde el detalle de la contratación.',
    _ =>
      'Tu pago está siendo procesado. Esto puede tardar unos minutos. Te notificaremos cuando se confirme.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado del pago'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: _buildContent(theme),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final color = _colorForStatus;
    final monto = _estadoPago?['monto'] as num?;
    final fee = _estadoPago?['fee_plataforma'] as num?;
    final neto = _estadoPago?['monto_neto'] as num?;
    final estadoReal = (_estadoPago?['status'] as String? ?? '').toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl2),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                  ),
                  child: Icon(_iconForStatus, color: color, size: 32),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  _titleForStatus,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _messageForStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (estadoReal.isNotEmpty) ...[
                  const SizedBox(height: Spacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Estado actual: $estadoReal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],

                if (monto != null) ...[
                  const SizedBox(height: Spacing.xl),
                  Divider(color: AppColors.border),
                  const SizedBox(height: Spacing.sm),
                  _montoRow(
                    theme,
                    'Monto',
                    '\$${monto.toStringAsFixed(0)}',
                    AppColors.textDark,
                  ),
                  if (fee != null)
                    _montoRow(
                      theme,
                      'Fee (10%)',
                      '-\$${fee.toStringAsFixed(0)}',
                      AppColors.textLight,
                    ),
                  if (neto != null)
                    _montoRow(
                      theme,
                      'Al proveedor',
                      '\$${neto.toStringAsFixed(0)}',
                      AppColors.success,
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.xl),

        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () {
              if (widget.status == 'success') {
                context.go('/contratacion/${widget.contratacionId}');
              } else if (widget.status == 'failure') {
                context.go('/pago/${widget.contratacionId}');
              } else {
                context.go('/contratacion/${widget.contratacionId}');
              }
            },
            icon: Icon(
              widget.status == 'failure' ? Icons.refresh : Icons.arrow_forward,
              size: 20,
            ),
            label: Text(
              widget.status == 'success'
                  ? 'Ver contratación'
                  : widget.status == 'failure'
                  ? 'Reintentar pago'
                  : 'Ver estado',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),

        OutlinedButton(
          onPressed: () => context.go('/cliente'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          child: const Text('Ir al inicio'),
        ),
      ],
    );
  }

  Widget _montoRow(ThemeData theme, String label, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textLight,
            ),
          ),
          Text(
            valor,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
