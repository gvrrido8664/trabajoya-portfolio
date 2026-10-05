class Mensaje {
  final String id;
  final String contratacionId;
  final String emisorId;
  final String contenido;
  final bool leido;
  final DateTime createdAt;

  Mensaje({
    required this.id,
    required this.contratacionId,
    required this.emisorId,
    required this.contenido,
    required this.leido,
    required this.createdAt,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: json['id']?.toString() ?? '',
      contratacionId:
          json['contratacion_id']?.toString() ??
          json['contratacionId']?.toString() ??
          '',
      emisorId:
          json['emisor_id']?.toString() ?? json['emisorId']?.toString() ?? '',
      contenido: json['contenido'] as String? ?? '',
      leido: json['leido'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contratacion_id': contratacionId,
      'emisor_id': emisorId,
      'contenido': contenido,
      'leido': leido,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
