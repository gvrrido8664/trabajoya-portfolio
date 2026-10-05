class Resena {
  final String id;
  final String contratacionId;
  final String calificadorId;
  final String calificadoId;
  final int puntuacion;
  final String? comentario;
  final DateTime createdAt;

  Resena({
    required this.id,
    required this.contratacionId,
    required this.calificadorId,
    required this.calificadoId,
    required this.puntuacion,
    this.comentario,
    required this.createdAt,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id']?.toString() ?? '',
      contratacionId:
          json['contratacion_id']?.toString() ??
          json['contratacionId']?.toString() ??
          '',
      calificadorId:
          json['calificador_id']?.toString() ??
          json['calificadorId']?.toString() ??
          '',
      calificadoId:
          json['calificado_id']?.toString() ??
          json['calificadoId']?.toString() ??
          '',
      puntuacion: json['puntuacion'] as int? ?? 0,
      comentario: json['comentario'] as String?,
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
      'calificador_id': calificadorId,
      'calificado_id': calificadoId,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
