import '../core/api/api_client.dart';
import '../features/contrataciones/data/models/contratacion_model.dart';
import '../features/resenas/data/models/resena_model.dart';

class ContratacionesService {
  final ApiClient _apiClient = ApiClient();

  Future<Contratacion> crearContratacion(
    String servicioId, {
    double? monto,
    String? mensaje,
    DateTime? fecha,
  }) async {
    try {
      final body = <String, dynamic>{'servicio_id': servicioId};
      if (monto != null) body['monto_acordado'] = monto;
      if (mensaje != null) body['mensaje_solicitud'] = mensaje;
      if (fecha != null) body['fecha_programada'] = fecha.toIso8601String();

      final response = await _apiClient.post('/contrataciones', body: body);
      return Contratacion.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Contratacion>> getMisContrataciones() async {
    try {
      final response = await _apiClient.get('/contrataciones');
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Contratacion.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Contratacion> getContratacion(String id) async {
    try {
      final response = await _apiClient.get('/contrataciones/$id');
      return Contratacion.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> aceptarContratacion(String id) async {
    try {
      await _apiClient.patch('/contrataciones/$id/aceptar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> rechazarContratacion(String id) async {
    try {
      await _apiClient.patch('/contrataciones/$id/rechazar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> finalizarContratacion(String id) async {
    try {
      await _apiClient.patch('/contrataciones/$id/finalizar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Resena> crearResena(
    String contratacionId,
    int puntuacion, {
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{
        'contratacion_id': contratacionId,
        'puntuacion': puntuacion,
      };
      if (comentario != null) body['comentario'] = comentario;

      final response = await _apiClient.post(
        '/contrataciones/$contratacionId/resena',
        body: body,
      );
      return Resena.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Resena>> getResenasUsuario(String usuarioId) async {
    try {
      final response = await _apiClient.get('/resenas/usuario/$usuarioId');
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Resena.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> abrirDisputa(
    String contratacionId,
    String motivo, {
    List<String>? evidencias,
  }) async {
    try {
      final body = <String, dynamic>{
        'contratacion_id': contratacionId,
        'motivo': motivo,
      };
      if (evidencias != null) body['evidencias'] = evidencias;

      final response = await _apiClient.post('/disputas', body: body);
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
