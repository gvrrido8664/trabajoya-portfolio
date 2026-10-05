import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/propuestas/data/models/propuesta_model.dart';

class PropuestasService {
  final ApiClient _apiClient = ApiClient();

  Future<Propuesta> crearPropuesta({
    required String solicitudId,
    required String descripcion,
    required double precio,
    required String tiempoEstimado,
  }) async {
    try {
      final response = await _apiClient.post(
        '/solicitudes/$solicitudId/propuestas',
        body: {
          'descripcion': descripcion,
          'precio': precio,
          'tiempo_estimado': tiempoEstimado,
        },
      );
      return Propuesta.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Propuesta>> getPropuestas(
    String solicitudId, {
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/solicitudes/$solicitudId/propuestas',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Propuesta.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Propuesta>> getMisPropuestas({int? skip, int? limit}) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/propuestas/mis-propuestas',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Propuesta.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Propuesta> aceptarPropuesta(
    String solicitudId,
    String propuestaId,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/solicitudes/$solicitudId/propuestas/$propuestaId/aceptar',
      );
      return Propuesta.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> rechazarPropuesta(String solicitudId, String propuestaId) async {
    try {
      await _apiClient.patch(
        '/solicitudes/$solicitudId/propuestas/$propuestaId/rechazar',
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
