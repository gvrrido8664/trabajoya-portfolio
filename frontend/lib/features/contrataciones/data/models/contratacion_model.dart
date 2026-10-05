class Contratacion {
  final String id;
  final String clienteId;
  final String proveedorId;
  final String? servicioId;
  final String? propuestaId;
  final String status;
  final double? montoAcordado;
  final String? mensajeSolicitud;
  final DateTime? fechaProgramada;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? servicioTitulo;
  final String? clienteNombre;
  final String? proveedorNombre;
  final String? categoriaNombre;
  final String? categoriaIcono;
  final String? subcategoriaNombre;
  final String? subcategoriaIcono;
  final String? pagoStatus;
  final String? payoutStatus;
  final bool hasReviewed;

  Contratacion({
    required this.id,
    required this.clienteId,
    required this.proveedorId,
    this.servicioId,
    this.propuestaId,
    required this.status,
    this.montoAcordado,
    this.mensajeSolicitud,
    this.fechaProgramada,
    this.createdAt,
    this.updatedAt,
    this.servicioTitulo,
    this.clienteNombre,
    this.proveedorNombre,
    this.categoriaNombre,
    this.categoriaIcono,
    this.subcategoriaNombre,
    this.subcategoriaIcono,
    this.pagoStatus,
    this.payoutStatus,
    this.hasReviewed = false,
  });

  factory Contratacion.fromJson(Map<String, dynamic> json) {
    return Contratacion(
      id: json['id']?.toString() ?? '',
      clienteId:
          json['cliente_id']?.toString() ?? json['clienteId']?.toString() ?? '',
      proveedorId:
          json['proveedor_id']?.toString() ??
          json['proveedorId']?.toString() ??
          '',
      servicioId:
          json['servicio_id']?.toString() ?? json['servicioId']?.toString(),
      propuestaId:
          json['propuesta_id']?.toString() ?? json['propuestaId']?.toString(),
      status: json['status'] as String? ?? 'PENDIENTE',
      montoAcordado:
          (json['monto_acordado'] as num? ?? json['montoAcordado'] as num?)
              ?.toDouble(),
      mensajeSolicitud:
          json['mensaje_solicitud'] as String? ??
          json['mensajeSolicitud'] as String?,
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.parse(json['fecha_programada'])
          : json['fechaProgramada'] != null
          ? DateTime.parse(json['fechaProgramada'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      servicioTitulo:
          json['servicio_titulo'] as String? ??
          json['servicioTitulo'] as String?,
      clienteNombre:
          json['cliente_nombre'] as String? ?? json['clienteNombre'] as String?,
      proveedorNombre:
          json['proveedor_nombre'] as String? ??
          json['proveedorNombre'] as String?,
      categoriaNombre: json['categoria_nombre'] as String?,
      categoriaIcono: json['categoria_icono'] as String?,
      subcategoriaNombre: json['subcategoria_nombre'],
      subcategoriaIcono: json['subcategoria_icono'],
      pagoStatus: json['pago_status'] ?? json['pagoStatus'],
      payoutStatus: json['payout_status'] ?? json['payoutStatus'],
      hasReviewed: json['has_reviewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'proveedor_id': proveedorId,
      'servicio_id': servicioId ?? '',
      'propuesta_id': propuestaId,
      'status': status,
      'monto_acordado': montoAcordado,
      'mensaje_solicitud': mensajeSolicitud,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'servicio_titulo': servicioTitulo,
      'cliente_nombre': clienteNombre,
      'proveedor_nombre': proveedorNombre,
      'subcategoria_nombre': subcategoriaNombre,
      'subcategoria_icono': subcategoriaIcono,
      'pago_status': pagoStatus,
      'has_reviewed': hasReviewed,
    };
  }

  bool get isPendiente => status == 'PENDIENTE';
  bool get isAceptada => status == 'ACEPTADO';
  bool get isAceptado => status == 'ACEPTADO';
  bool get isRechazada => status == 'RECHAZADO';
  bool get isFinalizada => status == 'COMPLETADO';
  bool get isCompletada => status == 'COMPLETADO';
  bool get isCancelada => status == 'CANCELADO';
  bool get isEnDisputa => status == 'DISPUTA';
}
