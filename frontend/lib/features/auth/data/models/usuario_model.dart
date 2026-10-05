class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String apellido;
  final String rol;
  final bool esCliente;
  final bool esProveedor;
  final DateTime? proveedorActivadoAt;
  final double avgRatingProveedor;
  final double avgRatingCliente;
  final String? telefono;
  final String? avatarUrl;
  final String? bio;
  final String? habilidades;
  final String? comuna;
  final String? codigoReferido;
  final bool isActive;
  final bool isVerified;
  final bool emailVerificado;
  final bool telefonoVerificado;
  final bool totpEnabled;
  final String docEstado;
  final int verificationLevel;
  final double avgRating;
  final int referidosCount;
  final bool mpConfigured;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.rol,
    this.esCliente = true,
    this.esProveedor = false,
    this.proveedorActivadoAt,
    this.avgRatingProveedor = 0,
    this.avgRatingCliente = 0,
    this.telefono,
    this.avatarUrl,
    this.bio,
    this.habilidades,
    this.comuna,
    this.codigoReferido,
    required this.isActive,
    required this.isVerified,
    this.emailVerificado = false,
    this.telefonoVerificado = false,
    this.totpEnabled = false,
    this.docEstado = 'none',
    this.verificationLevel = 0,
    required this.avgRating,
    required this.referidosCount,
    this.mpConfigured = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      rol: json['rol'] as String? ?? 'cliente',
      // Fallback legacy: si el backend todavía no manda es_proveedor/es_cliente
      // (versión previa a la migración de capacidades), lo derivamos del rol.
      esCliente: json['es_cliente'] as bool? ?? (json['rol'] != 'proveedor'),
      esProveedor: json['es_proveedor'] as bool? ?? (json['rol'] == 'proveedor'),
      proveedorActivadoAt: json['proveedor_activado_at'] != null
          ? DateTime.parse(json['proveedor_activado_at'])
          : null,
      avgRatingProveedor:
          (json['avg_rating_proveedor'] as num? ?? 0).toDouble(),
      avgRatingCliente: (json['avg_rating_cliente'] as num? ?? 0).toDouble(),
      telefono: json['telefono'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      habilidades: json['habilidades'] as String?,
      comuna: json['comuna'] as String?,
      codigoReferido:
          json['codigo_referido'] as String? ??
          json['codigoReferido'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      emailVerificado:
          json['email_verificado'] as bool? ??
          json['emailVerificado'] as bool? ??
          false,
      telefonoVerificado:
          json['telefono_verificado'] as bool? ??
          json['telefonoVerificado'] as bool? ??
          false,
      totpEnabled:
          json['totp_enabled'] as bool? ??
          json['totpEnabled'] as bool? ??
          false,
      docEstado:
          json['doc_estado'] as String? ??
          json['docEstado'] as String? ??
          'none',
      verificationLevel:
          json['verification_level'] as int? ??
          json['verificationLevel'] as int? ??
          0,
      avgRating: (json['avg_rating'] as num? ?? json['avgRating'] as num? ?? 0)
          .toDouble(),
      referidosCount:
          json['referidos_count'] as int? ??
          json['referidosCount'] as int? ??
          0,
      mpConfigured:
          json['mp_configured'] as bool? ??
          json['mpConfigured'] as bool? ??
          false,
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
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
      'es_cliente': esCliente,
      'es_proveedor': esProveedor,
      'proveedor_activado_at': proveedorActivadoAt?.toIso8601String(),
      'avg_rating_proveedor': avgRatingProveedor,
      'avg_rating_cliente': avgRatingCliente,
      'telefono': telefono,
      'avatar_url': avatarUrl,
      'bio': bio,
      'habilidades': habilidades,
      'comuna': comuna,
      'codigo_referido': codigoReferido,
      'is_active': isActive,
      'is_verified': isVerified,
      'email_verificado': emailVerificado,
      'avg_rating': avgRating,
      'referidos_count': referidosCount,
      'mp_configured': mpConfigured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Capacidad, no rol fijo: una cuenta puede tener ambas habilitadas.
  bool get isProveedor => esProveedor;
  bool get isAdmin => rol == 'admin';
  bool get isCliente => esCliente;

  String get nombreCompleto => '$nombre $apellido';

  Usuario copyWith({
    String? id,
    String? email,
    String? nombre,
    String? apellido,
    String? rol,
    bool? esCliente,
    bool? esProveedor,
    DateTime? proveedorActivadoAt,
    double? avgRatingProveedor,
    double? avgRatingCliente,
    String? telefono,
    String? avatarUrl,
    String? bio,
    String? habilidades,
    String? comuna,
    String? codigoReferido,
    bool? isActive,
    bool? isVerified,
    bool? emailVerificado,
    bool? telefonoVerificado,
    bool? totpEnabled,
    String? docEstado,
    int? verificationLevel,
    double? avgRating,
    int? referidosCount,
    bool? mpConfigured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      rol: rol ?? this.rol,
      esCliente: esCliente ?? this.esCliente,
      esProveedor: esProveedor ?? this.esProveedor,
      proveedorActivadoAt: proveedorActivadoAt ?? this.proveedorActivadoAt,
      avgRatingProveedor: avgRatingProveedor ?? this.avgRatingProveedor,
      avgRatingCliente: avgRatingCliente ?? this.avgRatingCliente,
      telefono: telefono ?? this.telefono,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      habilidades: habilidades ?? this.habilidades,
      comuna: comuna ?? this.comuna,
      codigoReferido: codigoReferido ?? this.codigoReferido,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      telefonoVerificado: telefonoVerificado ?? this.telefonoVerificado,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      docEstado: docEstado ?? this.docEstado,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      avgRating: avgRating ?? this.avgRating,
      referidosCount: referidosCount ?? this.referidosCount,
      mpConfigured: mpConfigured ?? this.mpConfigured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
