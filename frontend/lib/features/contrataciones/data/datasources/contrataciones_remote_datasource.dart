import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/contrataciones/data/models/contratacion_model.dart';
import 'package:trabajoya_app/features/resenas/data/models/resena_model.dart';

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

  Future<List<Contratacion>> getMisContrataciones({
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/contrataciones',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
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
      await _apiClient.post('/contrataciones/$id/completar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> cancelarContratacion(String id) async {
    try {
      await _apiClient.patch('/contrataciones/$id/cancelar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> actualizarMonto(String id, double nuevoMonto) async {
    try {
      await _apiClient.patch(
        '/contrataciones/$id/monto',
        body: {'monto_acordado': nuevoMonto},
      );
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

  Future<List<Resena>> getResenasUsuario(
    String usuarioId, {
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/contrataciones/usuario/$usuarioId/resenas',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

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
      final body = <String, dynamic>{'motivo': motivo};
      if (evidencias != null) body['evidencias'] = evidencias;

      final response = await _apiClient.post(
        '/disputas/contratacion/$contratacionId',
        body: body,
      );
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
