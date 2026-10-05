import '../core/api/api_client.dart';

class UploadService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    try {
      final response = await _apiClient.uploadMultipart(
        '/upload/avatar',
        filePath: filePath,
        fileField: 'file',
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

  Future<Map<String, dynamic>> uploadFotoServicio(
    String servicioId,
    String filePath,
  ) async {
    try {
      final response = await _apiClient.uploadMultipart(
        '/upload/servicio/$servicioId',
        filePath: filePath,
        fileField: 'file',
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
