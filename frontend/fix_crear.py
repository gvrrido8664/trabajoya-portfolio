import re

def main():
    filepath = 'lib/features/cliente/presentation/pages/crear_solicitud_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacing literals
    content = content.replace('Theme.of(context).cardColor', 'CliColors.surface(context)')
    content = content.replace('colorScheme.surfaceContainerHighest', 'CliColors.surface(context)')
    content = content.replace('colorScheme.onSurfaceVariant', 'CliColors.textSecondary(context)')
    content = content.replace('colorScheme.onSurface', 'CliColors.textPrimary(context)')
    content = content.replace('colorScheme.outlineVariant', 'CliColors.border(context)')
    content = content.replace('colorScheme.outline', 'CliColors.border(context)')
    content = content.replace('colorScheme.primary', 'CliColors.accent')
    content = content.replace('colorScheme.error', 'AppColors.danger')
    content = content.replace('Theme.of(context).colorScheme.shadow', 'Colors.black')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
