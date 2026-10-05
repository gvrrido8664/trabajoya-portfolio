import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  final _codeCtrl = TextEditingController();
  String? _otpauthUri;
  String? _secret;
  List<String>? _backupCodes;
  bool _loading = true;
  bool _enabling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    try {
      final response = await context.read<AuthProvider>().setupTotp();
      if (!mounted) return;
      setState(() {
        _otpauthUri = response['otpauth_uri'] as String?;
        _secret = response['secret'] as String?;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo iniciar la configuración: $error';
        _loading = false;
      });
    }
  }

  Future<void> _enable() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _enabling = true);
    try {
      final codes = await context.read<AuthProvider>().enableTotp(code);
      if (!mounted) return;
      setState(() => _backupCodes = codes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código inválido, intenta nuevamente'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _enabling = false);
    }
  }

  void _continue() {
    final auth = context.read<AuthProvider>();
    context.go(
      auth.isAdmin
          ? '/admin'
          : auth.isProveedorMode
          ? '/proveedor'
          : '/cliente',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      maxWidth: 440,
      onHome: () => context.go('/'),
      child: AuthPanel(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(Spacing.xl2),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _setup)
            : _backupCodes != null
            ? _buildBackupCodes()
            : _buildSetup(),
      ),
    );
  }

  Widget _buildSetup() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Eyebrow(label: 'Seguridad de cuenta'),
        ),
        const SizedBox(height: Spacing.lg),
        const AuthIconBadge(icon: Icons.phonelink_lock_outlined),
        const SizedBox(height: Spacing.lg),
        Text(
          'Verificación en dos pasos',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Escanea el código con Google Authenticator, Authy o tu aplicación de autenticación.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        if (_otpauthUri != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: QrImageView(data: _otpauthUri!, size: 200),
            ),
          ),
        if (_secret != null) ...[
          const SizedBox(height: Spacing.sm),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(
              'Ingresar manualmente: $_secret',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _secret!));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Clave copiada')));
            },
          ),
        ],
        const SizedBox(height: Spacing.lg),
        AuthField(
          label: 'Código de 6 dígitos',
          child: TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _enable(),
            decoration: const InputDecoration(hintText: '000000'),
          ),
        ),
        const SizedBox(height: Spacing.xl),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _enabling ? null : _enable,
            child: _enabling
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Activar 2FA'),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupCodes() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Eyebrow(label: '2FA activado'),
        ),
        const SizedBox(height: Spacing.lg),
        const AuthIconBadge(
          icon: Icons.check_circle_outline,
          color: AppColors.verified,
          background: AppColors.verifiedTint,
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Guarda tus códigos de respaldo',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Permiten entrar si pierdes tu dispositivo y solo se muestran una vez.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Wrap(
            runSpacing: Spacing.sm,
            children: _backupCodes!
                .map(
                  (code) => SizedBox(
                    width: double.infinity,
                    child: Text(code, style: AppTheme.dataSmall),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: Spacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copiar códigos'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _backupCodes!.join('\n')));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Códigos copiados')));
          },
        ),
        const SizedBox(height: Spacing.lg),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _continue,
            child: const Text('Listo, continuar'),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthIconBadge(
          icon: Icons.error_outline,
          color: AppColors.danger,
          background: AppColors.dangerLight,
        ),
        const SizedBox(height: Spacing.lg),
        Text(message, style: const TextStyle(color: AppColors.danger)),
        const SizedBox(height: Spacing.lg),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
