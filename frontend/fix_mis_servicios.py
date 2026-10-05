import re
import os

def main():
    files = [
        'lib/features/servicios/presentation/pages/crear_editar_servicio_screen.dart',
        'lib/features/servicios/presentation/pages/mis_servicios_screen.dart',
    ]

    for filepath in files:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            # Colors
            content = content.replace('Color(0xFF94A3B8)', 'ProColors.textSecondary')
            content = content.replace('Color(0x264FA9EC)', 'ProColors.accent.withValues(alpha: 0.15)')

            # Fonts
            content = re.sub(r'fontSize:\s*\d+(\.\d+)?\s*,?', '', content)

            # Clean up empty TestStyles
            content = content.replace('TextStyle()', 'TextStyle()')

            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed {filepath}")
        except Exception as e:
            print(f"Failed on {filepath}: {e}")

if __name__ == '__main__':
    main()
