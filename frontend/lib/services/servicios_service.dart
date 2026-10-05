import '../core/api/api_client.dart';
import '../features/servicios/data/models/servicio_model.dart';

class ServiciosService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Servicio>> getServicios({
    String? categoriaId,
    String? proveedorId,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoriaId != null) queryParams['categoria_id'] = categoriaId;
      if (proveedorId != null) queryParams['proveedor_id'] = proveedorId;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/servicios',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Servicio.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Servicio> getServicio(String id) async {
    try {
      final response = await _apiClient.get('/servicios/$id');
      return Servicio.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Servicio>> buscarServicios(
    double lat,
    double lng, {
    double? radioKm,
    String? categoriaId,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
      };
      if (radioKm != null) queryParams['radio_km'] = radioKm.toString();
      if (categoriaId != null) queryParams['categoria_id'] = categoriaId;
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        '/servicios/buscar',
        queryParams: queryParams,
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Servicio.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Servicio> crearServicio(
    String categoriaId,
    String titulo,
    String descripcion, {
    double? precioMin,
    double? precioMax,
    int? radioKm,
    String? direccion,
  }) async {
    try {
      final body = <String, dynamic>{
        'categoria_id': categoriaId,
        'titulo': titulo,
        'descripcion': descripcion,
      };
      if (precioMin != null) body['precio_min'] = precioMin;
      if (precioMax != null) body['precio_max'] = precioMax;
      if (radioKm != null) body['radio_cobertura_km'] = radioKm;
      if (direccion != null) body['direccion_texto'] = direccion;

      final response = await _apiClient.post('/servicios', body: body);
      return Servicio.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Servicio> actualizarServicio(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.put('/servicios/$id', body: data);
      return Servicio.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<String> togglePausar(String id) async {
    try {
      final response = await _apiClient.patch('/servicios/$id/pausar');
      return response['status'] as String? ?? '';
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> eliminarServicio(String id) async {
    try {
      await _apiClient.delete('/servicios/$id');
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
