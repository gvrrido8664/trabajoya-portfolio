import re
import sys
import glob

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace Shimmer colors
    content = content.replace('const Color(0xFFE2E8F0)', 'AppColors.border')
    content = content.replace('const Color(0xFFF1F5F9)', 'AppColors.background')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Fixed {filepath}")

def main():
    files = glob.glob('lib/features/cliente/**/*.dart', recursive=True)
    for file in files:
        fix_file(file)

if __name__ == '__main__':
    main()
