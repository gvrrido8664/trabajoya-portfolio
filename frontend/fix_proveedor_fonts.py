import re
import os
import glob

def main():
    pages_dir = 'lib/features/proveedor/presentation/pages'
    files = glob.glob(os.path.join(pages_dir, '*.dart'))
    files.append('lib/features/proveedor/presentation/widgets/pro_ui.dart')

    for filepath in files:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            # Colors
            content = content.replace('Color(0xFFCA8A04)', 'ProColors.amber')
            content = content.replace('Color(0xFF0F172A)', 'ProColors.bg')
            content = content.replace('Color(0xFF334155)', 'ProColors.border')
            content = content.replace('Color(0xFFFEF3C7)', 'ProColors.amberTint')
            content = content.replace('Color(0xFFA16207)', 'ProColors.amber')

            # Fonts: remove fontSize:\s*\d+\.?[0-9]*\s*,? except for specific cases where they are part of a responsive check
            # We'll use a regex that catches `fontSize: X` or `fontSize: X.X`
            # For simplicity, just matching `fontSize:\s*\d+(\.\d+)?`
            # Since Pro UI used custom sizes, it might be safer to remove them to inherit from text styles
            # But wait, does it inherit correctly? ProScaffold doesn't inject a TextTheme, so it inherits the AppTheme's textTheme.
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
