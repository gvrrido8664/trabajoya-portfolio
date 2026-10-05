import 'package:trabajoya_app/core/api/api_client.dart';

class BugsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> reportarBug({
    required String titulo,
    required String descripcion,
    required String area,
  }) async {
    try {
      final response = await _apiClient.post(
        '/bugs',
        body: {'titulo': titulo, 'descripcion': descripcion, 'area': area},
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

  Future<List<dynamic>> getMisReportes() async {
    try {
      final response = await _apiClient.get('/bugs/mis-reportes');
      if (response is List) return response;
      return [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
