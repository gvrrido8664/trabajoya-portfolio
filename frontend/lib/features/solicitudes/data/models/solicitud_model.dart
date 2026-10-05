class Solicitud {
  final String id;
  final String clienteId;
  final String? categoriaId;
  final String? categoriaNombre;
  final String titulo;
  final String descripcion;
  final double? presupuestoMax;
  final String? ubicacionTexto;
  final String status;
  final String? clienteNombre;
  final int propuestasCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Solicitud({
    required this.id,
    required this.clienteId,
    this.categoriaId,
    this.categoriaNombre,
    required this.titulo,
    required this.descripcion,
    this.presupuestoMax,
    this.ubicacionTexto,
    required this.status,
    this.clienteNombre,
    this.propuestasCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    return Solicitud(
      id: json['id']?.toString() ?? '',
      clienteId: json['cliente_id']?.toString() ?? '',
      categoriaId: json['categoria_id']?.toString(),
      categoriaNombre: json['categoria_nombre'] as String?,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      presupuestoMax: (json['presupuesto_max'] as num?)?.toDouble(),
      ubicacionTexto: json['ubicacion_texto'] as String?,
      status: json['status'] as String? ?? 'ABIERTA',
      clienteNombre: json['cliente_nombre'] as String?,
      propuestasCount: json['propuestas_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  bool get isAbierta => status == 'ABIERTA';
  bool get isCerrada => status == 'CERRADA';
}
