import 'package:trabajoya_app/core/api/api_client.dart';

class PagosService {
  final ApiClient _apiClient = ApiClient();

  // ─── MercadoPago ──────────────────────────────────────

  Future<Map<String, dynamic>> crearPagoMP(String contratacionId) async {
    try {
      final response = await _apiClient.post(
        '/pagos/crear?contratacion_id=$contratacionId',
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

  Future<Map<String, dynamic>> acordarEnPersona(String contratacionId) async {
    try {
      final response = await _apiClient.post(
        '/pagos/acordar-en-persona?contratacion_id=$contratacionId',
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

  // ─── Estado común ─────────────────────────────────────

  Future<Map<String, dynamic>> getEstadoPago(String contratacionId) async {
    try {
      final response = await _apiClient.get('/pagos/$contratacionId/estado');
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
