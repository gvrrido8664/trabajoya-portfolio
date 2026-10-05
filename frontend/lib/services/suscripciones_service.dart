import '../core/api/api_client.dart';

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
}
