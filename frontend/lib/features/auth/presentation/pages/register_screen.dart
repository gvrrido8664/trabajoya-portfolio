import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trabajoya_app/core/api/constants.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/role_toggle_button.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class RegisterScreen extends StatefulWidget {
  /// Intención preseleccionada desde la landing (?rol=cliente|proveedor).
  /// Toda cuenta nace cliente igual — esto solo decide qué opción del
  /// toggle aparece marcada al entrar.
  final String? initialRol;

  const RegisterScreen({super.key, this.initialRol});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _referidoCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  late bool _isCliente = widget.initialRol != 'proveedor';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showReferralField = false;
  bool _aceptaTerminos = false;
  // Guardia síncrona contra doble-submit: auth.loading recién se activa
  // dentro de auth.register() (tras un await), así que un 2º clic muy rápido
  // entra antes de que el botón se deshabilite y dispara un POST duplicado.
  bool _submitting = false;

  String _codigoPaisSeleccionado = '+56';
  int _currentStep = 0;

  final List<Map<String, String>> _paisesCodigos = [
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chile'},
    {'code': '+54', 'flag': '🇦🇷', 'name': 'Argentina'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Perú'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombia'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'México'},
  ];

  Color get _roleColor => AppColors.rust;
  Color get _roleLightColor => AppColors.rustTint;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _referidoCtrl.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _validateStep2() {
    final telefono = _telefonoCtrl.text.trim();
    if (telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El teléfono es obligatorio')),
      );
      return false;
    }
    // El campo Teléfono (paso "Validar") no vive dentro de un flujo que
    // llame Form.validate() al enviar -- _handleRegister() solo pasa por
    // acá, así que su propio `validator:` nunca se dispara. El chequeo de
    // formato tiene que vivir en esta función para que de verdad bloquee.
    final digits = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8 || digits.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un teléfono válido')),
      );
      return false;
    }
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return false;
    }
    return true;
  }

  void _handleRegister() async {
    if (!_validateStep2()) return;
    if (_submitting) return;
    _submitting = true;

    final auth = context.read<AuthProvider>();
    // Toda cuenta nace cliente; el toggle solo expresa intención — si
    // eligió "Proveedor", lo encadenamos a verificación de identidad, que
    // es el único camino real para habilitar esa capacidad.
    final quiereOfrecerServicios = !_isCliente;
    final telefonoCompleto =
        '$_codigoPaisSeleccionado${_telefonoCtrl.text.trim()}';
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      rol: 'cliente',
      telefono: telefonoCompleto,
      ref: _referidoCtrl.text.trim().isEmpty ? null : _referidoCtrl.text.trim(),
    );
    _submitting = false;
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cuenta creada exitosamente'),
          backgroundColor: _roleColor,
        ),
      );
      if (!mounted) return;
      if (auth.usuario?.esProveedor ?? false) {
        context.go('/proveedor');
      } else if (quiereOfrecerServicios) {
        context.go('/seguridad/identidad');
      } else {
        context.go('/cliente');
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al crear la cuenta'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          bodySmall: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      child: AuthScaffold(
        onHome: () => context.go('/'),
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        maxWidth: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthPanel(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Eyebrow(label: 'Crear cuenta'),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _buildStepIndicator(),
                    const SizedBox(height: Spacing.xl),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepContent(auth),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿Ya tienes cuenta? ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Text(
                      'Inicia sesión',
                      style: TextStyle(
                        color: _roleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocialRegister(String providerName) async {
    if (providerName != 'Google') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$providerName Sign-In estará disponible próximamente.',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }
    final intent = _isCliente ? 'cliente' : 'proveedor';
    if (kIsWeb) {
      // Flujo por redirect de página completa: navega la pestaña actual a
      // Google, que vuelve al backend y de ahí a /auth/google/callback.
      await launchUrl(
        Uri.parse('$apiBaseUrl/auth/google/login?intent=$intent'),
        webOnlyWindowName: '_self',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final quiereOfrecerServicios = !_isCliente;
    final success = await auth.loginWithGoogle(rol: 'cliente');
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cuenta de Google conectada exitosamente'),
          backgroundColor: _roleColor,
        ),
      );
      if (auth.usuario?.esProveedor ?? false) {
        context.go('/proveedor');
      } else if (quiereOfrecerServicios) {
        context.go('/seguridad/identidad');
      } else {
        context.go('/cliente');
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al registrar con $providerName'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'Uso'),
        _buildStepDivider(0),
        _buildStepDot(1, 'Datos'),
        _buildStepDivider(1),
        _buildStepDot(2, 'Validar'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final color = isCompleted
        ? _roleColor
        : (isActive
              ? _roleColor
              : Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4));

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.surface
                : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isActive ? 5 : 2),
          ),
          child: isCompleted
              ? Icon(Icons.check, size: 14, color: _roleColor)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
        height: 2,
        color: isCompleted ? _roleColor : Theme.of(context).colorScheme.outline,
      ),
    );
  }

  String? valueTextCheck(String? v, String msg) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  Widget _buildStepContent(AuthProvider auth) {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo quieres usar TrabajoYa?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Elige por dónde empezar — puedes cambiarlo después desde tu perfil',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RoleToggleButton(
                      label: '👥 Cliente',
                      isActive: _isCliente,
                      activeColor: _roleColor,
                      activeLightColor: _roleLightColor,
                      onTap: () => setState(() => _isCliente = true),
                    ),
                  ),
                  Expanded(
                    child: RoleToggleButton(
                      label: '🧰 Proveedor',
                      isActive: !_isCliente,
                      activeColor: _roleColor,
                      activeLightColor: _roleLightColor,
                      onTap: () => setState(() => _isCliente = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tarjeta explicativa del rol
            // _roleLightColor es un tono pastel pensado para tema claro --
            // con alpha 0.5 sobre fondo oscuro (tema del sistema) se veía
            // como una tarjeta gris lavado, inconsistente con el resto de
            // la pantalla. En oscuro se tiñe con el color de acento en vez.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? _roleColor.withValues(alpha: 0.15)
                    : _roleLightColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: _roleColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isCliente) ...[
                    Text(
                      'Como Cliente podrás:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _roleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _roleBullet(
                      'Buscar y contratar profesionales calificados.',
                    ),
                    _roleBullet(
                      'Publicar solicitudes de trabajo personalizadas.',
                    ),
                    _roleBullet(
                      'Pagar de forma segura y calificar proveedores.',
                    ),
                  ] else ...[
                    // La verificación es un requisito real antes de poder
                    // publicar servicios, así que va primero y con más peso
                    // visual que las promesas que dependen de ella.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: _roleColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Para publicar servicios, primero verificamos tu identidad (gratis, toma unos minutos).',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _roleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Una vez verificado, vas a poder:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _roleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _roleBullet('Crear tu perfil y publicar tus servicios.'),
                    _roleBullet('Enviar propuestas a solicitudes de clientes.'),
                    _roleBullet('Recibir pagos y construir tu reputación.'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _roleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Siguiente paso',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tus datos de acceso',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Ingresa tus datos básicos para registrarte',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(Icons.person_outline, 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apellidoCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(Icons.person_outline, 'Apellido'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa tu apellido'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(Icons.mail_outline, 'Email'),
              validator: (v) {
                final email = (v ?? '').trim();
                if (email.isEmpty ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              validator: (v) {
                final pass = v ?? '';
                if (pass.length < 8) {
                  return 'La contraseña debe tener mínimo 8 caracteres';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(pass) ||
                    !RegExp(r'[0-9]').hasMatch(pass)) {
                  return 'Debe incluir al menos una letra y un número';
                }
                return null;
              },
              decoration: _inputDecoration(Icons.lock_outline, 'Contraseña')
                  .copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _passwordFocus.requestFocus(),
                        );
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordCtrl,
              focusNode: _confirmPasswordFocus,
              obscureText: _obscureConfirmPassword,
              validator: (v) => (v != _passwordCtrl.text)
                  ? 'Las contraseñas no coinciden'
                  : null,
              decoration:
                  _inputDecoration(
                    Icons.enhanced_encryption_outlined,
                    'Confirmar contraseña',
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _confirmPasswordFocus.requestFocus(),
                        );
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Atrás',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _currentStep = 2);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'O registrarse con',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  // SizedBox explícito: minimumSize solo no bastaba para
                  // llegar a 44px reales -- VisualDensity.adaptivePlatformDensity
                  // (default de ThemeData) lo comprime en desktop/web (A11Y-01).
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSocialRegister('Google'),
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 18,
                      ),
                      label: const Text(
                        'Google',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSocialRegister('Apple'),
                      icon: Icon(
                        Icons.apple,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      label: const Text(
                        'Apple',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 2:
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contacto y confirmación',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Completa tu registro para continuar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 105,
                  height: 46,
                  child: DropdownButtonFormField<String>(
                    initialValue: _codigoPaisSeleccionado,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        borderSide: const BorderSide(
                          color: AppColors.ink,
                          width: 2,
                        ),
                      ),
                    ),
                    items: _paisesCodigos
                        .map(
                          (pais) => DropdownMenuItem<String>(
                            value: pais['code'],
                            child: Text(
                              '${pais['flag']} ${pais['code']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _codigoPaisSeleccionado = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(null, 'Teléfono').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    // Feedback visual en vivo mientras el usuario escribe.
                    // OJO: este paso ("Validar") no pasa por
                    // Form.validate() al enviar -- el bloqueo real está en
                    // _validateStep2() (mismo chequeo, duplicado a
                    // propósito porque ese es el que de verdad se ejecuta).
                    validator: (v) {
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) return 'El teléfono es obligatorio';
                      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 8 || digits.length > 12) {
                        return 'Ingresa un teléfono válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showReferralField = !_showReferralField),
                icon: Icon(
                  _showReferralField
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                  color: _roleColor,
                ),
                label: Text(
                  '¿Tienes un código de referido?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _roleColor,
                  ),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
            if (_showReferralField) ...[
              TextFormField(
                controller: _referidoCtrl,
                decoration: _inputDecoration(
                  Icons.card_giftcard,
                  'Código de referido (Opcional)',
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _aceptaTerminos,
                  activeColor: _roleColor,
                  onChanged: (v) =>
                      setState(() => _aceptaTerminos = v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _aceptaTerminos = !_aceptaTerminos),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'Acepto los '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => context.push('/terminos'),
                              child: Text(
                                'Términos y condiciones',
                                style: TextStyle(
                                  color: AppColors.blueprint,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' y la '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => context.push('/privacidad'),
                              child: Text(
                                'Política de privacidad',
                                style: TextStyle(
                                  color: AppColors.blueprint,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Atrás',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: auth.loading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: auth.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _roleBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: _roleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData? prefixIcon, String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: cs.onSurfaceVariant, size: 18)
          : null,
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // Sin esto, mensajes de error largos ("La contraseña debe tener
      // mínimo 8 caracteres") se truncaban con ellipsis en vez de
      // envolver a una 2da línea.
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: cs.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }
}
