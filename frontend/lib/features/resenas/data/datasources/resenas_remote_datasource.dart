import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/resenas/data/models/resena_model.dart';

class ResenasService {
  final ApiClient _apiClient = ApiClient();

  Future<Resena> crearResena(
    String contratacionId, {
    required int puntuacion,
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{'puntuacion': puntuacion};
      if (comentario != null) body['comentario'] = comentario;
      final response = await _apiClient.post(
        '/resenas/$contratacionId',
        body: body,
      );
      return Resena.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Resena>> getResenasUsuario(
    String usuarioId, {
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      final response = await _apiClient.get(
        '/resenas/usuario/$usuarioId',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Resena.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
