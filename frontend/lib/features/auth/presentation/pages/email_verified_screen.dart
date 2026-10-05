import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/utils/colors.dart';

class EmailVerifiedScreen extends StatelessWidget {
  final String? status;

  const EmailVerifiedScreen({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';
    final textTheme = Theme.of(context).textTheme;
    final color = isSuccess ? AppColors.verified : AppColors.danger;

    return AuthScaffold(
      onHome: () => context.go('/'),
      child: AuthPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Eyebrow(
                label: isSuccess ? 'Correo confirmado' : 'Enlace inválido',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            AuthIconBadge(
              icon: isSuccess
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: color,
              background: color.withValues(alpha: 0.1),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              isSuccess ? '¡Correo verificado!' : 'El enlace no es válido',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              isSuccess
                  ? 'Tu correo fue verificado correctamente. Ya puedes acceder a TrabajoYa.'
                  : 'El enlace de verificación expiró o ya fue utilizado. Solicita uno nuevo desde tu cuenta.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
