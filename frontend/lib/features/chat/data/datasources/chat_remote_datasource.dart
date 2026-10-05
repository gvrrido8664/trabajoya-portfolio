import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/chat/data/models/mensaje_model.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getConversaciones() async {
    try {
      final response = await _apiClient.get('/chat/conversaciones');
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

  Future<List<Mensaje>> getMensajes(
    String contratacionId, {
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/chat/$contratacionId/mensajes',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Mensaje.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
