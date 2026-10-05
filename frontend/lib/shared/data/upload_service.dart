import 'package:image_picker/image_picker.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

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

  String _mimeFromName(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> eliminarArchivo(String publicId) async {
    try {
      await _apiClient.delete('/upload/$publicId');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> uploadFotoServicioXFile(
    String servicioId,
    XFile xfile,
  ) async {
    final bytes = await xfile.readAsBytes();
    return uploadFotoServicioBytes(
      servicioId,
      bytes,
      xfile.name,
      xfile.mimeType,
    );
  }

  Future<Map<String, dynamic>> uploadFotoServicioBytes(
    String servicioId,
    List<int> bytes,
    String filename,
    String? mimeType,
  ) async {
    try {
      final mime = mimeType ?? _mimeFromName(filename);
      final response = await _apiClient.uploadMultipartFromBytes(
        '/upload/servicio/$servicioId',
        bytes: bytes,
        filename: filename,
        fileField: 'file',
        contentType: mime,
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
