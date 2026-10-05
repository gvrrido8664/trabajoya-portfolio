import 'package:flutter/material.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  bool _loading = false;
  List<dynamic> _categorias = [];

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  /// Convierte un texto en un slug url-friendly (minúsculas, sin acentos ni
  /// espacios). Evita crear categorías con slug vacío o con caracteres que
  /// rompan la búsqueda pública por slug.
  String _slugify(String input) {
    var s = input.toLowerCase().trim();
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    return s
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _loadCategorias() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/categorias');
      if (mounted) setState(() => _categorias = res as List<dynamic>);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formatError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCategoriaDialog({Map<String, dynamic>? categoria}) {
    final isEditing = categoria != null;
    final nombreCtrl = TextEditingController(text: categoria?['nombre']);
    final slugCtrl = TextEditingController(text: categoria?['slug']);
    final iconoCtrl = TextEditingController(text: categoria?['icono'] ?? '📁');
    final descCtrl = TextEditingController(text: categoria?['descripcion']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar categoría' : 'Nueva categoría'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nombreCtrl, 'Nombre', autofocus: true),
                const SizedBox(height: Spacing.md),
                _dialogField(
                  slugCtrl,
                  'Slug (opcional, se genera del nombre)',
                ),
                const SizedBox(height: Spacing.md),
                _dialogField(iconoCtrl, 'Ícono (emoji, ej. 🎨)'),
                const SizedBox(height: Spacing.md),
                _dialogField(descCtrl, 'Descripción', maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }
              final slug = slugCtrl.text.trim().isEmpty
                  ? _slugify(nombre)
                  : _slugify(slugCtrl.text);
              Navigator.pop(ctx);
              final data = {
                'nombre': nombre,
                'slug': slug,
                'icono': iconoCtrl.text.trim(),
                'descripcion': descCtrl.text.trim(),
              };
              try {
                if (isEditing) {
                  await ApiClient().put(
                    '/categorias/${categoria['id']}',
                    body: data,
                  );
                } else {
                  await ApiClient().post('/categorias', body: data);
                }
                await _loadCategorias();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(formatError(e)),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSubcategoriaDialog(
    String parentId, {
    Map<String, dynamic>? subcategoria,
  }) {
    final isEditing = subcategoria != null;
    final nombreCtrl = TextEditingController(text: subcategoria?['nombre']);
    final slugCtrl = TextEditingController(text: subcategoria?['slug']);
    final iconoCtrl = TextEditingController(text: subcategoria?['icono'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar subcategoría' : 'Nueva subcategoría'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nombreCtrl, 'Nombre', autofocus: true),
                const SizedBox(height: Spacing.md),
                _dialogField(iconoCtrl, 'Ícono (emoji, ej. 🎨)'),
                const SizedBox(height: Spacing.md),
                _dialogField(
                  slugCtrl,
                  'Slug (opcional, se genera del nombre)',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nombre = nombreCtrl.text.trim();
              if (nombre.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
                return;
              }
              final slug = slugCtrl.text.trim().isEmpty
                  ? _slugify(nombre)
                  : _slugify(slugCtrl.text);
              Navigator.pop(ctx);
              final data = {
                'nombre': nombre,
                'slug': slug,
                'icono': iconoCtrl.text.trim(),
                'categoria_id': parentId,
              };
              try {
                if (isEditing) {
                  await ApiClient().put(
                    '/categorias/subcategorias/${subcategoria['id']}',
                    body: data,
                  );
                } else {
                  await ApiClient().post(
                    '/categorias/$parentId/subcategorias',
                    body: data,
                  );
                }
                await _loadCategorias();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(formatError(e)),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntity(String path, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar?'),
        content: Text('Se eliminará "$nombre". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient().delete(path);
      await _loadCategorias();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formatError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoriaDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategorias,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, index) =>
                    _CategoriaCard(
                      cat: _categorias[index] as Map<String, dynamic>,
                      onEditCat: _showCategoriaDialog,
                      onDeleteCat: _deleteEntity,
                      onAddSub: _showSubcategoriaDialog,
                      onEditSub: _showSubcategoriaDialog,
                      onDeleteSub: _deleteEntity,
                    ),
              ),
            ),
    );
  }
}

/// True si el texto empieza con un carácter no-ASCII (un emoji), y no una
/// palabra como "category" que el diálogo viejo guardaba por defecto y que se
/// vería fea renderizada como texto.
bool _esEmoji(String? s) {
  final t = s?.trim();
  return t != null && t.isNotEmpty && t.codeUnitAt(0) > 127;
}

/// Tarjeta de categoría con subcategorías expandibles. Mantiene el chevron de
/// expandir (no se sobrescribe `trailing`) para que las subcategorías sean
/// siempre accesibles; las acciones viven dentro del contenido expandido.
class _CategoriaCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  final void Function({Map<String, dynamic>? categoria}) onEditCat;
  final Future<void> Function(String path, String nombre) onDeleteCat;
  final void Function(String parentId, {Map<String, dynamic>? subcategoria})
  onAddSub;
  final void Function(String parentId, {Map<String, dynamic>? subcategoria})
  onEditSub;
  final Future<void> Function(String path, String nombre) onDeleteSub;

  const _CategoriaCard({
    required this.cat,
    required this.onEditCat,
    required this.onDeleteCat,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
  });

  @override
  Widget build(BuildContext context) {
    final subs = cat['subcategorias'] as List<dynamic>? ?? [];
    final icono = (cat['icono'] as String?)?.trim();
    final descripcion = (cat['descripcion'] as String?)?.trim();
    final id = cat['id']?.toString() ?? '';
    final nombre = cat['nombre']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: Elevation.e1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: _esEmoji(icono)
                ? Text(icono!, style: const TextStyle(fontSize: 20))
                : const Icon(
                    Icons.folder_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
          ),
          title: Text(
            nombre,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            descripcion != null && descripcion.isNotEmpty
                ? descripcion
                : '${subs.length} subcategoría${subs.length == 1 ? '' : 's'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [
            // Acciones de la categoría (dentro del contenido expandido).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Row(
                children: [
                  Text(
                    'Categoría',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => onEditCat(categoria: cat),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar'),
                  ),
                  TextButton.icon(
                    onPressed: () => onDeleteCat('/categorias/$id', nombre),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...subs.map((s) {
              final sub = s as Map<String, dynamic>;
              final subId = sub['id']?.toString() ?? '';
              final subNombre = sub['nombre']?.toString() ?? '';
              final subIcono = (sub['icono'] as String?)?.trim();
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 24, right: 8),
                dense: true,
                leading: _esEmoji(subIcono)
                    ? Text(subIcono!, style: const TextStyle(fontSize: 18))
                    : Icon(
                        Icons.subdirectory_arrow_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                title: Text(
                  subNombre,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Editar subcategoría',
                      onPressed: () => onEditSub(id, subcategoria: sub),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      tooltip: 'Eliminar subcategoría',
                      onPressed: () => onDeleteSub(
                        '/categorias/subcategorias/$subId',
                        subNombre,
                      ),
                    ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onAddSub(id),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Agregar subcategoría'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
