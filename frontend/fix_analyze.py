import re
import os

def main():
    # 1. crear_solicitud_screen.dart (Add AppColors import)
    p = 'lib/features/cliente/presentation/pages/crear_solicitud_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'package:trabajoya_app/utils/colors.dart' not in content:
        content = content.replace("import 'package:trabajoya_app/app/theme.dart';", "import 'package:trabajoya_app/app/theme.dart';\nimport 'package:trabajoya_app/utils/colors.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 2. mis_solicitudes_screen.dart (Fix AppTheme -> AppColors.danger and import)
    p = 'lib/features/cliente/presentation/pages/mis_solicitudes_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('AppTheme.danger', 'AppColors.danger')
    content = content.replace('AppTheme.success', 'AppColors.success')
    if 'package:trabajoya_app/utils/colors.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:trabajoya_app/utils/colors.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 3. perfil_publico_proveedor_screen.dart (const ProColors -> ProColors, and add import)
    p = 'lib/features/proveedor/presentation/pages/perfil_publico_proveedor_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const ProColors.', 'ProColors.')
    if 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 4. proveedor_profile_screen.dart (const ProColors -> ProColors)
    p = 'lib/features/proveedor/presentation/pages/proveedor_profile_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const ProColors.', 'ProColors.')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 5. proveedor_shell.dart (const ProColors -> ProColors, and add import)
    p = 'lib/features/proveedor/presentation/pages/proveedor_shell.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const ProColors.', 'ProColors.')
    if 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:trabajoya_app/features/proveedor/presentation/widgets/pro_ui.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 6. mis_servicios_screen.dart (remove const from list with withValues)
    p = 'lib/features/servicios/presentation/pages/mis_servicios_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    # It might be `const LinearGradient(..., colors: const [ProColors...` or something.
    content = content.replace('const LinearGradient(', 'LinearGradient(')
    content = content.replace('const [ProColors.accent.withValues', '[ProColors.accent.withValues')
    content = content.replace('const BoxDecoration(\n        gradient: LinearGradient', 'BoxDecoration(\n        gradient: LinearGradient')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 7. servicio_detail_screen.dart (remove const from LinearGradient with Theme.of(context))
    p = 'lib/features/servicios/presentation/pages/servicio_detail_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const BoxDecoration(\n        gradient: LinearGradient', 'BoxDecoration(\n        gradient: LinearGradient')
    content = content.replace('const LinearGradient(', 'LinearGradient(')
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 8. servicios_list_screen.dart (AppColors import, const AppColors -> AppColors)
    p = 'lib/features/servicios/presentation/pages/servicios_list_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('const AppColors.', 'AppColors.')
    if 'package:trabajoya_app/utils/colors.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:trabajoya_app/utils/colors.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

    # 9. servicio_card.dart (CliColors import)
    p = 'lib/shared/widgets/servicio_card.dart'
    with open(p, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'cli_ui.dart' not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';")
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
