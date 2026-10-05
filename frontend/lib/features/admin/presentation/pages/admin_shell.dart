import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/shared/layout/app_sidebar.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminShell({super.key, required this.navigationShell});

  static const _labels = [
    'Dashboard',
    'Usuarios',
    'Servicios',
    'Categorías',
    'Pagos',
    'Soporte',
    'Feedback',
    'Suscripciones',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = !Breakpoints.isMobile(context);

    if (isDesktop) {
      return _DesktopLayout(navigationShell: navigationShell);
    } else {
      return _MobileLayout(navigationShell: navigationShell);
    }
  }
}

class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _DesktopLayout({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar.admin(
            currentIndex: navigationShell.currentIndex,
            onTap: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            onLogout: () => _showLogoutDialog(context),
          ),
          Expanded(
            child: Column(
              children: [
                _AdminTopBar(
                  title: AdminShell._labels[navigationShell.currentIndex],
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: navigationShell,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileLayout({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.sidebarTop,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          AdminShell._labels[navigationShell.currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      drawer: Drawer(
        width: 248,
        child: AppSidebar.admin(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) {
            Navigator.pop(context);
            navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            );
          },
          onLogout: () {
            Navigator.pop(context);
            _showLogoutDialog(context);
          },
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: navigationShell,
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  const _AdminTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Actualizar',
            onPressed: () {},
          ),
          const SizedBox(width: Spacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.blueprintTint,
              borderRadius: BorderRadius.circular(Radii.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blueprint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro de que quieres salir del panel?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final auth = context.read<AuthProvider>();
            final router = GoRouter.of(context);
            await auth.logout();
            router.go('/');
          },
          child: const Text(
            'Salir',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
