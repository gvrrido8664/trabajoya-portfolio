import re

def main():
    # 1. crear_solicitud_screen.dart
    p = 'lib/features/cliente/presentation/pages/crear_solicitud_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'package:trabajoya_app/utils/colors.dart' not in content:
        content = "import 'package:trabajoya_app/utils/colors.dart';\n" + content
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 2. mis_solicitudes_screen.dart
    p = 'lib/features/cliente/presentation/pages/mis_solicitudes_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('AppTheme.danger', 'AppColors.danger')
    content = content.replace('AppTheme.success', 'AppColors.success')
    content = content.replace('AppTheme.secondary', 'AppColors.secondary')
    content = content.replace('AppTheme.', 'AppColors.')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 3. mis_servicios_screen.dart
    p = 'lib/features/servicios/presentation/pages/mis_servicios_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const [\n          ProColors.accent.withValues', '[\n          ProColors.accent.withValues')
    content = content.replace('const [ProColors.accent.withValues', '[ProColors.accent.withValues')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 4. Add amberTint to pro_palette.dart
    p = 'lib/shared/theme/pro_palette.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'amberTint' not in content:
        content = content.replace('static const Color amber = Color(0xFF8A6508);', 'static const Color amber = Color(0xFF8A6508);\n  static const Color amberTint = Color(0xFFF5EBD6);')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
