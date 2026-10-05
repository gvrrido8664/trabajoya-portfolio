import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/login_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/register_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/email_verification_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/email_verified_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/google_callback_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/profile_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/totp_setup_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/pages/verificacion_identidad_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_verificaciones_screen.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/public/presentation/pages/landing_screen.dart';
import 'package:trabajoya_app/features/public/presentation/pages/terminos_screen.dart';
import 'package:trabajoya_app/features/public/presentation/pages/privacidad_screen.dart';
import 'package:trabajoya_app/features/public/presentation/pages/contacto_screen.dart';
import 'package:trabajoya_app/shared/layout/app_shell.dart';
import 'package:trabajoya_app/features/servicios/presentation/pages/servicio_detail_screen.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/pages/mis_contrataciones_screen.dart';
import 'package:trabajoya_app/features/servicios/presentation/pages/mis_servicios_screen.dart';
import 'package:trabajoya_app/features/servicios/presentation/pages/crear_editar_servicio_screen.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/pages/solicitar_servicio_screen.dart';
import 'package:trabajoya_app/features/contrataciones/presentation/pages/contratacion_detail_screen.dart';
import 'package:trabajoya_app/features/resenas/presentation/pages/resena_screen.dart';
import 'package:trabajoya_app/features/chat/presentation/pages/conversaciones_screen.dart';
import 'package:trabajoya_app/features/chat/presentation/pages/chat_screen.dart';
import 'package:trabajoya_app/features/pagos/presentation/pages/pago_screen.dart';
import 'package:trabajoya_app/features/suscripciones/presentation/pages/planes_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_full_dashboard_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_usuarios_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_servicios_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_pagos_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_categorias_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_soporte_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_feedback_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_suscripciones_screen.dart';
import 'package:trabajoya_app/features/admin/presentation/pages/admin_shell.dart';
import 'package:trabajoya_app/features/cliente/presentation/pages/cliente_shell.dart';
import 'package:trabajoya_app/features/cliente/presentation/pages/cliente_landing_screen.dart';
import 'package:trabajoya_app/features/cliente/presentation/pages/crear_solicitud_screen.dart';
import 'package:trabajoya_app/features/cliente/presentation/pages/mis_solicitudes_screen.dart';
import 'package:trabajoya_app/features/cliente/presentation/pages/categorias_list_screen.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/proveedor_shell.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/proveedor_profile_screen.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/perfil_publico_proveedor_screen.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/oportunidades_screen.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/proveedor_dashboard_screen.dart';
import 'package:trabajoya_app/features/proveedor/presentation/pages/proveedor_cobros_screen.dart';
import 'package:trabajoya_app/features/propuestas/presentation/pages/mis_propuestas_screen.dart';
import 'package:trabajoya_app/features/propuestas/presentation/pages/enviar_propuesta_screen.dart';
import 'package:trabajoya_app/features/solicitudes/presentation/pages/solicitud_detail_screen.dart';

/// Rutas del shell de proveedor que requieren la capacidad `esProveedor`
/// (distinto de `/proveedor/:id`, que es el perfil público de un proveedor).
const _proveedorShellPaths = {
  '/proveedor',
  '/proveedor/dashboard',
  '/proveedor/oportunidades',
  '/proveedor/cobros',
  '/proveedor/mis-propuestas',
  '/proveedor/servicios',
  '/proveedor/contrataciones',
  '/proveedor/chat',
  '/proveedor/perfil',
};

