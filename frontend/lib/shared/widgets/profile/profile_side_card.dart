import 'mini_kpi_item.dart';
import '../avatar_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ProfileSideCard extends StatelessWidget {
  final String name;
  final double rating;
  final String rol;
  final String docEstado;
  final int referidosCount;
  final int solicitudesCount;

  const ProfileSideCard({super.key, 
    required this.name,
    required this.rating,
    required this.rol,
    required this.docEstado,
    required this.referidosCount,
    required this.solicitudesCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: [
            Container(
              height: 88,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ink, AppColors.sidebarBottom],
                ),
              ),
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(Spacing.md),
              child: const Text(
                'PERFIL VERIFICADO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -44),
              child: Column(
                children: [
                  AvatarEditor(
                    avatarUrl: context.watch<AuthProvider>().usuario?.avatarUrl,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (docEstado == 'approved') ...[
                        const SizedBox(width: 8),
                        Icon(Icons.verified, color: colorScheme.primary, size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$rol · Santiago, Chile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.rustTint,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: AppColors.rust.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CALIFICACIÓN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.rustDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rating.toStringAsFixed(1)} ★',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.rustDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Basada en contrataciones finalizadas',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.rustDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MiniKpiItem(
                          value: '$referidosCount',
                          label: 'Referidos',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniKpiItem(
                          value: '$solicitudesCount',
                          label: 'Solicitudes',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}