import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/chat/presentation/pages/conversaciones_screen.dart';
import 'package:trabajoya_app/features/servicios/presentation/pages/servicios_list_screen.dart';
import 'package:trabajoya_app/features/servicios/presentation/pages/mis_servicios_screen.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/pages/mis_contrataciones_screen.dart';
import 'package:trabajoya_app/features/suscripciones/presentation/pages/planes_screen.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/utils/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.usuario;

    if (user == null) {
      final router = GoRouter.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => router.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.isAdmin) {
      final router = GoRouter.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) => router.go('/admin'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = auth.isProveedorMode ? _proveedorTabs() : _clienteTabs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TrabajoYa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              final authProv = context.read<AuthProvider>();
              final router = GoRouter.of(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que quieres salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await authProv.logout();
                        router.go('/login');
                      },
                      child: const Text(
                        'Salir',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: IconButton(
                tooltip: 'Mi perfil',
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => context.push('/perfil'),
              ),
            ),
          ),
        ],
      ),
      body: tabs[_currentIndex]['screen'] as Widget,
      // Heurística #4: NavigationBar M3 para la navegación principal.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: tabs.map<NavigationDestination>((tab) {
            return NavigationDestination(
              icon: Icon(tab['icon'] as IconData),
              selectedIcon: Icon(tab['iconActive'] as IconData),
              label: tab['label'] as String,
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _clienteTabs() => [
    {
      'icon': Icons.search_outlined,
      'iconActive': Icons.search,
      'label': 'Buscar',
      'screen': const ServiciosListScreen(),
    },
    {
      'icon': Icons.work_outline,
      'iconActive': Icons.work,
      'label': 'Mis Trabajos',
      'screen': const MisContratacionesScreen(),
    },
    {
      'icon': Icons.chat_outlined,
      'iconActive': Icons.chat,
      'label': 'Chat',
      'screen': const ConversacionesScreen(),
    },
  ];

  List<Map<String, dynamic>> _proveedorTabs() => [
    {
      'icon': Icons.build_outlined,
      'iconActive': Icons.build,
      'label': 'Servicios',
      'screen': const MisServiciosScreen(),
    },
    {
      'icon': Icons.work_outline,
      'iconActive': Icons.work,
      'label': 'Solicitudes',
      'screen': const MisContratacionesScreen(),
    },
    {
      'icon': Icons.chat_outlined,
      'iconActive': Icons.chat,
      'label': 'Chat',
      'screen': const ConversacionesScreen(),
    },
    {
      'icon': Icons.workspace_premium_outlined,
      'iconActive': Icons.workspace_premium,
      'label': 'Planes',
      'screen': const PlanesScreen(),
    },
  ];
}
