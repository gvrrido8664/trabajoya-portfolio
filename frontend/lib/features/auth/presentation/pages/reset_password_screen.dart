import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _success = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(widget.token, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al restablecer contraseña'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onHome: () => context.go('/'),
      onBack: () => context.go('/login'),
      child: AuthPanel(child: _success ? _buildSuccess() : _buildForm()),
    );
  }

  Widget _buildForm() {
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Eyebrow(label: 'Nueva contraseña'),
          ),
          const SizedBox(height: Spacing.lg),
          const AuthIconBadge(icon: Icons.lock_reset),
          const SizedBox(height: Spacing.lg),
          Text(
            'Crea una contraseña nueva',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Debe tener al menos 6 caracteres y coincidir en ambos campos.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
          ),
          const SizedBox(height: Spacing.xl),
          AuthField(
            label: 'Nueva contraseña',
            child: TextFormField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Mínimo 6 caracteres',
                suffixIcon: IconButton(
                  tooltip: _obscure
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscure = !_obscure);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _passwordFocus.requestFocus(),
                    );
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una contraseña';
                }
                if (value.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AuthField(
            label: 'Confirmar contraseña',
            child: TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Repite tu contraseña',
              ),
              validator: (value) => value != _passwordCtrl.text
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: auth.loading ? null : _submit,
              child: auth.loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Restablecer contraseña'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Eyebrow(label: 'Acceso recuperado'),
        ),
        const SizedBox(height: Spacing.lg),
        const AuthIconBadge(
          icon: Icons.check_circle_outline,
          color: AppColors.verified,
          background: AppColors.verifiedTint,
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Contraseña restablecida',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Tu contraseña se actualizó correctamente.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
        ),
        const SizedBox(height: Spacing.xl),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir a iniciar sesión'),
          ),
        ),
      ],
    );
  }
}
