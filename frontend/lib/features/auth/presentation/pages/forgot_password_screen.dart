import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al enviar el correo'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      onHome: () => context.go('/'),
      onBack: () => context.go('/login'),
      child: AuthPanel(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Eyebrow(label: 'Recuperar acceso'),
              ),
              const SizedBox(height: Spacing.lg),
              const AuthIconBadge(icon: Icons.shield_outlined),
              const SizedBox(height: Spacing.lg),
              Text(
                '¿Olvidaste tu contraseña?',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Ingresa tu correo y te enviaremos un enlace para crear una nueva.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.55,
                ),
              ),
              if (_sent) ...[
                const SizedBox(height: Spacing.lg),
                const AuthNotice(
                  message:
                      'Si el correo existe en nuestro sistema, recibirás un enlace en los próximos minutos.',
                ),
              ],
              const SizedBox(height: Spacing.xl),
              AuthField(
                label: 'Correo electrónico',
                child: TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleResetRequest(),
                  decoration: const InputDecoration(
                    hintText: 'tucorreo@ejemplo.com',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'El correo es obligatorio'
                      : null,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _handleResetRequest,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar enlace de recuperación'),
                ),
              ),
              const SizedBox(height: Spacing.md),
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
