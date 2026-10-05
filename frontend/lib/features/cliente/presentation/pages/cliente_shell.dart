import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/layout/breakpoints.dart';
import 'package:trabajoya_app/shared/layout/app_sidebar.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ClienteShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ClienteShell({super.key, required this.navigationShell});

  // Chat tab index
  static const int _chatIndex = 3;

  void _onTap(BuildContext context, int index) {
    if (index == _chatIndex) {
      context.read<AuthProvider>().clearUnreadMessages();
    }

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _switchToProveedor(BuildContext context) async {
    await context.read<AuthProvider>().switchMode('proveedor');
    if (context.mounted) context.go('/proveedor');
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = !Breakpoints.isMobile(context);
    final auth = context.watch<AuthProvider>();
    final unread = context.select<AuthProvider, int>((a) => a.unreadMessages);

    Widget chatIcon(bool active) => Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(active ? Icons.forum : Icons.forum_outlined),
    );

    final content = Column(
      children: [
        _ClienteTopBar(
          title: switch (navigationShell.currentIndex) {
            0 => 'Buscar servicios',
            1 => 'Mis solicitudes',
            2 => 'Mis contrataciones',
            3 => 'Chat',
            _ => 'Mi perfil',
          },
          unread: unread,
          avatarUrl: auth.usuario?.avatarUrl,
          initials: _initials(auth.usuario?.nombreCompleto ?? 'Usuario'),
          onMessages: () => _onTap(context, _chatIndex),
          onProfile: () => _onTap(context, 4),
        ),
        Expanded(child: ClipRect(child: navigationShell)),
      ],
    );

    if (isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar.cliente(
              currentIndex: navigationShell.currentIndex,
              unread: unread,
              onTap: (i) => _onTap(context, i),
              canSwitchToProveedor: auth.usuario?.esProveedor ?? false,
              onSwitchMode: () => _switchToProveedor(context),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Buscar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Solicitudes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              // Versión corta de "Contrataciones" solo para caber en la barra
              // inferior a 320-360px sin partir la palabra a la mitad; el
              // sidebar de escritorio sigue diciendo "Contrataciones" completo.
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

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class _ClienteTopBar extends StatelessWidget {
  final String title;
  final int unread;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  const _ClienteTopBar({
    required this.title,
    required this.unread,
    required this.avatarUrl,
    required this.initials,
    required this.onMessages,
    required this.onProfile,
  });

  void _showNotificationPopup(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final buttonPos = button.localToGlobal(Offset.zero, ancestor: overlay);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: buttonPos.dy + button.size.height + 4,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.card,
              child: Container(
                width: 320,
                constraints: const BoxConstraints(maxHeight: 360),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Text(
                            'Notificaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.rust.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unread nuevo${unread > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.rust,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (unread > 0) ...[
                      _NotificationTile(
                        icon: Icons.chat_bubble_outline,
                        title: 'Nuevos mensajes',
                        subtitle: 'Tienes $unread mensaje${unread > 1 ? 's' : ''} sin leer en el chat.',
                        onTap: () {
                          Navigator.pop(ctx);
                          onMessages();
                        },
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.inkSoft),
                              SizedBox(height: 8),
                              Text(
                                'No tienes notificaciones pendientes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        onMessages();
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Ir al Chat',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rust,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl?.trim();
    final hasAvatar = avatar != null && avatar.isNotEmpty;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 600
        ? Spacing.lg
        : Spacing.xl;

    return Material(
      color: AppColors.card,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 68,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Builder(
                builder: (btnContext) => Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.rust,
                  child: IconButton(
                    onPressed: () => _showNotificationPopup(btnContext),
                    tooltip: 'Notificaciones',
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Semantics(
                button: true,
                label: 'Abrir mi perfil',
                child: InkWell(
                  onTap: onProfile,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: CircleAvatar(
                        radius: 18,
                        foregroundImage: hasAvatar ? NetworkImage(avatar) : null,
                        backgroundColor: AppColors.blueprintTint,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.blueprint,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
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

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.rust.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.rust),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