GoRouter createRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  required AuthProvider authProvider,
}) {
  final router = GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();

      // Mientras checkAuth() no resuelve, auth.isLoggedIn da false aunque
      // haya sesión válida guardada. Sin este guard, un deep link a una ruta
      // privada (ej. /proveedor/cobros) rebota a /login por esa falsa lectura,
      // y cuando checkAuth() resuelve y notifica, el router reevalúa el
      // redirect ya parado en /login (no en la ruta original) y termina
      // mandando siempre al dashboard por defecto — el deep link se pierde.
      if (!auth.initialized) return null;

      final isPublicRoute = [
        '/',
        '/login',
        '/register',
        '/forgot-password',
        '/verify-email',
        '/verificado',
        '/auth/google/callback',
        '/terminos',
        '/privacidad',
        '/contacto',
        '/buscar',
        '/categorias',
      ].contains(state.uri.path);
      final isServiciosRoute = state.uri.path.startsWith('/servicio/');

      final isLoggedIn = auth.isLoggedIn;

      // Si está logueado y visita la landing page o auth pages, redirigir por
      // modo activo (admin es aparte: no participa del modo cliente/proveedor).
      if (isLoggedIn && (state.uri.path == '/' || state.uri.path == '/login' || state.uri.path == '/register')) {
        if (auth.isAdmin) return '/admin';
        return auth.isProveedorMode ? '/proveedor' : '/cliente';
      }

      // Redirect antiguo /proveedor/crear-servicio → /crear-servicio
      if (state.uri.path == '/proveedor/crear-servicio') {
        return '/crear-servicio';
      }

      // Si no está logueado y quiere ruta privada → login, recordando el
      // destino para volver ahí después de autenticarse (sin esto, tras
      // loguearse desde un deep link a una ruta protegida siempre
      // aterrizaba en el dashboard por defecto, perdiendo el destino real).
      if (!isLoggedIn && !isPublicRoute && !isServiciosRoute) {
        return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
      }

      // Guard de seguridad para creacion de servicios
      if (state.uri.path == '/crear-servicio' && auth.usuario?.docEstado != 'approved') {
        return '/seguridad/identidad';
      }

      // Guard de seguridad para perfiles
      if (state.uri.path.startsWith('/perfil') && isLoggedIn && !auth.isAdmin) {
        return auth.isProveedorMode ? '/proveedor' : '/cliente';
      }

      // Guard de seguridad para rutas de administración
      if (state.uri.path.startsWith('/admin') && isLoggedIn && !auth.isAdmin) {
        return auth.isProveedorMode ? '/proveedor' : '/cliente';
      }

      // El MFA es obligatorio para admin (el backend ya lo exige, ver
      // get_current_admin en dependencies.py) -- sin este guard, un admin
      // logueado que nunca completó el 2FA podía entrar a /admin
      // directamente por URL (el único lugar que lo forzaba antes era la
      // navegación post-login de LoginScreen, evitable con un deep link).
      if (state.uri.path.startsWith('/admin') &&
          isLoggedIn &&
          auth.isAdmin &&
          auth.usuario?.totpEnabled != true) {
        return '/seguridad/2fa';
      }

      // Guard de capacidad: el shell de proveedor requiere esProveedor, sin
      // importar el modo activo guardado (evita que quien pierda la capacidad
      // quede atrapado ahí). No aplica a /proveedor/:id (perfil público).
      if (isLoggedIn &&
          !auth.isAdmin &&
          _proveedorShellPaths.contains(state.uri.path) &&
          !(auth.usuario?.esProveedor ?? false)) {
        return '/cliente/perfil';
      }

      // Sincroniza activeMode con la ruta real. switchMode() solo se
      // llamaba desde el botón explícito "Cambiar a modo Proveedor/Cliente"
      // -- navegar directo a una ruta del otro shell (deep link, URL, hash)
      // dejaba activeMode desfasado de la ruta/shell visible, y pantallas
      // que sí leen ese flag (Contrataciones, Chat) mostraban tema/copy del
      // modo equivocado pese al shell correcto en pantalla.
      if (isLoggedIn && !auth.isAdmin) {
        if (_proveedorShellPaths.contains(state.uri.path) &&
            !auth.isProveedorMode) {
          scheduleMicrotask(() => auth.switchMode('proveedor'));
        } else if (state.uri.path.startsWith('/cliente') &&
            auth.isProveedorMode) {
          scheduleMicrotask(() => auth.switchMode('cliente'));
        }
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Pagina no encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Ruta no encontrada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(
          initialRol: state.uri.queryParameters['rol'],
        ),
      ),
      GoRoute(path: '/buscar', builder: (_, _) => const ClienteLandingScreen()),
      GoRoute(
        path: '/categorias',
        builder: (_, _) => const CategoriasListScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => EmailVerificationScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verificado',
        builder: (_, state) => EmailVerifiedScreen(
          status: state.uri.queryParameters['status'],
        ),
      ),
      GoRoute(
        path: '/auth/google/callback',
        builder: (_, state) => GoogleCallbackScreen(
          exchangeCode: state.uri.queryParameters['xc'],
          intent: state.uri.queryParameters['intent'] ?? 'cliente',
        ),
      ),
      GoRoute(
        path: '/seguridad/2fa',
        builder: (_, _) => const TotpSetupScreen(),
      ),
      GoRoute(
        path: '/seguridad/identidad',
        builder: (_, _) => const VerificacionIdentidadScreen(),
      ),
      GoRoute(
        path: '/admin/verificaciones',
        builder: (_, _) => const AdminVerificacionesScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      // ---- Cliente Shell (BottomNav con tabs persistentes) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ClienteShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/buscar',
                builder: (_, _) => const ClienteLandingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/mis-solicitudes',
                builder: (_, _) => const MisSolicitudesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/trabajos',
                builder: (_, _) => const MisContratacionesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/chat',
                builder: (_, _) => const ConversacionesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cliente/perfil',
                builder: (_, _) => const ProfileAmplioScreen(),
              ),
            ],
          ),
        ],
      ),

      // Redirect /cliente → first branch
      GoRoute(path: '/cliente', redirect: (_, _) => '/cliente/buscar'),

      // ---- Proveedor Shell ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ProveedorShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/dashboard',
                builder: (_, _) => const ProveedorDashboardScreen(),
              ),
              GoRoute(
                path: '/proveedor/oportunidades',
                builder: (_, _) => const OportunidadesScreen(),
              ),
              GoRoute(
                path: '/proveedor/cobros',
                builder: (_, _) => const ProveedorCobrosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/mis-propuestas',
                builder: (_, _) => const MisPropuestasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/servicios',
                builder: (_, _) => const MisServiciosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/contrataciones',
                builder: (_, _) => const ContratacionesProveedorScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/chat',
                builder: (_, _) => const ConversacionesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proveedor/perfil',
                builder: (_, _) => const PerfilProveedorScreen(),
              ),
            ],
          ),
        ],
      ),

      // Redirect /proveedor → first branch (dashboard)
      GoRoute(
        path: '/proveedor',
        redirect: (_, _) => '/proveedor/dashboard',
      ),

      GoRoute(
        path: '/cliente/categorias',
        builder: (_, _) => const CategoriasListScreen(),
      ),

      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/perfil', builder: (_, _) => const ProfileAmplioScreen()),
      GoRoute(
        path: '/servicio/:id',
        builder: (_, state) =>
            ServicioDetailScreen(servicioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/proveedor/:id',
        builder: (_, state) => PerfilPublicoProveedorScreen(
          proveedorId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/solicitar/:servicioId',
        builder: (_, state) => SolicitarServicioScreen(
          servicioId: state.pathParameters['servicioId']!,
        ),
      ),
      GoRoute(
        path: '/mis-servicios',
        builder: (_, _) => const MisServiciosScreen(),
      ),
      GoRoute(
        path: '/crear-servicio',
        builder: (_, _) =>
            const NuevaSolicitudFormScreen(), // Usa la pantalla de servicios
      ),
      GoRoute(
        path: '/editar-servicio/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'];
          return NuevaSolicitudFormScreen(
            servicioId: id,
          ); // Esta sí acepta servicioId
        },
      ),
      GoRoute(
        path: '/contratacion/:id',
        builder: (_, state) => ContratacionDetailScreen(
          contratacionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/resena/:contratacionId',
        redirect: (context, state) {
          final auth = context.read<AuthProvider>();
          // Reseñas mutuas: cliente o proveedor pueden reseñar. El backend
          // valida que haya participado en la contratación.
          if (!auth.isLoggedIn) return '/login';
          return null;
        },
        builder: (_, state) => ResenaScreen(
          contratacionId: state.pathParameters['contratacionId']!,
        ),
      ),
      GoRoute(path: '/chat', builder: (_, _) => const ConversacionesScreen()),
      GoRoute(
        path: '/chat/:contratacionId',
        builder: (_, state) =>
            ChatScreen(contratacionId: state.pathParameters['contratacionId']!),
      ),
      GoRoute(
        path: '/pago/:contratacionId',
        builder: (_, state) =>
            PagoScreen(contratacionId: state.pathParameters['contratacionId']!),
      ),
      GoRoute(
        path: '/pago/resultado/:contratacionId',
        builder: (_, state) {
          final qp = state.uri.queryParameters;
          return PagoScreen(
            contratacionId: state.pathParameters['contratacionId']!,
            metodo: qp['metodo'],
            tokenWs: qp['token_ws'],
            status: qp['status'], // "success" | "failure" | "pending" (MP)
          );
        },
      ),
      GoRoute(
        path: '/crear-solicitud',
        builder: (_, _) => const CrearSolicitudScreen(),
      ),
      GoRoute(
        path: '/mis-solicitudes',
        builder: (_, _) => const MisSolicitudesScreen(),
      ),
      GoRoute(
        path: '/solicitud/:id',
        builder: (_, state) =>
            SolicitudDetailScreen(solicitudId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/solicitud/:id/proponer',
        builder: (_, state) =>
            EnviarPropuestaScreen(solicitudId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/mis-propuestas',
        builder: (_, _) => const MisPropuestasScreen(),
      ),
      GoRoute(path: '/planes', builder: (_, _) => const PlanesScreen()),
      GoRoute(path: '/terminos', builder: (_, _) => const TerminosScreen()),
      GoRoute(path: '/privacidad', builder: (_, _) => const PrivacidadScreen()),
      GoRoute(path: '/contacto', builder: (_, _) => const ContactoScreen()),

      // ---- Admin Shell con Sidebar ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, _) => const AdminFullDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/usuarios',
                builder: (_, _) => const AdminUsuariosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/servicios',
                builder: (_, _) => const AdminServiciosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/categorias',
                builder: (_, _) => const AdminCategoriasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/pagos',
                builder: (_, _) => const AdminPagosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/soporte',
                builder: (_, _) => const AdminSoporteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/feedback',
                builder: (_, _) => const AdminFeedbackScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/suscripciones',
                builder: (_, _) => const AdminSuscripcionesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    try {
      final path = router.routerDelegate.currentConfiguration.uri.path;
      String title = 'TrabajoYa | Encuentra a los mejores expertos';
      if (path == '/login') title = 'TrabajoYa | Iniciar sesión';
      if (path == '/register') title = 'TrabajoYa | Registro';
      if (path.startsWith('/cliente')) title = 'TrabajoYa | Cliente';
      if (path.startsWith('/proveedor')) title = 'TrabajoYa | Proveedor';
      if (path.startsWith('/admin')) title = 'TrabajoYa | Administración';
      if (path.startsWith('/servicio/')) title = 'TrabajoYa | Detalles del Servicio';
      if (path.startsWith('/mensajes')) title = 'TrabajoYa | Mis Mensajes';
      
      SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
          label: title,
          primaryColor: 0xFF0EA5E9,
        ),
      );
    } catch (_) {}
  });

  return router;
}
