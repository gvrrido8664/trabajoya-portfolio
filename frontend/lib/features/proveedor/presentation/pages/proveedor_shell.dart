import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/shared/layout/app_sidebar.dart';

class ProveedorShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ProveedorShell({super.key, required this.navigationShell});

  static const int _chatIndex = 4;

  void _onTap(BuildContext context, int index) {
    if (index == _chatIndex) {
      context.read<AuthProvider>().clearUnreadMessages();
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _switchToCliente(BuildContext context) async {
    await context.read<AuthProvider>().switchMode('cliente');
    if (context.mounted) context.go('/cliente');
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = !Breakpoints.isMobile(context);
    final unread = context.select<AuthProvider, int>((a) => a.unreadMessages);

    Widget chatIcon(bool active) => Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(active ? Icons.chat : Icons.chat_outlined),
    );

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar.proveedor(
              currentIndex: navigationShell.currentIndex,
              unread: unread,
              onTap: (i) => _onTap(context, i),
              onSwitchMode: () => _switchToCliente(context),
            ),
            Expanded(child: ClipRect(child: navigationShell)),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: ProColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              label: 'Propuestas',
            ),
            const NavigationDestination(
              icon: Icon(Icons.business_center_outlined),
              label: 'Servicios',
            ),
            const NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              label: 'Contratos',
            ),
            NavigationDestination(
              icon: chatIcon(navigationShell.currentIndex == _chatIndex),
              label: 'Chat',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
