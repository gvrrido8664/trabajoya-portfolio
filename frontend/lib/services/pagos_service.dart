import '../core/api/api_client.dart';

class PagosService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> crearPago(String contratacionId) async {
    try {
      final response = await _apiClient.post(
        '/pagos',
        body: {'contratacion_id': contratacionId},
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

  Future<Map<String, dynamic>> getEstadoPago(String contratacionId) async {
    try {
      final response = await _apiClient.get('/pagos/$contratacionId');
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
