import os

def remove_line(filepath, text_to_remove):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        with open(filepath, 'w', encoding='utf-8') as f:
            for line in lines:
                if text_to_remove not in line:
                    f.write(line)
        print(f"Removed {text_to_remove} from {filepath}")
    except Exception as e:
        print(f"Failed {filepath}: {e}")

def main():
    remove_line('lib/features/contrataciones/presentation/pages/mis_contrataciones_screen.dart', "import 'package:trabajoya_app/utils/colors.dart';")
    remove_line('lib/features/proveedor/presentation/pages/proveedor_shell.dart', "import 'package:trabajoya_app/app/theme.dart';")
    remove_line('lib/features/servicios/presentation/pages/servicios_list_screen.dart', "import 'package:trabajoya_app/app/theme.dart';")
    remove_line('test/widget_test.dart', "import 'dart:convert';")

if __name__ == '__main__':
    main()
