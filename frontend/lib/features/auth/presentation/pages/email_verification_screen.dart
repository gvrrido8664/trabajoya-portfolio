import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String token;

  const EmailVerificationScreen({super.key, required this.token});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _loading = true;
  bool _success = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    if (widget.token.isNotEmpty) {
      _verify();
    } else {
      _loading = false;
    }
  }

  Future<void> _verify() async {
    try {
      final ok = await context.read<AuthProvider>().verifyEmail(widget.token);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = ok;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerification();
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Correo de verificación reenviado'
              : auth.error ?? 'Error al reenviar',
        ),
        backgroundColor: ok ? AppColors.verified : AppColors.danger,
      ),
    );
  }

  void _continue() {
    final auth = context.read<AuthProvider>();
    context.go(
      auth.isLoggedIn
          ? auth.isAdmin
                ? '/admin'
                : auth.isProveedorMode
                ? '/proveedor'
                : '/cliente'
          : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AuthScaffold(
      onHome: () => context.go('/'),
      onBack: () => context.go('/login'),
      child: AuthPanel(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(Spacing.xl2),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Eyebrow(label: 'Verificar correo'),
                  ),
                  const SizedBox(height: Spacing.lg),
                  AuthIconBadge(
                    icon: _success
                        ? Icons.check_circle_outline
                        : Icons.mark_email_unread_outlined,
                    color: _success ? AppColors.verified : AppColors.blueprint,
                    background: _success
                        ? AppColors.verifiedTint
                        : AppColors.blueprintTint,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    _success ? 'Correo verificado' : 'Revisa tu correo',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    _success
                        ? 'Tu cuenta fue verificada correctamente.'
                        : 'Te enviamos un enlace de verificación. Revisa tu bandeja de entrada y la carpeta de spam.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _success || !_resending
                          ? (_success ? _continue : _resend)
                          : null,
                      child: _resending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_success ? 'Continuar' : 'Reenviar correo'),
                    ),
                  ),
                  if (!_success) ...[
                    const SizedBox(height: Spacing.sm),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Ya verifiqué, ir al login'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
