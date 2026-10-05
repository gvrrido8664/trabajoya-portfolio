import re

def main():
    filepath = 'lib/features/contrataciones/presentation/pages/solicitar_servicio_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Literals
    content = content.replace('theme.cardColor', 'CliColors.surface(context)')
    content = content.replace('theme.dividerColor', 'CliColors.border(context)')
    content = content.replace('theme.colorScheme.primary', 'CliColors.accent')
    content = content.replace('theme.colorScheme.surfaceContainerLow', 'CliColors.surface(context)')
    content = content.replace('theme.colorScheme.outlineVariant', 'CliColors.border(context)')
    
    # Text colors
    content = content.replace('theme.textTheme.headlineMedium?.color', 'CliColors.textPrimary(context)')
    content = content.replace('theme.textTheme.titleMedium?.color', 'CliColors.textPrimary(context)')
    content = content.replace('theme.textTheme.bodyMedium?.color', 'CliColors.textSecondary(context)')
    content = content.replace('theme.textTheme.bodySmall?.color', 'CliColors.textSecondary(context)')

    # Add Colors white explicit just in case withValues is failing because of it
    content = content.replace('CliColors.textSecondary(context)?.withValues(alpha: 0.6)', 'CliColors.textSecondary(context)')
    content = content.replace('CliColors.textSecondary(context)?.withValues(alpha: 0.82)', 'CliColors.textSecondary(context)')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
