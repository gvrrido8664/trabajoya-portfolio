import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
class SidebarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badge;

  SidebarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badge = 0,
  });
}

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final List<SidebarItem> items;
  final ValueChanged<int> onTap;
  final String? logoSubtitle;
  final Widget? footer;
  final Color activeColor;
  final Color activeBgColor;
  final Color inactiveColor;
  final Color? inactiveTextColor;
  final BoxDecoration decoration;
  final double borderRadius;
  final bool showDotIndicator;
  final Border? activeBorder;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.logoSubtitle,
    this.footer,
    required this.activeColor,
    required this.activeBgColor,
    required this.inactiveColor,
    this.inactiveTextColor,
    required this.decoration,
    this.borderRadius = Radii.md,
    this.showDotIndicator = false,
    this.activeBorder,
  });

  factory AppSidebar.cliente({
    required int currentIndex,
    required int unread,
    required ValueChanged<int> onTap,
    bool canSwitchToProveedor = false,
    VoidCallback? onSwitchMode,
  }) {
    return AppSidebar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: AppColors.ink,
      activeBgColor: Colors.white,
      inactiveColor: Colors.white.withValues(alpha: 0.78),
      borderRadius: Radii.md,
      showDotIndicator: false,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarTop, AppColors.sidebarBottom],
        ),
      ),
      items: [
        SidebarItem(icon: Icons.search, label: 'Buscar'),
        SidebarItem(
          icon: Icons.assignment_outlined,
          label: 'Mis solicitudes',
        ),
        SidebarItem(
          icon: Icons.handshake_outlined,
          label: 'Contrataciones',
        ),
        SidebarItem(icon: Icons.forum_outlined, label: 'Chat', badge: unread),
        SidebarItem(icon: Icons.person_outline, label: 'Perfil'),
      ],
      footer: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final user = auth.usuario;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (canSwitchToProveedor && onSwitchMode != null) {
                      onSwitchMode();
                    } else {
                      GoRouter.of(context).push('/seguridad/identidad');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '¿Ofreces servicios también?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 12),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          canSwitchToProveedor
                              ? 'Cambia al modo proveedor haciendo clic aquí.'
                              : 'Verifica tu identidad para trabajar como proveedor.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                        if (canSwitchToProveedor) ...[
                          const SizedBox(height: Spacing.md),
                          _SwitchModeButton(
                            label: 'Cambiar a Proveedor',
                            onTap: onSwitchMode,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: Spacing.xl),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Text(
                              user.nombreCompleto.isNotEmpty ? user.nombreCompleto[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nombreCompleto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Cliente · Santiago, Chile',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }
      ),
    );
  }

  factory AppSidebar.proveedor({
    required int currentIndex,
    required int unread,
    required ValueChanged<int> onTap,
    VoidCallback? onSwitchMode,
  }) {
    return AppSidebar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: AppColors.ink,
      activeBgColor: Colors.white,
      inactiveColor: Colors.white.withValues(alpha: 0.78),
      borderRadius: Radii.md,
      showDotIndicator: false,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarTop, AppColors.sidebarBottom],
        ),
      ),
      items: [
        SidebarItem(icon: Icons.home_outlined, label: 'Inicio'),
        SidebarItem(
          icon: Icons.local_offer_outlined,
          label: 'Mis propuestas',
        ),
        SidebarItem(
          icon: Icons.business_center_outlined,
          label: 'Mis servicios',
        ),
        SidebarItem(
          icon: Icons.handshake_outlined,
          label: 'Contrataciones',
        ),
        SidebarItem(
          icon: Icons.chat_outlined,
          label: 'Mensajes',
          badge: unread,
        ),
        SidebarItem(icon: Icons.person_outline, label: 'Perfil'),
      ],
      footer: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proveedor activo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Revisa nuevas oportunidades comerciales, envía presupuestos y gestiona tus servicios.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: Spacing.md),
            _SwitchModeButton(
              label: 'Cambiar a modo Cliente',
              onTap: onSwitchMode,
            ),
          ],
        ),
      ),
    );
  }

  factory AppSidebar.admin({
    required int currentIndex,
    required ValueChanged<int> onTap,
    required VoidCallback onLogout,
  }) {
    return AppSidebar(
      currentIndex: currentIndex,
      onTap: onTap,
      logoSubtitle: 'ADMIN',
      activeColor: AppColors.ink,
      activeBgColor: Colors.white,
      inactiveColor: Colors.white.withValues(alpha: 0.68),
      inactiveTextColor: Colors.white.withValues(alpha: 0.68),
      borderRadius: Radii.md,
      showDotIndicator: false,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarTop, AppColors.sidebarBottom],
        ),
      ),
      items: [
        SidebarItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          label: 'Dashboard',
        ),
        SidebarItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people,
          label: 'Usuarios',
        ),
        SidebarItem(
          icon: Icons.work_outline,
          activeIcon: Icons.work,
          label: 'Servicios',
        ),
        SidebarItem(
          icon: Icons.category,
          activeIcon: Icons.category,
          label: 'Categorías',
        ),
        SidebarItem(
          icon: Icons.payment_outlined,
          activeIcon: Icons.payment,
          label: 'Pagos',
        ),
        SidebarItem(
          icon: Icons.help_outline,
          activeIcon: Icons.help,
          label: 'Soporte',
        ),
        SidebarItem(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          label: 'Feedback',
        ),
        SidebarItem(
          icon: Icons.star_outline,
          activeIcon: Icons.star,
          label: 'Suscripciones',
        ),
      ],
      footer: _AdminLogoutFooter(onLogout: onLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 248,
      height: double.infinity,
      decoration: decoration,
      padding: const EdgeInsets.all(Spacing.xl),
      // El footer (tarjeta "Proveedor/Cliente activo") vivía en un
      // Positioned(bottom:0) sobre el Stack, sin reservar su propio espacio
      // en el Column -- en viewports bajos (apaisado/landscape, RESP-13) el
      // Expanded de la lista de nav ocupaba TODA la altura disponible y el
      // footer terminaba flotando encima de los últimos ítems. Ahora el
      // footer es parte del flujo normal del Column (después del Expanded
      // scrolleable), así siempre reserva su propio alto.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/brand/trabajoya-logo-dark.png',
                width: 172,
                height: 48,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                filterQuality: FilterQuality.high,
                semanticLabel: 'TrabajoYa',
              ),
              if (logoSubtitle != null)
                const Padding(
                  padding: EdgeInsets.only(left: Spacing.xs),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xl2),
          // Navigation list wrapped in SingleChildScrollView if many items (e.g. admin)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (logoSubtitle != null) // If Admin, show GESTIÓN label
                    const Padding(
                      padding: EdgeInsets.only(
                        left: Spacing.sm,
                        bottom: Spacing.sm,
                      ),
                      child: Text(
                        'GESTIÓN',
                        style: TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isSelected = currentIndex == idx;
                    final currentIconColor = isSelected
                        ? activeColor
                        : inactiveColor;
                    final currentTextColor = isSelected
                        ? activeColor
                        : (inactiveTextColor ?? inactiveColor);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: item.label,
                        onTap: () => onTap(idx),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(borderRadius),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(borderRadius),
                            onTap: () => onTap(idx),
                            excludeFromSemantics: true,
                            child: AnimatedContainer(
                              duration: Motion.fast,
                              curve: Motion.curve,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.lg,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? activeBgColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                                border: isSelected ? activeBorder : null,
                              ),
                              child: Row(
                                children: [
                                  Badge(
                                    isLabelVisible: item.badge > 0,
                                    backgroundColor: AppColors.rust,
                                    textColor: Colors.white,
                                    label: Text(
                                      item.badge > 99 ? '99+' : '${item.badge}',
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? (item.activeIcon ?? item.icon)
                                          : item.icon,
                                      size: 20,
                                      color: currentIconColor,
                                    ),
                                  ),
                                  const SizedBox(width: Spacing.md),
                                  Text(
                                    item.label,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                          color: currentTextColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ) ??
                                        TextStyle(
                                          color: currentTextColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                  ),
                                  if (isSelected && showDotIndicator) ...[
                                    const Spacer(),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: activeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: Spacing.md),
            footer!,
          ] else
            const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
}

/// Botón compacto para alternar el modo activo (cliente/proveedor) desde el
/// footer del sidebar, estilo Uber rider/driver.
class _SwitchModeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SwitchModeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: const BorderSide(color: Colors.white24, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogoutFooter extends StatelessWidget {
  final VoidCallback onLogout;
  const _AdminLogoutFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: Spacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.sidebarBottom)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: onLogout,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: AppColors.textLight),
                const SizedBox(width: Spacing.md),
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
