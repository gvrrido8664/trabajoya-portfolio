import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';

class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _asuntoCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _asuntoCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _enviado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              tooltip: 'Volver',
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
            ),
            title: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.blueprintTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.engineering,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Text(
                  'TrabajoYa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Hero
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.xl3,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOPORTE',
                        style: TextStyle(
                          color: AppColors.blueprintTint,
                          
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'Contáctanos',
                        style: TextStyle(
                          color: Colors.white,
                          
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Estamos aquí para ayudarte. Responderemos en menos de 24 horas hábiles.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Cuerpo
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.xl3,
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildForm(theme)),
                            const SizedBox(width: Spacing.xl2),
                            Expanded(flex: 3, child: _buildInfoPanel()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildInfoPanel(),
                            const SizedBox(height: Spacing.xl2),
                            _buildForm(theme),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
              ),
              padding: const EdgeInsets.all(Spacing.xl),
              child: Center(
                child: Text(
                  '© 2026 TrabajoYa. Todos los derechos reservados.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    if (_enviado) {
      return Container(
        padding: const EdgeInsets.all(Spacing.xl2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              '¡Mensaje enviado!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Gracias por contactarnos. Te responderemos dentro de las próximas 24 horas hábiles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                
                height: 1.5,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            OutlinedButton(
              onPressed: () => setState(() => _enviado = false),
              child: const Text('Enviar otro mensaje'),
            ),
          ],
        ),
      );
    }

    return TicketCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl2),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envíanos un mensaje',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              _Field(
                controller: _nombreCtrl,
                label: 'Nombre completo',
                hint: 'Tu nombre',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: Spacing.lg),
              _Field(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: Spacing.lg),
              _Field(
                controller: _asuntoCtrl,
                label: 'Asunto',
                hint: '¿En qué podemos ayudarte?',
                prefixIcon: Icons.info_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: Spacing.lg),
              _Field(
                controller: _mensajeCtrl,
                label: 'Mensaje',
                hint: 'Describe tu consulta con el mayor detalle posible...',
                maxLines: 5,
                prefixIcon: Icons.chat_bubble_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim().length < 20) return 'Mínimo 20 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar mensaje',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      children: const [
        _InfoCard(
          icon: Icons.email_outlined,
          title: 'Email de soporte',
          subtitle: 'admin@somostrabajoya.cl',
          detail: 'Respuesta en menos de 24 h hábiles',
        ),
        SizedBox(height: Spacing.lg),
        _InfoCard(
          icon: Icons.access_time_outlined,
          title: 'Horario de atención',
          subtitle: 'Lunes a viernes',
          detail: '9:00 – 18:00 (hora Santiago)',
        ),
        SizedBox(height: Spacing.lg),
        _InfoCard(
          icon: Icons.location_on_outlined,
          title: 'Ubicación',
          subtitle: 'Santiago, Chile',
          detail: 'Operamos en todo el territorio nacional',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.blueprintTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle( color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.primary, size: 20)
                : null,
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
