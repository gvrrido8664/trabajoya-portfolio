import 'package:trabajoya_app/core/api/api_client.dart';

class SuscripcionesService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> crearSuscripcion(String planSlug) async {
    try {
      final response = await _apiClient.post(
        '/suscripciones/crear',
        body: {'plan_slug': planSlug},
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

  Future<Map<String, dynamic>> getMiSuscripcion() async {
    try {
      final response = await _apiClient.get('/suscripciones/me');
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> cancelarSuscripcion() async {
    try {
      await _apiClient.post('/suscripciones/cancelar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<dynamic>> getPlanes() async {
    try {
      final response = await _apiClient.get('/suscripciones/planes');
      return response is List ? response : [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
