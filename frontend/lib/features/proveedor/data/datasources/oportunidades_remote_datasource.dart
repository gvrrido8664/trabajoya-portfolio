import 'package:trabajoya_app/core/api/api_client.dart';

class OportunidadesService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getOportunidades({int? limit}) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      final response = await _apiClient.get(
        '/oportunidades',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response is List) return response;
      return response['items'] as List<dynamic>? ?? [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
