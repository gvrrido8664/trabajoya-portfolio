import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

/// Destino del redirect de Google tras /auth/google/callback (backend).
/// Canjea el código de intercambio de 60s por la sesión real y navega.
class GoogleCallbackScreen extends StatefulWidget {
  final String? exchangeCode;
  final String intent;

  const GoogleCallbackScreen({
    super.key,
    required this.exchangeCode,
    required this.intent,
  });

  @override
  State<GoogleCallbackScreen> createState() => _GoogleCallbackScreenState();
}

class _GoogleCallbackScreenState extends State<GoogleCallbackScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  Future<void> _complete() async {
    final code = widget.exchangeCode;
    if (code == null || code.isEmpty) {
      setState(() => _error = true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.completeGoogleRedirect(code);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = true);
      return;
    }
    final destino = auth.usuario?.esProveedor == true
        ? '/proveedor'
        : (widget.intent == 'proveedor' ? '/seguridad/identidad' : '/cliente');
    context.go(destino);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _error
                ? [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se pudo completar el inicio de sesión con Google.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Volver a iniciar sesión'),
                    ),
                  ]
                : const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Completando inicio de sesión con Google...'),
                  ],
          ),
        ),
      ),
    );
  }
}
