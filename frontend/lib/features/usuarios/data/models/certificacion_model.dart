class Certificacion {
  final String id;
  final String usuarioId;
  final String titulo;
  final String institucion;
  final String archivoUrl;
  final DateTime? fechaEmision;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  Certificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.institucion,
    required this.archivoUrl,
    this.fechaEmision,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certificacion.fromJson(Map<String, dynamic> json) {
    return Certificacion(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String,
      institucion: json['institucion'] as String,
      archivoUrl: json['archivo_url'] as String,
      fechaEmision: json['fecha_emision'] != null
          ? DateTime.parse(json['fecha_emision'] as String)
          : null,
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'institucion': institucion,
      'archivo_url': archivoUrl,
      'fecha_emision': fechaEmision?.toIso8601String(),
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
