import '../core/api/api_client.dart';

class AdminService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiClient.get('/admin/stats');
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> getUsuarios({
    String? rol,
    String? email,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (rol != null) queryParams['rol'] = rol;
      if (email != null) queryParams['email'] = email;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/admin/usuarios',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
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

  Future<Map<String, dynamic>> toggleUsuarioActivo(String id) async {
    try {
      final response = await _apiClient.patch(
        '/admin/usuarios/$id/toggle-active',
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

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/admin/usuarios', body: data);
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put('/admin/usuarios/$id', body: data);
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> getServiciosAdmin({
    String? status,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/admin/servicios',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
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

  Future<Map<String, dynamic>> getPagosAdmin({
    String? status,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/admin/pagos',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
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

  Future<Map<String, dynamic>> getDisputas({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        '/disputas/admin',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
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

  Future<Map<String, dynamic>> resolverDisputa(
    String disputaId,
    String resolucion,
    String accion,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/disputas/admin/$disputaId/resolver?accion=$accion',
        body: {'resolucion': resolucion},
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
