import 'package:trabajoya_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';

// --- PALETA DE COLORES SCI-FI ---
final Color sciFiBg = AppColors.ink;
final Color sciFiCyan = AppColors.blueprint;
final Color sciFiMagenta = AppColors.danger;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ─── LÓGICA ORIGINAL INTACTA ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.checkAuth();
    if (!mounted) return;
    if (loggedIn) {
      final rol = auth.usuario?.rol;
      if (rol == 'admin') {
        context.go('/admin');
      } else if (rol == 'proveedor') {
        context.go('/proveedor');
      } else {
        context.go('/cliente');
      }
    } else {
      context.go('/');
    }
  }
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sciFiBg,
      body: Stack(
        children: [
          // Iluminación ambiental holográfica
          Positioned(
            top: -150,
            right: -100,
            child: _GlowOrb(
              color: sciFiCyan.withValues(alpha: 0.15),
              size: 400,
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _GlowOrb(
              color: sciFiMagenta.withValues(alpha: 0.1),
              size: 400,
            ),
          ),

          // Contenido Central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Animado / Iluminado
                Text(
                  'TY',
                  style: GoogleFonts.inter(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -4,
                    shadows: [
                      Shadow(
                        color: sciFiCyan.withValues(alpha: 0.6),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nombre de la marca
                Text(
                  'TRABAJOYA',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 48),

                // Indicador de carga de neón
                SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: sciFiCyan,
                  ),
                ),

                const SizedBox(height: 24),

                // Texto de estado
                Text(
                  'VERIFICANDO CREDENCIALES...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white38,
                    letterSpacing: 1.5,
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

// ─── COMPONENTE ESTRUCTURAL: ORBES DE LUZ ─────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)],
      ),
    );
  }
}
