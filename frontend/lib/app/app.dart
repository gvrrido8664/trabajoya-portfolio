import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/router.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:trabajoya_app/features/pagos/presentation/providers/pagos_provider.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/features/suscripciones/presentation/providers/suscripciones_provider.dart';
import 'package:trabajoya_app/features/proveedor/presentation/providers/oportunidades_provider.dart';
import 'package:trabajoya_app/features/solicitudes/presentation/providers/solicitudes_provider.dart';
import 'package:trabajoya_app/features/propuestas/presentation/providers/propuestas_provider.dart';
import 'package:trabajoya_app/features/usuarios/presentation/providers/certificaciones_provider.dart';

class TrabajoYaApp extends StatefulWidget {
  final AuthProvider authProvider;

  const TrabajoYaApp({super.key, required this.authProvider});

  @override
  State<TrabajoYaApp> createState() => _TrabajoYaAppState();
}

class _TrabajoYaAppState extends State<TrabajoYaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ApiClient.onUnauthorized = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ctx.read<AuthProvider>().logout();
          ctx.go('/login');
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => ServiciosProvider()),
        ChangeNotifierProvider(create: (_) => ContratacionesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PagosProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => SuscripcionesProvider()),
        ChangeNotifierProvider(create: (_) => OportunidadesProvider()),
        ChangeNotifierProvider(create: (_) => SolicitudesProvider()),
        ChangeNotifierProvider(create: (_) => PropuestasProvider()),
        ChangeNotifierProvider(create: (_) => CertificacionesProvider()),
      ],
      child: MaterialApp.router(
        title: 'TrabajoYa',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: createRouter(
          navigatorKey: _navigatorKey,
          authProvider: widget.authProvider,
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
