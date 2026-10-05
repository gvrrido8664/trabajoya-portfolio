class Categoria {
  final String id;
  final String nombre;
  final String slug;
  final String? icono;
  final String? descripcion;
  final String? parentId;
  final List<Categoria> subcategorias;

  Categoria({
    required this.id,
    required this.nombre,
    required this.slug,
    this.icono,
    this.descripcion,
    this.parentId,
    this.subcategorias = const [],
  });

  bool get esRaiz =>
      parentId == null && subcategorias.isNotEmpty || (parentId == null);

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icono: json['icono'] as String?,
      descripcion: json['descripcion'] as String?,
      parentId: (json['parent_id']?.toString() ?? '').isEmpty
          ? null
          : json['parent_id'].toString(),
      subcategorias: (json['subcategorias'] as List<dynamic>? ?? [])
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'slug': slug,
      'icono': icono,
      'descripcion': descripcion,
      'parent_id': parentId,
    };
  }
}
