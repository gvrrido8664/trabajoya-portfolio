import re
import sys
import glob

def main():
    files = [
        'lib/features/servicios/presentation/pages/servicios_list_screen.dart',
        'lib/shared/widgets/empty_state.dart',
        'lib/shared/widgets/servicio_card.dart',
        'lib/features/servicios/presentation/pages/servicio_detail_screen.dart'
    ]
    for filepath in files:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            content = content.replace('Theme.of(context).cardColor', 'CliColors.surface(context)')
            content = content.replace('theme.cardColor', 'CliColors.surface(context)')
            content = content.replace('Theme.of(context).dividerColor', 'CliColors.border(context)')
            content = content.replace('theme.dividerColor', 'CliColors.border(context)')
            content = content.replace('Theme.of(context).colorScheme.primary', 'CliColors.accent')
            content = content.replace('theme.colorScheme.primary', 'CliColors.accent')
            content = content.replace('Theme.of(context).colorScheme.surfaceContainerLow', 'CliColors.surface(context)')
            content = content.replace('theme.colorScheme.surfaceContainerLow', 'CliColors.surface(context)')
            content = content.replace('Theme.of(context).colorScheme.outlineVariant', 'CliColors.border(context)')
            content = content.replace('theme.colorScheme.outlineVariant', 'CliColors.border(context)')
            content = content.replace('AppTheme.danger', 'AppColors.danger')
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed {filepath}")
        except FileNotFoundError:
            pass

if __name__ == '__main__':
    main()
