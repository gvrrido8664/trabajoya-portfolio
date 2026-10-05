class Servicio {
  final String id;
  final String proveedorId;
  final String categoriaId;
  final String? subcategoriaId;
  final String titulo;
  final String descripcion;
  final String status;
  final double? precioMin;
  final double? precioMax;
  final int radioCoberturaKm;
  final String? direccionTexto;
  final double? latitud;
  final double? longitud;
  final List<String>? fotos;
  final double? distancia;
  final String? proveedorNombre;
  final double? proveedorRating;
  final String? proveedorDocEstado;
  final bool proveedorEsPremium;
  final String? categoriaNombre;
  final String? categoriaIcono;
  final String? subcategoriaNombre;
  final String? subcategoriaIcono;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Servicio({
    required this.id,
    required this.proveedorId,
    required this.categoriaId,
    this.subcategoriaId,
    required this.titulo,
    required this.descripcion,
    required this.status,
    this.precioMin,
    this.precioMax,
    required this.radioCoberturaKm,
    this.direccionTexto,
    this.latitud,
    this.longitud,
    this.fotos,
    this.distancia,
    this.proveedorNombre,
    this.proveedorRating,
    this.proveedorDocEstado,
    this.proveedorEsPremium = false,
    this.categoriaNombre,
    this.categoriaIcono,
    this.subcategoriaNombre,
    this.subcategoriaIcono,
    required this.createdAt,
    this.updatedAt,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id']?.toString() ?? '',
      proveedorId:
          json['proveedor_id']?.toString() ??
          json['proveedorId']?.toString() ??
          '',
      categoriaId:
          json['categoria_id']?.toString() ??
          json['categoriaId']?.toString() ??
          '',
      subcategoriaId:
          json['subcategoria_id']?.toString() ??
          json['subcategoriaId']?.toString(),
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVO',
      precioMin: (json['precio_min'] as num? ?? json['precioMin'] as num?)
          ?.toDouble(),
      precioMax: (json['precio_max'] as num? ?? json['precioMax'] as num?)
          ?.toDouble(),
      radioCoberturaKm:
          json['radio_cobertura_km'] as int? ??
          json['radioCoberturaKm'] as int? ??
          10,
      direccionTexto:
          json['direccion_texto'] as String? ??
          json['direccionTexto'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      fotos: json['fotos'] is List
          ? (json['fotos'] as List).map((e) => e.toString()).toList()
          : json['fotos'] != null
          ? [json['fotos'].toString()]
          : null,
      distancia: (json['distancia'] as num?)?.toDouble(),
      proveedorNombre: json['proveedor_nombre'] as String?,
      proveedorRating: (json['proveedor_rating'] as num?)?.toDouble(),
      proveedorDocEstado: json['proveedor_doc_estado'] as String?,
      proveedorEsPremium: json['proveedor_es_premium'] as bool? ?? false,
      categoriaNombre: json['categoria_nombre'] as String?,
      categoriaIcono: json['categoria_icono'] as String?,
      subcategoriaNombre: json['subcategoria_nombre'] as String?,
      subcategoriaIcono: json['subcategoria_icono'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proveedor_id': proveedorId,
      'categoria_id': categoriaId,
      'titulo': titulo,
      'descripcion': descripcion,
      'status': status,
      'precio_min': precioMin,
      'precio_max': precioMax,
      'radio_cobertura_km': radioCoberturaKm,
      'direccion_texto': direccionTexto,
      'latitud': latitud,
      'longitud': longitud,
      'fotos': fotos,
      'distancia': distancia,
      'proveedor_nombre': proveedorNombre,
      'proveedor_rating': proveedorRating,
      'proveedor_es_premium': proveedorEsPremium,
      'categoria_nombre': categoriaNombre,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  List<String> get fotosList => fotos ?? [];

  bool get isActivo => status == 'ACTIVO';
  bool get isPausado => status == 'PAUSADO';
  bool get isEliminado => status == 'ELIMINADO';
}
