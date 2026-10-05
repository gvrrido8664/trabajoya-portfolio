import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback onHome;
  final VoidCallback? onBack;
  final double maxWidth;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.onHome,
    this.onBack,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    IconButton(
                      onPressed: onBack,
                      tooltip: 'Volver',
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: Spacing.sm),
                  ],
                  InkWell(
                    onTap: onHome,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      child: Image.asset(
                        'assets/images/brand/trabajoya-logo-horizontal.png',
                        width: 168,
                        height: 45,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl,
                  vertical: Spacing.xl2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPanel extends StatelessWidget {
  final Widget child;

  const AuthPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      padding: const EdgeInsets.all(Spacing.xl2),
      color: AppColors.card,
      child: child,
    );
  }
}

class AuthField extends StatelessWidget {
  final String label;
  final Widget child;

  const AuthField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.eyebrow.copyWith(
            color: AppColors.inkSoft,
            letterSpacing: 0.36,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        child,
      ],
    );
  }
}

class AuthIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const AuthIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.blueprint,
    this.background = AppColors.blueprintTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class AuthNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color background;

  const AuthNotice({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_outline,
    this.color = AppColors.verified,
    this.background = AppColors.verifiedTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
