import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

import 'package:trabajoya_app/features/pagos/presentation/providers/pagos_provider.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class PagoScreen extends StatefulWidget {
  final String contratacionId;
  final String?
  metodo; // compat de ruta (no usado tras deprecar Webpay directo)
  final String? tokenWs; // compat de ruta
  final String?
  status; // "success" | "failure" | "pending" del redirect del agregador
  const PagoScreen({
    super.key,
    required this.contratacionId,
    this.metodo,
    this.tokenWs,
    this.status,
  });

  @override
  State<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  _PagoState _estado = _PagoState.inicial;
  bool _creandoPago = false;
  String? _errorMsg;
  Map<String, dynamic>? _estadoPago;
  String _metodoSeleccionado = 'mp'; // 'mp' o 'persona'

  Timer? _pollingTimer;
  int _pollingSegundos = 0;
  static const int _maxPollingSegundos = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContratacionesProvider>().getContratacion(
        widget.contratacionId,
      );
    });
    if (widget.status == 'success') {
      _iniciarPolling();
    } else if (widget.status == 'failure') {
      _estado = _PagoState.rechazado;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ─── MercadoPago ──────────────────────────────────────

  Future<void> _iniciarMP() async {
    setState(() {
      _creandoPago = true;
      _errorMsg = null;
    });
    try {
      final pagos = context.read<PagosProvider>();
      final resultado = await pagos.crearPagoMP(widget.contratacionId);
      final url =
          resultado['sandbox_init_point'] as String? ??
          resultado['init_point'] as String? ??
          '';
      if (url.isEmpty) throw Exception('No se recibió URL de pago');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() {
        _estado = _PagoState.esperando;
        _creandoPago = false;
      });
      _iniciarPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creandoPago = false;
        _errorMsg = formatError(e);
        _estado = _PagoState.error;
      });
    }
  }

  Future<void> _acordarEnPersona() async {
    setState(() {
      _creandoPago = true;
      _errorMsg = null;
    });
    try {
      final pagos = context.read<PagosProvider>();
      await pagos.acordarEnPersona(widget.contratacionId);
      if (!mounted) return;
      setState(() {
        _estadoPago = {'monto': context.read<ContratacionesProvider>().selected?.montoAcordado ?? 0};
        _estado = _PagoState.aprobado;
        _creandoPago = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creandoPago = false;
        _errorMsg = formatError(e);
        _estado = _PagoState.error;
      });
    }
  }

  // ─── Polling ──────────────────────────────────────────

  void _iniciarPolling() {
    _pollingSegundos = 0;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollingSegundos += 3;
      if (_pollingSegundos >= _maxPollingSegundos) {
        _pollingTimer?.cancel();
        if (mounted) setState(() => _estado = _PagoState.timeout);
        return;
      }
      await _consultarEstado();
    });
  }

  Future<void> _consultarEstado() async {
    try {
      final pagos = context.read<PagosProvider>();
      final resultado = await pagos.getEstadoPago(widget.contratacionId);
      final status = (resultado['status'] as String? ?? '').toUpperCase();
      if (!mounted) return;
      if (status == 'APROBADO') {
        _pollingTimer?.cancel();
        setState(() {
          _estadoPago = resultado;
          _estado = _PagoState.aprobado;
        });
      } else if (status == 'RECHAZADO' || status == 'CANCELADO') {
        _pollingTimer?.cancel();
        setState(() {
          _estadoPago = resultado;
          _estado = _PagoState.rechazado;
        });
      }
    } catch (_) {}
  }

  void _reintentar() {
    _pollingTimer?.cancel();
    setState(() {
      _estado = _PagoState.inicial;
      _errorMsg = null;
      _estadoPago = null;
      _creandoPago = false;
    });
  }

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pago del servicio')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_estado) {
      _PagoState.inicial => _buildInicial(),
      _PagoState.esperando => _buildEsperando(),
      _PagoState.aprobado => _buildAprobado(),
      _PagoState.rechazado => _buildRechazado(),
      _PagoState.timeout => _buildTimeout(),
      _PagoState.error => _buildError(),
    };
  }

  void _procesarExpressPay(bool isApple, double monto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.build, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${isApple ? 'Apple Pay' : 'Google Pay'} está en desarrollo.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInicial() {
    final theme = Theme.of(context);
    final contratacion = context.watch<ContratacionesProvider>().selected;
    final loadingContratacion = context.watch<ContratacionesProvider>().loading;
    final monto = contratacion?.montoAcordado ?? 15000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen de la Contratación
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: loadingContratacion
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.blueprintTint,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: AppColors.blueprint,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contratacion?.servicioTitulo ??
                                  'Servicio de TrabajoYa',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              'Proveedor: ${contratacion?.proveedorNombre ?? "Cargando..."}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${_fmt(monto)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Apple & Google Express Pay Section
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PAGO RÁPIDO EXPRESS (EN DESARROLLO)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _ExpressPayButton(
                        isApple: true,
                        onTap: () => _procesarExpressPay(true, monto),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: _ExpressPayButton(
                        isApple: false,
                        onTap: () => _procesarExpressPay(false, monto),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),

        // Selector de método de pago tradicional
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPCIONES DE PAGO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _MetodoTile(
                  icon: Icons.credit_card_outlined,
                  nombre: 'Pago Online (MercadoPago)',
                  descripcion: 'Débito / Crédito / Prepago. Protegido por TrabajoYa.',
                  selected: _metodoSeleccionado == 'mp',
                  onTap: () => setState(() => _metodoSeleccionado = 'mp'),
                ),
                const SizedBox(height: Spacing.sm),
                _MetodoTile(
                  icon: Icons.handshake_rounded,
                  nombre: 'Acordar pago en persona',
                  descripcion: 'Sin comisión de plataforma. Le pagas directamente al proveedor.',
                  selected: _metodoSeleccionado == 'persona',
                  onTap: () => setState(() => _metodoSeleccionado = 'persona'),
                ),
                const SizedBox(height: Spacing.sm),
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.blueprint.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.blueprint,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Expanded(
                        child: Text(
                          _metodoSeleccionado == 'mp'
                              ? 'El pago se procesa de forma segura y el proveedor recibe su dinero al finalizar.'
                              : 'Al acordar en persona, TrabajoYa no retiene comisiones y el pago se gestiona entre el proveedor y tú.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.blueprint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Botón de pago
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _creandoPago ? null : (_metodoSeleccionado == 'mp' ? _iniciarMP : _acordarEnPersona),
            icon: _creandoPago
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_metodoSeleccionado == 'mp' ? Icons.credit_card : Icons.check_circle_outline, size: 20),
            label: Text(
              _creandoPago
                  ? 'Procesando...'
                  : (_metodoSeleccionado == 'mp' ? 'Pagar con MercadoPago' : 'Confirmar Acuerdo'),
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
      ],
    );
  }

  Widget _buildEsperando() {
    final theme = Theme.of(context);
    final progreso = (_pollingSegundos / _maxPollingSegundos).clamp(0.0, 1.0);
    final restantes = (_maxPollingSegundos - _pollingSegundos).clamp(
      0,
      _maxPollingSegundos,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl2),
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                      const Icon(
                        Icons.hourglass_empty,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                Text(
                  'Esperando confirmación',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Completa el pago en la ventana de MercadoPago.\nEsta pantalla se actualizará automáticamente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),
                LinearProgressIndicator(
                  value: progreso,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Verificando pago · ${restantes}s restantes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        OutlinedButton(
          onPressed: _consultarEstado,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
          child: const Text('Consultar ahora'),
        ),
      ],
    );
  }

  Widget _buildAprobado() {
    final theme = Theme.of(context);
    final monto = _estadoPago?['monto'] as num?;

    return Card(
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
                color: AppColors.success.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 36,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Pago aprobado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'El pago fue procesado exitosamente.\nEl proveedor ha sido notificado.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (monto != null) ...[
              const SizedBox(height: Spacing.xl),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: Spacing.sm),
              _montoRow(
                theme,
                'Monto pagado',
                '\$${_fmt(monto)}',
                theme.colorScheme.onSurface,
              ),
              Divider(color: theme.colorScheme.outlineVariant),
              _montoRow(
                theme,
                'Monto del servicio',
                '\$${_fmt(monto)}',
                AppColors.success,
              ),
            ],
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () =>
                    context.go('/contratacion/${widget.contratacionId}'),
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text('Ver contratación'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildRechazado() {
    final theme = Theme.of(context);
    return Card(
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
                color: AppColors.danger.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Pago rechazado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'El pago no pudo ser procesado.\nVerifica los datos e intenta nuevamente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reintentar pago'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeout() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: Column(
          children: [
            const Icon(Icons.access_time, color: AppColors.primary, size: 56),
            const SizedBox(height: Spacing.xl),
            Text(
              'Tiempo de espera agotado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'No detectamos la confirmación en 2 minutos. Podés consultar manualmente.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _consultarEstado,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: const Text('Consultar'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.go('/contratacion/${widget.contratacionId}'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 56),
            const SizedBox(height: Spacing.xl),
            Text(
              'Error al crear pago',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            if (_errorMsg != null)
              Text(
                _errorMsg!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _reintentar,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Reintentar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(num v) => v.toStringAsFixed(0);

  Widget _montoRow(ThemeData theme, String label, String valor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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

enum _PagoState { inicial, esperando, aprobado, rechazado, timeout, error }

// ─── Widget selector de método ─────────────────────────

class _MetodoTile extends StatelessWidget {
  final IconData icon;
  final String nombre;
  final String descripcion;
  final bool selected;
  final VoidCallback onTap;

  const _MetodoTile({
    required this.icon,
    required this.nombre,
    required this.descripcion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? AppColors.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? AppColors.primary.withValues(alpha: 0.04)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Express Pay Button ────────────────────────────────

class _ExpressPayButton extends StatelessWidget {
  final bool isApple;
  final VoidCallback onTap;

  const _ExpressPayButton({required this.isApple, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isApple ? Colors.black : Colors.white,
          foregroundColor: isApple ? Colors.white : Colors.black,
          side: isApple
              ? null
              : BorderSide(color: Colors.grey.shade300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isApple
                ? const Icon(Icons.apple, size: 22, color: Colors.white)
                : RichText(
                    text: TextSpan(
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                        letterSpacing: -1.2,
                      ),
                      children: const [
                        TextSpan(
                          text: 'G',
                          style: TextStyle(color: AppColors.blueprint),
                        ),
                        TextSpan(
                          text: 'o',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        TextSpan(
                          text: 'o',
                          style: TextStyle(color: AppColors.amber),
                        ),
                        TextSpan(
                          text: 'g',
                          style: TextStyle(color: AppColors.blueprint),
                        ),
                        TextSpan(
                          text: 'l',
                          style: TextStyle(color: AppColors.success),
                        ),
                        TextSpan(
                          text: 'e',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(width: Spacing.xs),
            Text(
              'Pay',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isApple ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Express Pay Modal ─────────────────────────────────

class _ExpressPayModal extends StatefulWidget {
  final bool isApple;
  final double monto;
  final VoidCallback onSuccess;

  const _ExpressPayModal({
    required this.isApple,
    required this.monto,
    required this.onSuccess,
  });

  @override
  State<_ExpressPayModal> createState() => _ExpressPayModalState();
}

class _ExpressPayModalState extends State<_ExpressPayModal>
    with SingleTickerProviderStateMixin {
  String _status = 'ready'; // ready, scanning, success
  late AnimationController _animController;
  Timer? _authTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _authTimer?.cancel();
    super.dispose();
  }

  void _startAuth() {
    setState(() {
      _status = 'scanning';
    });
    _animController.repeat();
    _authTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _status = 'success';
      });
      _animController.stop();
      // Wait for success visual confirmation before returning
      Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        widget.onSuccess();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.isApple
        ? (isDark ? AppColors.paper : AppColors.paper)
        : (isDark ? AppColors.card : Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.only(
        left: Spacing.xl,
        right: Spacing.xl,
        top: Spacing.lg,
        bottom: Spacing.xl3,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header handle bar
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Pay brand logo header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.isApple
                    ? const Icon(Icons.apple, size: 24, color: Colors.white)
                    : RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            fontFamily: 'Roboto',
                            letterSpacing: -1.2,
                          ),
                          children: [
                            TextSpan(
                              text: 'G',
                              style: TextStyle(color: AppColors.blueprint),
                            ),
                            TextSpan(
                              text: 'o',
                              style: TextStyle(color: AppColors.danger),
                            ),
                            TextSpan(
                              text: 'o',
                              style: TextStyle(color: AppColors.amber),
                            ),
                            TextSpan(
                              text: 'g',
                              style: TextStyle(color: AppColors.blueprint),
                            ),
                            TextSpan(
                              text: 'l',
                              style: TextStyle(color: AppColors.success),
                            ),
                            TextSpan(
                              text: 'e',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(width: Spacing.xs),
                Text(
                  'Pay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: widget.isApple ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),

            // Card details card
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isApple
                          ? Colors.black
                          : AppColors.blueprint,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.isApple ? 'VISA' : 'MC',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isApple
                              ? 'Visa •••• 4242'
                              : 'Mastercard •••• 9876',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.isApple
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          'Garantía de TrabajoYa',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${widget.monto.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: widget.isApple
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl2),

            // Authentication scanning area
            Center(
              child: GestureDetector(
                onTap: _status == 'ready' ? _startAuth : null,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(Spacing.xs),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _status == 'success'
                                  ? AppColors.success
                                  : _status == 'scanning'
                                  ? AppColors.primary
                                  : Colors.grey.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: _status == 'success'
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.success,
                                    size: 56,
                                  )
                                : _status == 'scanning'
                                ? RotationTransition(
                                    turns: _animController,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        widget.isApple
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                      strokeWidth: 4,
                                    ),
                                  )
                                : Icon(
                                    widget.isApple
                                        ? Icons.face_retouching_natural
                                        : Icons.fingerprint,
                                    color: widget.isApple
                                        ? Colors.white70
                                        : Colors.black87,
                                    size: 48,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      _status == 'success'
                          ? 'Pago Verificado'
                          : _status == 'scanning'
                          ? (widget.isApple
                                ? 'Verificando con Face ID...'
                                : 'Escaneando Huella...')
                          : (widget.isApple
                                ? 'Toca para verificar con Face ID'
                                : 'Toca para verificar con Huella'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _status == 'success'
                            ? AppColors.success
                            : _status == 'scanning'
                            ? AppColors.primary
                            : (widget.isApple
                                  ? Colors.white70
                                  : Colors.black54),
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
}
