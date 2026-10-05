import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/constants/comunas.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/contrataciones/data/datasources/contrataciones_remote_datasource.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/help_modal.dart';
import 'package:trabajoya_app/shared/widgets/avatar_editor.dart';
import 'package:trabajoya_app/shared/widgets/corner_border_container.dart';
import 'package:trabajoya_app/shared/utils/unsaved_changes.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ProfileAmplioScreen extends StatefulWidget {
  const ProfileAmplioScreen({super.key});

  @override
  State<ProfileAmplioScreen> createState() => _ProfileAmplioScreenState();
}

class _ProfileAmplioScreenState extends State<ProfileAmplioScreen> {
  int _solicitudesCount = 0;
  int _contratacionesCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarMetricas());
  }

  Future<void> _cargarMetricas() async {
    try {
      final sols = await SolicitudesService().getMisSolicitudes();
      final cons = await ContratacionesService().getMisContrataciones();
      if (mounted) {
        setState(() {
          _solicitudesCount = sols.where((s) => s.isAbierta).length;
          _contratacionesCount = cons.length;
        });
      }
    } catch (_) {}
  }

  void _mostrarEditarPerfil(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => _EditarPerfilDialog(auth: auth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.usuario;
    final width = MediaQuery.of(context).size.width;

    final isWideScreen = width > 760;

    final userName = user?.nombreCompleto ?? 'Sin nombre';
    final userEmail = user?.email ?? '—';
    final userComuna = user?.comuna;
    final userLocation = (userComuna != null && userComuna.isNotEmpty)
        ? '$userComuna, Santiago'
        : 'No especificada';
    final userRating = user?.avgRatingCliente ?? 0.0;
    final emailVerificado = user?.emailVerificado ?? false;
    final isIdentidadVerificada = user?.docEstado == 'aprobado' || emailVerificado;
    final joinYear = user?.createdAt.year ?? 2026;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 40 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TARJETA RESUMEN DE PERFIL ──
                CornerBorderContainer(
                  backgroundColor: AppColors.card,
                  padding: EdgeInsets.all(isWideScreen ? 28 : 20),
                  child: isWideScreen
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto, Nombre, Email/Comuna, Badge
                            Expanded(
                              flex: 6,
                              child: Row(
                                children: [
                                  AvatarEditor(
                                    avatarUrl: user?.avatarUrl,
                                    radius: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$userEmail · $userLocation',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isIdentidadVerificada
                                                ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                                : AppColors.rust.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: isIdentidadVerificada
                                                    ? const Color(0xFF2E7D32)
                                                    : AppColors.rust,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isIdentidadVerificada
                                                    ? 'IDENTIDAD VERIFICADA'
                                                    : 'PENDIENTE VERIFICACIÓN',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: isIdentidadVerificada
                                                      ? const Color(0xFF2E7D32)
                                                      : AppColors.rust,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 70,
                              width: 1,
                              color: AppColors.border,
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            // Estadísticas
                            Expanded(
                              flex: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _StatItem(
                                    number: '$_contratacionesCount',
                                    label: 'Contrataciones',
                                  ),
                                  _StatItem(
                                    number: userRating > 0
                                        ? '${userRating.toStringAsFixed(1)} ★'
                                        : 'N/A',
                                    label: 'Calificación dada',
                                  ),
                                  _StatItem(
                                    number: '$joinYear',
                                    label: 'Cliente desde',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                AvatarEditor(
                                  avatarUrl: user?.avatarUrl,
                                  radius: 28,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$userEmail · $userLocation',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isIdentidadVerificada
                                    ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                                    : AppColors.rust.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: isIdentidadVerificada
                                        ? const Color(0xFF2E7D32)
                                        : AppColors.rust,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isIdentidadVerificada
                                        ? 'IDENTIDAD VERIFICADA'
                                        : 'PENDIENTE VERIFICACIÓN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isIdentidadVerificada
                                          ? const Color(0xFF2E7D32)
                                          : AppColors.rust,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  number: '$_contratacionesCount',
                                  label: 'Contrataciones',
                                ),
                                _StatItem(
                                  number: userRating > 0
                                      ? '${userRating.toStringAsFixed(1)} ★'
                                      : 'N/A',
                                  label: 'Calificación dada',
                                ),
                                _StatItem(
                                  number: '$joinYear',
                                  label: 'Cliente desde',
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 32),

                // ── SECCIÓN "CUENTA" ──
                const Text(
                  'Cuenta',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),

                // ── LISTA DE MENÚS DESPLEGABLES ──
                CornerBorderContainer(
                  backgroundColor: AppColors.card,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // 1. Editar perfil
                      _ProfileExpandableItem(
                        icon: Icons.person_outline,
                        title: 'Editar perfil',
                        subtitle: 'Nombre, teléfono y dirección',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nombre: $userName', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                            const SizedBox(height: 4),
                            Text('Teléfono: ${user?.telefono ?? "No registrado"}', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                            const SizedBox(height: 4),
                            Text('Comuna: $userLocation', style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarEditarPerfil(auth),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Editar información'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.rust,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 70),

                      // 2. Métodos de pago
                      _ProfileExpandableItem(
                        icon: Icons.credit_card_outlined,
                        title: 'Métodos de pago',
                        subtitle: 'Tarjetas guardadas y facturación',
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actualmente tus pagos se procesan de forma segura al solicitar servicios.',
                              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 70),

                      // 3. Notificaciones
                      _ProfileExpandableItem(
                        icon: Icons.mail_outline,
                        title: 'Notificaciones',
                        subtitle: 'Estado de las alertas en la plataforma',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SecurityStatusRow(
                              title: 'Mensajes de Chat',
                              subtitle: 'Recibes notificaciones en la campanita cuando un proveedor te escribe.',
                              status: 'Activo',
                              statusColor: const Color(0xFF2E7D32),
                            ),
                            const SizedBox(height: 12),
                            _SecurityStatusRow(
                              title: 'Notificaciones por correo',
                              subtitle: 'Aún no disponible. Próximamente recibirás alertas en tu email.',
                              status: 'Próximamente',
                              statusColor: const Color(0xFF6A1B9A),
                            ),
                            const SizedBox(height: 12),
                            _SecurityStatusRow(
                              title: 'Notificaciones push (app)',
                              subtitle: 'Aún no disponible. Próximamente recibirás alertas en tu dispositivo.',
                              status: 'Próximamente',
                              statusColor: const Color(0xFF6A1B9A),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 70),

                      // 4. Seguridad
                      _ProfileExpandableItem(
                        icon: Icons.lock_outline,
                        title: 'Seguridad',
                        subtitle: 'Contraseña y verificación en dos pasos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SecurityStatusRow(
                              title: 'Correo verificado',
                              subtitle: 'Tu correo principal está validado para iniciar sesión y recuperar acceso.',
                              status: emailVerificado ? 'Verificado' : 'Pendiente',
                              statusColor: emailVerificado ? const Color(0xFF2E7D32) : AppColors.rust,
                            ),
                            const SizedBox(height: 12),
                            _SecurityStatusRow(
                              title: 'Teléfono confirmado',
                              subtitle: 'Tu número está disponible para coordinación con proveedores.',
                              status: (user?.telefono != null && (user!.telefono!.isNotEmpty)) ? 'Activo' : 'Pendiente',
                              statusColor: (user?.telefono != null && (user!.telefono!.isNotEmpty)) ? const Color(0xFF1565C0) : AppColors.rust,
                            ),
                            const SizedBox(height: 12),
                            _SecurityStatusRow(
                              title: 'Verificación de identidad',
                              subtitle: 'Verifica tu identidad para aumentar la confianza de los proveedores.',
                              status: user?.docEstado == 'aprobado' ? 'Aprobado' : 'Pendiente',
                              statusColor: user?.docEstado == 'aprobado' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                              onTap: user?.docEstado != 'aprobado' ? () => context.push('/verificacion-identidad') : null,
                            ),
                            const SizedBox(height: 12),
                            _SecurityStatusRow(
                              title: 'Cambio de contraseña',
                              subtitle: 'Te conviene actualizarla si no lo has hecho recientemente.',
                              status: 'Recomendado',
                              statusColor: const Color(0xFF6A1B9A),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/totp-setup'),
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: const Text('Verificación en dos pasos'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 70),

                      // 5. Ayuda y soporte
                      _ProfileExpandableItem(
                        icon: Icons.help_outline,
                        title: 'Ayuda y soporte',
                        subtitle: 'Preguntas frecuentes y contacto',
                        onTapOverride: () => showHelpModal(context),
                        child: const SizedBox.shrink(),
                      ),
                      const Divider(height: 1, indent: 70),

                      // 6. Cerrar sesión
                      _ProfileExpandableItem(
                        icon: Icons.logout,
                        title: 'Cerrar sesión',
                        subtitle: 'Salir de la cuenta de forma segura',
                        isDanger: true,
                        onTapOverride: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                              title: const Text(
                                'Cerrar sesión',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                '¿Estás seguro que querés cerrar sesión?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.rust,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Cerrar sesión'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await context.read<AuthProvider>().logout();
                            if (context.mounted) context.go('/login');
                          }
                        },
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _ProfileExpandableItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDanger;
  final VoidCallback? onTapOverride;

  const _ProfileExpandableItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.isDanger = false,
    this.onTapOverride,
  });

  @override
  State<_ProfileExpandableItem> createState() => _ProfileExpandableItemState();
}

class _ProfileExpandableItemState extends State<_ProfileExpandableItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titleColor = widget.isDanger ? AppColors.rust : AppColors.ink;
    final iconBg = widget.isDanger
        ? AppColors.rust.withValues(alpha: 0.1)
        : AppColors.background;
    final iconColor = widget.isDanger ? AppColors.rust : AppColors.inkSoft;

    return Column(
      children: [
        InkWell(
          onTap: widget.onTapOverride ?? () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Icon(
                    widget.icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  widget.onTapOverride != null
                      ? Icons.chevron_right
                      : (_expanded ? Icons.keyboard_arrow_down : Icons.chevron_right),
                  color: AppColors.inkSoft,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_expanded && widget.onTapOverride == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(80, 0, 20, 16),
            child: widget.child,
          ),
      ],
    );
  }
}

class _NotificationSwitchRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NotificationSwitchRow> createState() => _NotificationSwitchRowState();
}

class _NotificationSwitchRowState extends State<_NotificationSwitchRow> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        Switch(
          value: _val,
          activeColor: AppColors.rust,
          onChanged: (v) {
            setState(() => _val = v);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────── DIALOGS ────────────────────────────────────

class _EditarPerfilDialog extends StatefulWidget {
  final AuthProvider auth;

  const _EditarPerfilDialog({required this.auth});

  @override
  State<_EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<_EditarPerfilDialog> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _comunaCtrl;
  final _actualPassCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  final _actualPassFocus = FocusNode();
  final _nuevaPassFocus = FocusNode();
  bool _saving = false;
  bool _showPasswordSection = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  String? _regionSeleccionada;
  bool _dirty = false;
  void _markDirty() => _dirty = true;

  String _codigoPais = '+56';
  static const _paises = [
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chile'},
    {'code': '+54', 'flag': '🇦🇷', 'name': 'Argentina'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Perú'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombia'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'México'},
    {'code': '+55', 'flag': '🇧🇷', 'name': 'Brasil'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'EE.UU.'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'España'},
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.auth.usuario?.nombre);
    _apellidoCtrl = TextEditingController(text: widget.auth.usuario?.apellido);
    _comunaCtrl = TextEditingController(text: widget.auth.usuario?.comuna);

    if (widget.auth.usuario?.comuna != null) {
      for (final entry in ComunasChile.regionesYComunas.entries) {
        if (entry.value.contains(widget.auth.usuario!.comuna!)) {
          _regionSeleccionada = entry.key;
          break;
        }
      }
    }

    // Separar código de país del número guardado
    final telefonoRaw = widget.auth.usuario?.telefono ?? '';
    final codigoMatch = _paises.firstWhere(
      (p) => telefonoRaw.startsWith(p['code']!),
      orElse: () => _paises.first,
    );
    _codigoPais = codigoMatch['code']!;
    final soloNumero = telefonoRaw.startsWith(_codigoPais)
        ? telefonoRaw.substring(_codigoPais.length)
        : telefonoRaw;
    _telefonoCtrl = TextEditingController(text: soloNumero);

    for (final c in [_nombreCtrl, _apellidoCtrl, _telefonoCtrl, _comunaCtrl, _nuevaPassCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _comunaCtrl.dispose();
    _telefonoCtrl.dispose();
    _actualPassCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _actualPassFocus.dispose();
    _nuevaPassFocus.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_saving) return;
    // Ni el backend ni este diálogo (usa TextField suelto, no Form) exigían
    // nombre/apellido no vacíos -- se podía guardar un perfil en blanco.
    if (_nombreCtrl.text.trim().isEmpty || _apellidoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y apellido son obligatorios')),
      );
      return;
    }
    setState(() => _saving = true);

    // 1. Guardar perfil
    final telefonoCompleto = _telefonoCtrl.text.trim().isEmpty
        ? ''
        : '$_codigoPais${_telefonoCtrl.text.trim()}';
    final okPerfil = await widget.auth.actualizarPerfil(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      telefono: telefonoCompleto,
      comuna: _comunaCtrl.text.trim(),
    );

    // 2. Cambiar contraseña si se llenaron los campos
    bool okPass = true;
    String? passError;
    if (_actualPassCtrl.text.isNotEmpty && _nuevaPassCtrl.text.isNotEmpty) {
      okPass = await widget.auth.changePassword(
        _actualPassCtrl.text,
        _nuevaPassCtrl.text,
      );
      if (!okPass) passError = widget.auth.error;
    }

    if (!mounted) return;
    Navigator.pop(context);

    String msg;
    bool success;
    if (okPerfil && okPass) {
      msg = _actualPassCtrl.text.isNotEmpty
          ? 'Perfil y contraseña actualizados.'
          : 'Perfil actualizado.';
      success = true;
    } else if (!okPerfil) {
      msg = widget.auth.error ?? 'Error al actualizar perfil.';
      success = false;
    } else {
      msg = passError ?? 'Error al cambiar contraseña.';
      success = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? Theme.of(context).colorScheme.tertiary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 400 fijo desbordaba en pantallas angostas (<400+64 de insetPadding) --
    // el campo Teléfono quedaba cortado a la mitad del último dígito.
    final maxDialogWidth = MediaQuery.sizeOf(context).width - 64;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await confirmDiscardChanges(context, hasChanges: _dirty) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      title: const Text(
        'Editar perfil',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: maxDialogWidth < 400 ? maxDialogWidth : 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apellidoCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final codigoPaisField = SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_codigoPais),
                      initialValue: _codigoPais,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(color: theme.colorScheme.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _paises
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['code'],
                              child: Text(
                                '${p['flag']} ${p['code']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _codigoPais = v);
                      },
                    ),
                  );
                  final telefonoField = TextField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  );
                  // Con el selector de código de país (110px) al lado, el
                  // campo Teléfono se quedaba sin ancho suficiente para 9
                  // dígitos en diálogos angostos (<340px) y el último dígito
                  // se veía cortado. Se apila en vez de ir lado a lado.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            codigoPaisField,
                            const SizedBox(height: 12),
                            telefonoField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          codigoPaisField,
                          const SizedBox(width: 10),
                          Expanded(child: telefonoField),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _regionSeleccionada,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Región'),
                items: ComunasChile.todasLasRegiones.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _regionSeleccionada = val;
                    _comunaCtrl.clear();
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (_regionSeleccionada != null &&
                        ComunasChile.regionesYComunas[_regionSeleccionada!]!
                            .contains(_comunaCtrl.text))
                    ? _comunaCtrl.text
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Comuna o Ciudad'),
                items: (_regionSeleccionada != null
                        ? ComunasChile.regionesYComunas[_regionSeleccionada!]!
                        : <String>[])
                    .map((comuna) {
                  return DropdownMenuItem(
                    value: comuna,
                    child: Text(comuna, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _regionSeleccionada == null
                    ? null
                    : (val) {
                        setState(() {
                          _comunaCtrl.text = val ?? '';
                        });
                      },
              ),

              // ── Sección de cambiar contraseña (expandible) ──
              const SizedBox(height: 8),
              const Divider(),
              InkWell(
                onTap: () => setState(
                  () => _showPasswordSection = !_showPasswordSection,
                ),
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cambiar contraseña',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        _showPasswordSection
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _showPasswordSection
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actualPassCtrl,
                      focusNode: _actualPassFocus,
                      obscureText: _obscureActual,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureActual
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          tooltip: _obscureActual
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(() => _obscureActual = !_obscureActual);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _actualPassFocus.requestFocus(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nuevaPassCtrl,
                      focusNode: _nuevaPassFocus,
                      obscureText: _obscureNueva,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNueva
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          tooltip: _obscureNueva
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(() => _obscureNueva = !_obscureNueva);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _nuevaPassFocus.requestFocus(),
                            );
                          },
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
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  if (await confirmDiscardChanges(context, hasChanges: _dirty) && context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    ),
    );
  }
}

class _SecurityStatusRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final VoidCallback? onTap;

  const _SecurityStatusRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: row,
    );
  }
}
