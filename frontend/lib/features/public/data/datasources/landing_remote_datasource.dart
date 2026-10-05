import 'package:trabajoya_app/core/api/api_client.dart';

class LandingService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get('/landing/stats');
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexión: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHighlights({int limit = 5}) async {
    try {
      final response = await _apiClient.get(
        '/landing/highlights',
        queryParams: {'limit': limit.toString()},
      );
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexión: $e');
    }
  }
}
