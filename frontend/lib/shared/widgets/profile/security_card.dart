import 'package:go_router/go_router.dart';
import 'security_item_row.dart';
import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class SecurityCard extends StatelessWidget {
  final bool emailVerificado;
  final bool telefonoActivo;
  final String docEstado;

  const SecurityCard({super.key, 
    required this.emailVerificado,
    required this.telefonoActivo,
    required this.docEstado,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seguridad y verificaciones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estado de tus verificaciones de cuenta y opciones de seguridad.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SecurityItemRow(
              title: 'Correo verificado',
              subtitle:
                  'Tu correo principal está validado para iniciar sesión y recuperar acceso.',
              badgeLabel: emailVerificado ? 'Verificado' : 'Pendiente',
              isWarning: !emailVerificado,
            ),
            const SizedBox(height: 12),
            SecurityItemRow(
              title: 'Teléfono confirmado',
              subtitle:
                  'Tu número está disponible para coordinación con proveedores.',
              badgeLabel: telefonoActivo ? 'Activo' : 'Pendiente',
              isWarning: !telefonoActivo,
            ),
            const SizedBox(height: 12),
            SecurityItemRow(
              title: 'Verificación de identidad',
              subtitle: docEstado == 'approved'
                  ? 'Tu identidad ha sido validada.'
                  : (docEstado == 'pending'
                      ? 'Tus documentos están en revisión.'
                      : 'Verifica tu identidad para aumentar la confianza de los proveedores.'),
              badgeLabel: docEstado == 'approved'
                  ? 'Aprobada'
                  : (docEstado == 'pending' ? 'En revisión' : 'Pendiente'),
              isWarning: docEstado != 'approved',
            ),
            const SizedBox(height: 12),
            const SecurityItemRow(
              title: 'Cambio de contraseña',
              subtitle:
                  'Te conviene actualizarla si no lo has hecho recientemente.',
              badgeLabel: 'Recomendado',
              isWarning: true,
            ),
            const SizedBox(height: 20),
            // El CTA de "Verificar identidad" vive solo en la card "Ofrece
            // tus servicios" de abajo -- tenerlo repetido acá (mismo label,
            // misma ruta /seguridad/identidad) quedaba duplicado a
            // centímetros de distancia. Esta card muestra el estado (badge
            // arriba); la acción vive en un solo lugar.
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : null,
                  // Sin height fijo: "Verificación en dos pasos" envuelve a
                  // 2 líneas en móvil y un alto fijo de 44 cortaba la
                  // segunda -- el botón ahora crece con su contenido.
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/seguridad/2fa'),
                    icon: const Icon(Icons.security, size: 16),
                    label: const Text(
                      'Verificación en dos pasos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}