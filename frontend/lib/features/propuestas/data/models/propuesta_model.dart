class Propuesta {
  final String id;
  final String solicitudId;
  final String proveedorId;
  final String descripcion;
  final double precio;
  final String tiempoEstimado;
  final String status;
  final String? proveedorNombre;
  final String? solicitudTitulo;
  final String? contratacionId;
  final DateTime? createdAt;

  Propuesta({
    required this.id,
    required this.solicitudId,
    required this.proveedorId,
    required this.descripcion,
    required this.precio,
    required this.tiempoEstimado,
    required this.status,
    this.proveedorNombre,
    this.solicitudTitulo,
    this.contratacionId,
    this.createdAt,
  });

  factory Propuesta.fromJson(Map<String, dynamic> json) {
    return Propuesta(
      id: json['id']?.toString() ?? '',
      solicitudId: json['solicitud_id']?.toString() ?? '',
      proveedorId: json['proveedor_id']?.toString() ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      tiempoEstimado: json['tiempo_estimado'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDIENTE',
      proveedorNombre: json['proveedor_nombre'] as String?,
      solicitudTitulo: json['solicitud_titulo'] as String?,
      contratacionId: json['contratacion_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  bool get isPendiente => status == 'PENDIENTE';
  bool get isAceptada => status == 'ACEPTADA';
  bool get isRechazada => status == 'RECHAZADA';
}
