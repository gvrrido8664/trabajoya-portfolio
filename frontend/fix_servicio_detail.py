import re

def main():
    filepath = 'lib/features/servicios/presentation/pages/servicio_detail_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Colors
    content = content.replace('Color(0xFFCA8A04)', 'AppColors.warning')
    content = content.replace('const Color(0xFFF0F9FF)', 'Theme.of(context).colorScheme.surfaceContainerHighest')
    content = content.replace('Color(0xFFEFF6FF)', 'Theme.of(context).colorScheme.surfaceContainerHigh')
    content = content.replace('Color(0xFFF8FAFC)', 'Theme.of(context).colorScheme.surface')

    # Fonts
    # Since it's a bit tricky to replace exact font sizes, we'll use regex or just leave them if they are part of explicit designs.
    # Actually, let's just replace all `fontSize: \d+,?` with `/* fontSize removed */` and let Flutter fall back to text styles.
    # Except for the hero icon font size (72) which is needed for the icon.
    content = re.sub(r'fontSize:\s*1[1-6],?', '', content)
    content = re.sub(r'fontSize:\s*2[0-9],?', '', content)
    content = re.sub(r'fontSize:\s*isMobile\s*\?\s*\d+\s*:\s*\d+,?', '', content)

    # Clean up empty TestStyles
    content = content.replace('TextStyle()', 'TextStyle()')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    main()
