import 'info_grid_tile.dart';
import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class PersonalInfoCard extends StatelessWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String location;
  final String rol;
  final bool isTablet;
  final VoidCallback onEditarPerfil;

  const PersonalInfoCard({super.key, 
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.location,
    required this.rol,
    required this.isTablet,
    required this.onEditarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
            Builder(
              builder: (context) {
                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Información personal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Datos principales del cliente.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
                final editButton = ElevatedButton.icon(
                  onPressed: onEditarPerfil,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(
                    'Editar perfil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                );
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // El botón fijo al lado del título dejaba muy poco
                    // ancho para "Información personal" en móvil,
                    // envolviéndolo letra por letra; se apila debajo.
                    if (constraints.maxWidth < 340) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleBlock,
                          const SizedBox(height: 14),
                          editButton,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: titleBlock),
                        const SizedBox(width: 12),
                        editButton,
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTablet ? 2 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 90,
              ),
              children: [
                InfoGridTile(label: 'Tipo de usuario', value: rol),
                InfoGridTile(label: 'Correo', value: email),
                InfoGridTile(label: 'Nombre', value: firstName),
                InfoGridTile(label: 'Apellido', value: lastName),
                InfoGridTile(label: 'Teléfono', value: phone),
                InfoGridTile(label: 'Comuna', value: location),
              ],
            ),
          ],
        ),
      ),
    );
  }
}