import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/propuestas/data/datasources/propuestas_remote_datasource.dart';
import 'package:trabajoya_app/features/propuestas/presentation/providers/propuestas_provider.dart';
import 'package:trabajoya_app/features/suscripciones/presentation/providers/suscripciones_provider.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';

import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/utils/unsaved_changes.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';

class EnviarPropuestaScreen extends StatefulWidget {
  final String solicitudId;
  const EnviarPropuestaScreen({super.key, required this.solicitudId});

  @override
  State<EnviarPropuestaScreen> createState() => _EnviarPropuestaScreenState();
}

class _EnviarPropuestaScreenState extends State<EnviarPropuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final PropuestasService _service = PropuestasService();
  String _solicitudTitulo = '';
  bool _saving = false;
  bool _fetching = true;
  String? _planSlug;
  int _pendientes = 0;
  bool _dirty = false;

  bool get _esBasico => _planSlug != 'premium'; // null o 'basico' → básico

  @override
  void initState() {
    super.initState();
    _cargarSolicitud();
    for (final c in [_descCtrl, _precioCtrl, _tiempoCtrl]) {
      c.addListener(() => _dirty = true);
    }
  }

  Future<void> _volver() async {
    if (await confirmDiscardChanges(context, hasChanges: _dirty) && mounted) {
      context.canPop()
          ? context.pop()
          : context.go('/solicitud/${widget.solicitudId}');
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _tiempoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarSolicitud() async {
    final subProv = context.read<SuscripcionesProvider>();
    final propProv = context.read<PropuestasProvider>();
    try {
      final sol = await SolicitudesService().getSolicitud(widget.solicitudId);
      await Future.wait([
        subProv.cargarSuscripcion(),
        propProv.cargarMisPropuestas(),
      ]);
      if (mounted) {
        final slug = (subProv.miSuscripcion?['plan'] ??
            subProv.miSuscripcion?['plan_slug']) as String?;
        setState(() {
          _solicitudTitulo = sol.titulo;
          _planSlug = slug;
          _pendientes = propProv.propuestas
              .where((p) => p.status.toUpperCase() == 'PENDIENTE')
              .length;
          _fetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Widget _buildPropuestasBanner(TextTheme textTheme) {
    final restantes = (3 - _pendientes).clamp(0, 3);
    final agotado = restantes <= 0;
    final color = agotado ? ProColors.amber : ProColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: ProCard(
        child: Row(
          children: [
            Icon(
              agotado
                  ? Icons.workspace_premium
                  : Icons.info_outline_rounded,
              color: color,
              size: 22,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agotado
                        ? 'Alcanzaste el límite del plan Básico'
                        : 'Te quedan $restantes de 3 propuestas',
                    style: textTheme.titleSmall?.copyWith(
                      color: ProColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agotado
                        ? 'Mejora a Premium para enviar propuestas ilimitadas.'
                        : 'Plan Básico: máximo 3 propuestas pendientes a la vez.',
                    style: textTheme.bodySmall?.copyWith(
                      color: ProColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (agotado) ...[
              const SizedBox(width: Spacing.md),
              ProButton(
                label: 'Mejorar',
                compact: true,
                onPressed: () => context.push('/planes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? ProColors.success : ProColors.danger,
      ),
    );
  }

  void _mostrarDialogoPremium(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: ProColors.amber),
            SizedBox(width: 8),
            Text('¡Mejora a Premium!'),
          ],
        ),
        content: Text(
          '$message\n\n'
          'Con el plan Premium podrás enviar propuestas ilimitadas, destacar tus servicios en los resultados de búsqueda y lucir el sello Premium en tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Más tarde'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/planes');
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // Guardia síncrona: _saving recién se refleja en el botón (ProButton
    // deshabilita con loading:) después del próximo rebuild -- un 2do tap
    // muy rápido podía colarse antes de eso y disparar 2 propuestas.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final precio = double.tryParse(_precioCtrl.text);
    if (precio == null || precio <= 0) {
      _snack('Ingresa un precio válido', ok: false);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.crearPropuesta(
        solicitudId: widget.solicitudId,
        descripcion: _descCtrl.text.trim(),
        precio: precio,
        tiempoEstimado: _tiempoCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Propuesta enviada', ok: true);
      context.pop();
    } on AuthException catch (_) {
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 && e.message.contains('Límite alcanzado')) {
        _mostrarDialogoPremium(e.message);
      } else {
        _snack('Error: ${e.message}', ok: false);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _volver();
      },
      child: ProScaffold(
      title: 'Enviar propuesta',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Volver',
        onPressed: _volver,
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_solicitudTitulo.isNotEmpty) ...[
                        Text(
                          'Respondiendo a la solicitud',
                          style: textTheme.labelMedium?.copyWith(
                            color: ProColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(_solicitudTitulo, style: textTheme.headlineSmall),
                        const SizedBox(height: Spacing.xl),
                      ],
                      if (_esBasico) _buildPropuestasBanner(textTheme),
                      ProCard(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                TextFormField(
                                  controller: _descCtrl,
                                  maxLines: 4,
                                  maxLength: 2000,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción de la propuesta',
                                    alignLabelWithHint: true,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Ingresa el detalle de tu propuesta'
                                      : null,
                                ),
                                const SizedBox(height: Spacing.lg),
                                TextFormField(
                                  controller: _precioCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio total (\$)',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Ingresa un precio';
                                    }
                                    final parsed = double.tryParse(v);
                                    if (parsed == null) {
                                      return 'Formato numérico inválido';
                                    }
                                    if (parsed <= 0) {
                                      return 'El precio debe ser mayor a \$0';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: Spacing.lg),
                                TextFormField(
                                  controller: _tiempoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Tiempo estimado (ej: 3 días)',
                                    prefixIcon: Icon(Icons.schedule_outlined),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Especifica el plazo estimado'
                                      : null,
                                ),
                                const SizedBox(height: Spacing.xl),
                                ProButton(
                                  label: 'Confirmar y enviar',
                                  loading: _saving,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
