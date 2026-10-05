import urllib.request, json, codecs

try:
    # 1. Fetch Regiones
    req_reg = urllib.request.Request('https://apis.digital.gob.cl/dpa/regiones', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req_reg) as url:
        regiones_data = json.loads(url.read().decode())
    
    # 2. Fetch Comunas
    req_com = urllib.request.Request('https://apis.digital.gob.cl/dpa/comunas', headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req_com) as url:
        comunas_data = json.loads(url.read().decode())

    # Map region codigo to nombre
    regiones_map = {r['codigo']: r['nombre'] for r in regiones_data}
    
    # Map Region Nombre -> List[Comuna Nombre]
    regiones_comunas = {r['nombre']: [] for r in regiones_data}

    for c in comunas_data:
        reg_code = c['codigoPadre'][:2] if len(c['codigo']) > 2 else c['codigoPadre']
        # The API structure: comuna -> provincia -> region. 
        # Actually, dpa/comunas returns codigoPadre as Provincia code. 
        # To get the Region, it's the first 2 digits of the comuna code.
        reg_code = c['codigo'][:2]
        if reg_code in regiones_map:
            reg_name = regiones_map[reg_code]
            regiones_comunas[reg_name].append(c['nombre'])

except Exception as e:
    print('Failed API:', e)
    # Fallback
    regiones_comunas = {
        'Región Metropolitana de Santiago': ['Santiago', 'Providencia', 'Las Condes', 'Maipú'],
        'Región de Valparaíso': ['Valparaíso', 'Viña del Mar', 'Quilpué']
    }

for reg in regiones_comunas:
    regiones_comunas[reg].sort()

# Sort regions alphabetically
sorted_regions = sorted(regiones_comunas.keys())

with codecs.open('lib/core/constants/comunas.dart', 'w', 'utf-8') as f:
    f.write('class ComunasChile {\n')
    f.write('  static const Map<String, List<String>> regionesYComunas = {\n')
    
    for reg in sorted_regions:
        reg_esc = reg.replace(chr(39), chr(92) + chr(39))
        f.write(f"    '{reg_esc}': [\n")
        for c in regiones_comunas[reg]:
            c_esc = c.replace(chr(39), chr(92) + chr(39))
            f.write(f"      '{c_esc}',\n")
        f.write("    ],\n")
    f.write('  };\n')
    
    f.write('\n  static List<String> get todas Las Regiones => regionesYComunas.keys.toList();\n')
    f.write('}\n')

print('Generated map with', len(sorted_regions), 'regions.')
