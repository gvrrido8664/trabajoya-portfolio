import re
import subprocess
import os

def run_analyze():
    print("Running flutter analyze...")
    result = subprocess.run("flutter analyze", shell=True, capture_output=True, text=True)
    return result.stdout + "\n" + result.stderr

def fix_const_errors():
    output = run_analyze()
    # Find all lines like: error - Methods can't be invoked in constant expressions - lib\features\auth\presentation\pages\totp_setup_screen.dart:189:20 - const_eval_method_invocation
    pattern = r"error - Methods can't be invoked in constant expressions - (.*?):(\d+):\d+ - const_eval_method_invocation"
    matches = re.findall(pattern, output)
    
    if not matches:
        print("No const errors found.")
        return False
        
    print(f"Found {len(matches)} const errors to fix.")
    
    files_to_fix = {}
    for filepath, line_str in matches:
        line_idx = int(line_str) - 1
        if filepath not in files_to_fix:
            files_to_fix[filepath] = []
        files_to_fix[filepath].append(line_idx)
        
    for filepath, lines in files_to_fix.items():
        if not os.path.exists(filepath):
            continue
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
            
        # For each error line, we go upwards to find the closest 'const ' and remove it
        # We sort lines descending so we can modify without affecting line indices of earlier lines? No, indices are same
        lines = sorted(list(set(lines)), reverse=True)
        for line_idx in lines:
            # Look backwards from line_idx up to 10 lines
            for i in range(line_idx, max(-1, line_idx - 10), -1):
                if 'const ' in content[i]:
                    content[i] = re.sub(r'\bconst\s+', '', content[i], count=1)
                    break
                    
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(content)
            
    return True

if __name__ == "__main__":
    while fix_const_errors():
        pass
    print("Done!")
