import re
import sys
import glob

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove fontSize: <digits>,
    content = re.sub(r'fontSize:\s*\d+\.?[0-9]*\s*,?\s*', '', content)
    # Remove fontSize: isTablet ? 34 : 26,
    content = re.sub(r'fontSize:\s*isTablet\s*\?\s*\d+\s*:\s*\d+\s*,?\s*', '', content)
    
    # Remove empty TextStyle()
    content = re.sub(r'style:\s*(?:const\s+)?TextStyle\(\s*\),?', '', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Fixed {filepath}")

def main():
    files = glob.glob('lib/features/cliente/**/*.dart', recursive=True)
    for file in files:
        fix_file(file)

if __name__ == '__main__':
    main()
