import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/contrataciones/data/datasources/contrataciones_remote_datasource.dart';
import 'package:trabajoya_app/features/servicios/data/datasources/servicios_remote_datasource.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';


class SolicitarServicioScreen extends StatefulWidget {
  final String servicioId;
  const SolicitarServicioScreen({super.key, required this.servicioId});

  @override
  State<SolicitarServicioScreen> createState() =>
      _SolicitarServicioScreenState();
}

class _SolicitarServicioScreenState extends State<SolicitarServicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _budgetController = TextEditingController();

  final ServiciosService _serviciosService = ServiciosService();
  final ContratacionesService _contratacionesService = ContratacionesService();

  Servicio? _servicio;
  bool _loadingServicio = true;
  bool _saving = false;
  DateTime? _fechaProgramada;

  @override
  void initState() {
    super.initState();
    _cargarServicio();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _cargarServicio() async {
    try {
      final s = await _serviciosService.getServicio(widget.servicioId);
      if (mounted) {
        setState(() {
          _servicio = s;
          _loadingServicio = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingServicio = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        setState(() {
          _fechaProgramada = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _precioSugerido(Servicio s) {
    if (s.precioMin == null) return 'A convenir';
    final min = s.precioMin!.toStringAsFixed(0);
    if (s.precioMax == 1.0) return '\$$min / hora';
    if (s.precioMax == 2.0) return '\$$min / servicio';
    return '\$$min';
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _contratacionesService.crearContratacion(
        widget.servicioId,
        monto: _budgetController.text.isNotEmpty
            ? double.tryParse(_budgetController.text)
            : null,
        mensaje: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        fecha: _fechaProgramada,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada con éxito!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final isMobileHead = Breakpoints.isMobile(context);

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: CliColors.border(context)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: CliColors.accent, width: 1.5),
    );

    final s = _servicio;
    final precio = s != null ? _precioSugerido(s) : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: _centered(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ENCABEZADO ---
              Flex(
                direction: isMobileHead ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isMobileHead ? 0 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitar servicio',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: CliColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s != null
                              ? 'Enviá tu solicitud a ${s.proveedorNombre ?? "el proveedor"} para el servicio "${s.titulo}".'
                              : 'Completá el formulario para contactar al proveedor.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: CliColors.textSecondary(context),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMobileHead)
                    const SizedBox(height: Spacing.md)
                  else
                    const SizedBox(width: Spacing.xl),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CliColors.textPrimary(context),
                      backgroundColor: CliColors.surface(context),
                      side: BorderSide(color: CliColors.border(context)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      '← Volver al detalle',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xl2),

              // --- LAYOUT PRINCIPAL ---
              Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna Izquierda: Formulario
                  Expanded(
                    flex: isDesktop ? 12 : 0,
                    child: CliCard(
                      padding: EdgeInsets.all(
                        isMobileHead ? Spacing.lg : Spacing.xl,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Preview del servicio
                            CliCard(
                              padding: const EdgeInsets.all(Spacing.md),
                              child: _loadingServicio
                                  ? const SizedBox(
                                      height: 48,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: CliColors.accent.withValues(alpha: 0.08),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              s?.categoriaIcono ??
                                                  s?.subcategoriaIcono ??
                                                  '🛠',
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: Spacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s?.titulo ?? '—',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: CliColors.textPrimary(context),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                s?.proveedorNombre ?? '—',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          CliColors.textSecondary(context),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (precio != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CliColors.accent.withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Radii.pill,
                                                  ),
                                            ),
                                            child: Text(
                                              precio,
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: CliColors.accent,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: Spacing.xl),

                            // Campo: Mensaje
                            const CliSectionHeader(title: 'Mensaje'),
                            const SizedBox(height: Spacing.sm),
                            TextFormField(
                              controller: _messageController,
                              maxLines: null,
                              minLines: 6,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText:
                                    'Describe lo que necesitas, el contexto del trabajo y cualquier detalle importante.',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: CliColors.textSecondary(context),
                                ),
                                fillColor: CliColors.surface(context),
                                filled: true,
                                contentPadding: const EdgeInsets.all(18),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  borderSide: BorderSide(
                                    color: CliColors.border(context),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  borderSide: BorderSide(
                                    color: CliColors.accent,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  borderSide: BorderSide(
                                    color: AppTheme.danger,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(Radii.md),
                                  borderSide: BorderSide(
                                    color: AppTheme.danger,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'El mensaje es requerido'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Campo: Monto Ofrecido
                            TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Monto ofrecido (opcional)',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: CliColors.textSecondary(context),
                                ),
                                fillColor: CliColors.surface(context),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                enabledBorder: inputBorder,
                                focusedBorder: focusBorder,
                              ),
                            ),
                            if (precio != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4),
                                child: Text(
                                  'Sugerido: $precio',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: CliColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Campo: Fecha programada
                            GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: _fechaProgramada != null
                                        ? _formatDate(_fechaProgramada!)
                                        : 'Seleccioná fecha y hora',
                                    hintStyle: TextStyle(
                                      color: _fechaProgramada != null
                                          ? CliColors.textPrimary(context)
                                          : CliColors.textSecondary(context),
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.all(14.0),
                                      child: Text(
                                        '📅',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    suffixIcon: _fechaProgramada != null
                                        ? IconButton(
                                            tooltip: 'Limpiar fecha',
                                            icon: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: CliColors.textSecondary(context),
                                            ),
                                            onPressed: () => setState(
                                              () => _fechaProgramada = null,
                                            ),
                                          )
                                        : null,
                                    fillColor: CliColors.surface(context),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusBorder,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Fecha programada (opcional)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: CliColors.textSecondary(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Botón de Envío
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _saving ? null : _enviarSolicitud,
                                style: FilledButton.styleFrom(
                                  backgroundColor: CliColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Radii.md),
                                  ),
                                  elevation: 0,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Enviar solicitud',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isDesktop)
                    const SizedBox(width: 22)
                  else
                    const SizedBox(height: 22),

                  // Columna Derecha: Panel de Resumen
                  SizedBox(
                    width: isDesktop ? 400 : double.infinity,
                    child: CliCard(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CliSectionHeader(title: 'Resumen'),
                          const SizedBox(height: Spacing.md),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              if (s?.proveedorNombre != null)
                                _SummaryChip(
                                  label: '👤 ${s!.proveedorNombre!}',
                                ),
                              if (s?.categoriaNombre != null)
                                _SummaryChip(
                                  label:
                                      '${s!.categoriaIcono ?? '🧩'} ${s.categoriaNombre!}',
                                ),
                              if (s?.subcategoriaNombre != null)
                                _SummaryChip(
                                  label:
                                      '${s!.subcategoriaIcono ?? '•'} ${s.subcategoriaNombre!}',
                                ),
                              if (s != null && s.isActivo)
                                const _SummaryChip(label: '✅ Servicio activo'),
                              const _SummaryChip(label: '💬 Mensaje requerido'),
                              const _SummaryChip(label: '📅 Fecha opcional'),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Bloque destacado oscuro
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Radii.md),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  CliColors.accent,
                                  CliColors.accent.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (s?.titulo != null) ...[
                                  Text(
                                    s!.titulo,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  precio != null
                                      ? 'Precio del servicio: $precio'
                                      : 'El proveedor recibirá tu solicitud y podrá aceptarla o rechazarla.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Column(
                            children: [
                              _InfoItemRow(
                                title: 'Mensaje claro',
                                subtitle:
                                    'Explica el trabajo y evita ambigüedad.',
                              ),
                              SizedBox(height: 10),
                              _InfoItemRow(
                                title: 'Monto sugerido',
                                subtitle: 'Sirve para negociar sin fricción.',
                              ),
                              SizedBox(height: 10),
                              _InfoItemRow(
                                title: 'Programación',
                                subtitle:
                                    'Agrega una fecha solo si ya la tienes definida.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: CliColors.border(context)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: CliColors.textSecondary(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoItemRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoItemRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CliColors.surface(context),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: CliColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: CliColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: CliColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
