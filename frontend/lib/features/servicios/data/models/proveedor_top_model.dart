class ProveedorTop {
  final String id;
  final String nombre;
  final String? avatarUrl;
  final double? avgRating;
  final String? bio;
  final String? habilidades;
  final int totalContratos;
  final bool proveedorEsPremium;
  final bool identidadVerificada;
  final DateTime? miembroDesde;

  ProveedorTop({
    required this.id,
    required this.nombre,
    this.avatarUrl,
    this.avgRating,
    this.bio,
    this.habilidades,
    required this.totalContratos,
    this.proveedorEsPremium = false,
    this.identidadVerificada = false,
    this.miembroDesde,
  });

  factory ProveedorTop.fromJson(Map<String, dynamic> json) {
    return ProveedorTop(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      habilidades: json['habilidades'] as String?,
      totalContratos: (json['total_contratos'] as num?)?.toInt() ?? 0,
      proveedorEsPremium: json['proveedor_es_premium'] as bool? ?? false,
      identidadVerificada: json['identidad_verificada'] as bool? ?? false,
      miembroDesde: json['miembro_desde'] != null
          ? DateTime.tryParse(json['miembro_desde'] as String)
          : null,
    );
  }
}
