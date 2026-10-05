import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/proveedor_top_model.dart';

class ServiciosService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Servicio>> getServicios({
    String? categoriaId,
    String? categoriaPadreId,
    String? proveedorId,
    String? q,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoriaPadreId != null) {
        queryParams['categoria_padre_id'] = categoriaPadreId;
      }
      if (categoriaId != null) queryParams['categoria_id'] = categoriaId;
      if (proveedorId != null) queryParams['proveedor_id'] = proveedorId;
      if (q != null) queryParams['q'] = q;
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
    String? categoriaPadreId,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': lat.toString(),
        'lng': lng.toString(),
      };
      if (radioKm != null) queryParams['radio_km'] = radioKm.toString();
      if (categoriaPadreId != null) {
        queryParams['categoria_padre_id'] = categoriaPadreId;
      }
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
    String? subcategoriaId,
    double? precioMin,
    double? precioMax,
    int? radioKm,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final body = <String, dynamic>{
        'categoria_id': categoriaId,
        'titulo': titulo,
        'descripcion': descripcion,
      };
      if (subcategoriaId != null) body['subcategoria_id'] = subcategoriaId;
      if (precioMin != null) body['precio_min'] = precioMin;
      if (precioMax != null) body['precio_max'] = precioMax;
      if (radioKm != null) body['radio_cobertura_km'] = radioKm;
      if (direccion != null) body['direccion_texto'] = direccion;
      if (latitud != null) body['latitud'] = latitud;
      if (longitud != null) body['longitud'] = longitud;

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

  Future<bool> toggleDestacar(String id) async {
    try {
      final response = await _apiClient.post('/servicios/$id/destacar');
      return response['es_destacado'] as bool? ?? false;
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

  Future<Categoria> getCategoria(String slug) async {
    try {
      final response = await _apiClient.get('/categorias/$slug');
      return Categoria.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<Categoria>> getCategorias() async {
    try {
      final response = await _apiClient.get('/categorias');
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => Categoria.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<List<ProveedorTop>> getTopProveedores({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/proveedores/top',
        queryParams: {'limit': limit.toString()},
      );
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      return data.map((e) => ProveedorTop.fromJson(e)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }
}
