import re
import sys
import glob

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace Theme colors with CliColors
    content = content.replace('Theme.of(context).colorScheme.onSurfaceVariant', 'CliColors.textSecondary(context)')
    content = content.replace('Theme.of(context).colorScheme.onSurface', 'CliColors.textPrimary(context)')
    content = content.replace('Theme.of(context).colorScheme.primary', 'CliColors.accent')
    content = content.replace('Theme.of(context).colorScheme.onPrimary', 'Colors.white')
    content = content.replace('Theme.of(context).colorScheme.error', 'AppColors.danger')
    content = content.replace('Theme.of(context).dividerColor', 'CliColors.border(context)')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Fixed {filepath}")

def main():
    files = glob.glob('lib/features/cliente/**/*.dart', recursive=True) + glob.glob('lib/features/contrataciones/**/*.dart', recursive=True)
    for file in files:
        fix_file(file)

if __name__ == '__main__':
    main()
