import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';

class PrivacidadScreen extends StatelessWidget {
  const PrivacidadScreen({super.key});

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
                        'PRIVACIDAD',
                        style: TextStyle(
                          color: AppColors.blueprintTint,
                          
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'Política de Privacidad',
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

          // Intro card
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.xl,
                    Spacing.xl2,
                    Spacing.xl,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(Spacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.blueprintTint,
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(color: AppColors.blueprint),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.md),
                        const Expanded(
                          child: Text(
                            'Tu privacidad es nuestra prioridad. Esta política explica qué datos recopilamos, cómo los usamos y cómo los protegemos.',
                            style: TextStyle(
                              color: AppColors.primary,
                              
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                    vertical: Spacing.xl2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Section(
                        title: '1. Información que recopilamos',
                        body:
                            'Recopilamos información que usted nos proporciona directamente, como nombre, correo electrónico, número de teléfono y ubicación al registrarse. Si solicita una verificación de identidad o certificación (Sello Azul), recopilamos los documentos y datos adicionales proporcionados. Estos documentos son revisados manualmente por nuestro equipo administrativo para garantizar la seguridad de la plataforma. También recopilamos información sobre cómo utiliza la plataforma, incluyendo páginas visitadas, servicios consultados y transacciones realizadas. Podemos recopilar información técnica como dirección IP, tipo de dispositivo y navegador.',
                      ),
                      _Section(
                        title: '2. Cómo usamos su información',
                        body:
                            'Utilizamos su información para: (a) proveer y mejorar nuestros servicios; (b) personalizar su experiencia en la plataforma; (c) procesar transacciones y enviar notificaciones relacionadas; (d) comunicarnos con usted sobre actualizaciones, promociones y soporte; (e) detectar y prevenir fraudes y abusos; (f) cumplir con obligaciones legales.',
                      ),
                      _Section(
                        title: '3. Compartir información',
                        body:
                            'No vendemos su información personal a terceros. Podemos compartir información con: proveedores de servicios que nos ayudan a operar la plataforma (procesadores de pago, servicios de análisis), otros usuarios cuando sea necesario para completar una transacción, y autoridades cuando lo exija la ley. Todos los terceros con acceso a sus datos están obligados a protegerlos.',
                      ),
                      _Section(
                        title: '4. Seguridad de los datos',
                        body:
                            'Implementamos medidas de seguridad técnicas y organizativas para proteger su información contra acceso no autorizado, alteración, divulgación o destrucción. Esto incluye cifrado SSL/TLS, almacenamiento seguro de contraseñas y auditorías de seguridad periódicas. Sin embargo, ningún método de transmisión por Internet es 100% seguro.',
                      ),
                      _Section(
                        title: '5. Cookies y tecnologías similares',
                        body:
                            'Utilizamos cookies y tecnologías similares para recordar sus preferencias, analizar el uso de la plataforma y personalizar contenido. Puede configurar su navegador para rechazar cookies, aunque esto puede afectar algunas funcionalidades. Utilizamos Google Analytics y otras herramientas de análisis que pueden establecer sus propias cookies.',
                      ),
                      _Section(
                        title: '6. Sus derechos',
                        body:
                            'Usted tiene derecho a: acceder a la información personal que tenemos sobre usted, corregir datos inexactos, solicitar la eliminación de sus datos (sujeto a obligaciones legales), oponerse al procesamiento de sus datos para marketing directo, y portabilidad de datos. Para ejercer estos derechos, contáctenos en privacidad@trabajoya.cl.',
                      ),
                      _Section(
                        title: '7. Retención de datos',
                        body:
                            'Conservamos su información personal mientras su cuenta esté activa o según sea necesario para proveer servicios. Si cierra su cuenta, eliminaremos o anonimizaremos su información dentro de los 90 días, excepto donde la ley exija conservación por más tiempo.',
                      ),
                      _Section(
                        title: '8. Cambios a esta política',
                        body:
                            'Podemos actualizar esta Política de Privacidad periódicamente. Le notificaremos sobre cambios significativos por correo electrónico o mediante un aviso destacado en la plataforma antes de que los cambios entren en vigor.',
                      ),
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
