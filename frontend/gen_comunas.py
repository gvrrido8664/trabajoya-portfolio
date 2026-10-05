import urllib.request
import json
import codecs

req = urllib.request.Request('https://gist.githubusercontent.com/rhernandog/9247c7c376180a3a14e9f73315a676eb/raw/8227bde268d8ef5381d58ba7a1b4d008bb9e6939/regiones-provincias-comunas.json')
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read().decode('utf-8'))

regiones_comunas = {}
for reg in data:
    reg_name = reg['region']
    comunas = reg['comunas']
    comunas.sort()
    regiones_comunas[reg_name] = comunas

# Let's sort the regions too
sorted_regions = sorted(regiones_comunas.keys())

with codecs.open('lib/core/constants/comunas.dart', 'w', 'utf-8') as f:
    f.write('class ComunasChile {\n')
    f.write('  static const Map<String, List<String>> regionesYComunas = {\n')
    
    for reg in sorted_regions:
        reg_esc = reg.replace("'", "\\'")
        f.write(f"    '{reg_esc}': [\n")
        for c in regiones_comunas[reg]:
            c_esc = c.replace("'", "\\'")
            f.write(f"      '{c_esc}',\n")
        f.write("    ],\n")
    f.write('  };\n')
    
    f.write('\n  static List<String> get todasLasRegiones => regionesYComunas.keys.toList();\n')
    f.write('\n  static List<String> get todasLasComunas => regionesYComunas.values.expand((element) => element).toList();\n')
    f.write('}\n')

print('Generated map with regions and comunas.')
