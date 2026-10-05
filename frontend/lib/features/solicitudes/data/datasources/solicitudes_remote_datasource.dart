import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';

class SolicitudesService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Solicitud>> getSolicitudes({
    String? categoriaId,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoriaId != null) queryParams['categoria_id'] = categoriaId;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      final response = await _apiClient.get(
        '/solicitudes',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Solicitud.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Solicitud>> getMisSolicitudes({int? skip, int? limit}) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      final response = await _apiClient.get(
        '/solicitudes/mis-solicitudes',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Solicitud.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Solicitud> getSolicitud(String id) async {
    try {
      final response = await _apiClient.get('/solicitudes/$id');
      return Solicitud.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> cerrarSolicitud(String id) async {
    try {
      await _apiClient.patch('/solicitudes/$id/cerrar');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Solicitud> crearSolicitud({
    required String titulo,
    required String descripcion,
    String? categoriaId,
    double? presupuestoMax,
    String? ubicacionTexto,
  }) async {
    try {
      final body = <String, dynamic>{
        'titulo': titulo,
        'descripcion': descripcion,
      };
      if (categoriaId != null) body['categoria_id'] = categoriaId;
      if (presupuestoMax != null) body['presupuesto_max'] = presupuestoMax;
      if (ubicacionTexto != null) body['ubicacion_texto'] = ubicacionTexto;
      final response = await _apiClient.post('/solicitudes', body: body);
      return Solicitud.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
