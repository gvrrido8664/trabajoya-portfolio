import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          // Hero oscuro
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl,
                vertical: Spacing.xl3,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LEGAL',
                        style: TextStyle(
                          color: AppColors.blueprintTint,
                          
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          color: Colors.white,
                          
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        'Última actualización: junio 2026',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.xl3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Section(
                        title: '1. Aceptación de los términos',
                        body:
                            'Al acceder y utilizar la plataforma TrabajoYa, usted acepta estar legalmente vinculado por estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no podrá acceder al servicio. El uso continuado de la plataforma constituye la aceptación de cualquier modificación que realicemos.',
                      ),
                      _Section(
                        title: '2. Descripción del servicio',
                        body:
                            'TrabajoYa es un marketplace digital que conecta a clientes que necesitan servicios del hogar y profesionales con proveedores de servicios independientes. Actuamos como intermediarios y no somos parte de ningún contrato de servicio celebrado entre clientes y proveedores. No garantizamos la calidad, seguridad o legalidad de los servicios ofrecidos.',
                      ),
                      _Section(
                        title: '3. Registro y cuenta',
                        body:
                            'Para utilizar ciertas funciones de la plataforma, debe crear una cuenta. Usted es responsable de mantener la confidencialidad de su contraseña y de todas las actividades que ocurran bajo su cuenta. Las verificaciones de identidad y certificaciones (Sello Azul) son gestionadas y revisadas de forma manual por nuestro equipo administrativo, lo que puede tomar tiempo adicional. Debe notificarnos inmediatamente sobre cualquier uso no autorizado de su cuenta. Nos reservamos el derecho de cerrar cuentas en cualquier momento a nuestra discreción.',
                      ),
                      _Section(
                        title: '4. Obligaciones del usuario',
                        body:
                            'Usted se compromete a: (a) proporcionar información veraz y actualizada al registrarse; (b) no utilizar la plataforma para actividades ilegales o fraudulentas; (c) no publicar contenido ofensivo, difamatorio o que infrinja derechos de terceros; (d) cumplir con todas las leyes y regulaciones aplicables en su jurisdicción.',
                      ),
                      _Section(
                        title: '5. Pagos y comisiones',
                        body:
                            'TrabajoYa cobra una comisión por cada transacción completada a través de la plataforma. Los pagos se procesan a través de proveedores de pago seguros de terceros. Los fondos quedan retenidos hasta la confirmación de la finalización del servicio. Las disputas deben reportarse dentro de los 7 días posteriores a la finalización del trabajo.',
                      ),
                      _Section(
                        title: '6. Limitación de responsabilidad',
                        body:
                            'TrabajoYa no será responsable por daños indirectos, incidentales, especiales o consecuentes que resulten del uso o la imposibilidad de usar el servicio. Nuestra responsabilidad total ante usted por cualquier reclamación no excederá el monto pagado por usted en los últimos 12 meses.',
                      ),
                      _Section(
                        title: '7. Modificaciones',
                        body:
                            'Nos reservamos el derecho de modificar estos Términos en cualquier momento. Le notificaremos sobre cambios materiales con al menos 30 días de anticipación a través del correo electrónico registrado. El uso continuado de la plataforma después de dichos cambios constituye su aceptación de los nuevos Términos.',
                      ),
                      _Section(
                        title: '8. Ley aplicable',
                        body:
                            'Estos Términos se regirán e interpretarán de acuerdo con las leyes de la República de Chile. Cualquier disputa relacionada con estos Términos estará sujeta a la jurisdicción exclusiva de los tribunales competentes de Santiago de Chile.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer mínimo
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
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: TicketCard(
        padding: EdgeInsets.zero,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            iconColor: AppColors.primary,
            collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.lg,
            ),
            children: [
              Text(
                body,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
