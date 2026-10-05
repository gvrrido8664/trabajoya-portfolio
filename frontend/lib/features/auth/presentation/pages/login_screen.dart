import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/core/api/constants.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectTo;

  const LoginScreen({super.key, this.redirectTo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _totpCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      totpCode: auth.mfaRequired ? _totpCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.mfaRequired
                ? 'Ingresa el código de tu app de autenticación'
                : auth.error ?? 'Error al iniciar sesión',
          ),
          backgroundColor: auth.mfaRequired ? null : AppColors.danger,
        ),
      );
      return;
    }
    if (auth.isAdmin) {
      context.go(
        auth.usuario?.totpEnabled == true
            ? (widget.redirectTo ?? '/admin')
            : '/seguridad/2fa',
      );
    } else {
      context.go(
        widget.redirectTo ?? (auth.isProveedorMode ? '/proveedor' : '/cliente'),
      );
    }
  }

  Future<void> _handleSocialLogin(String providerName) async {
    if (providerName != 'Google') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$providerName estará disponible próximamente.'),
        ),
      );
      return;
    }
    if (kIsWeb) {
      await launchUrl(
        Uri.parse('$apiBaseUrl/auth/google/login?intent=cliente'),
        webOnlyWindowName: '_self',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle(rol: 'cliente');
    if (!mounted) return;
    if (success) {
      context.go(auth.isProveedorMode ? '/proveedor' : '/cliente');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al iniciar sesión con Google'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      onHome: () => context.go('/'),
      child: AuthPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Eyebrow(label: 'Acceso'),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Bienvenido de vuelta',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Ingresa a tu cuenta para seguir gestionando tus trabajos.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Spacing.xl),
              AuthField(
                label: 'Correo electrónico',
                child: TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'tucorreo@ejemplo.com',
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'El correo es requerido';
                    if (!RegExp(
                      r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,4}$',
                    ).hasMatch(email)) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: Spacing.lg),
              AuthField(
                label: 'Contraseña',
                child: TextFormField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: auth.mfaRequired
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.mfaRequired) _handleLogin();
                  },
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _passwordFocus.requestFocus(),
                        );
                      },
                    ),
                  ),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'La contraseña es requerida'
                      : null,
                ),
              ),
              if (auth.mfaRequired) ...[
                const SizedBox(height: Spacing.lg),
                AuthField(
                  label: 'Código de verificación',
                  child: TextFormField(
                    controller: _totpCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: const InputDecoration(hintText: '000000'),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blueprint,
                  ),
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: auth.loading ? null : _handleLogin,
                  child: auth.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    child: Text('O CONTINÚA CON', style: AppTheme.badgeLabel),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 280;
                  final width = stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - Spacing.sm) / 2;
                  return Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      SizedBox(
                        width: width,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSocialLogin('Google'),
                          icon: Image.asset(
                            'assets/images/google_logo.png',
                            height: 18,
                          ),
                          label: const Text('Google'),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleSocialLogin('Apple'),
                          icon: const Icon(Icons.apple),
                          label: const Text('Apple'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: Spacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Regístrate gratis'),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: Spacing.lg,
                runSpacing: Spacing.xs,
                children: const [
                  _TrustLabel(
                    icon: Icons.shield_outlined,
                    label: 'Conexión segura',
                  ),
                  _TrustLabel(
                    icon: Icons.verified_user_outlined,
                    label: 'Datos protegidos',
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

class _TrustLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.verified, size: 16),
        const SizedBox(width: Spacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
