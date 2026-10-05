import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/data/datasources/servicios_remote_datasource.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/shared/data/upload_service.dart';

class ServiciosProvider extends ChangeNotifier {
  final ServiciosService _service = ServiciosService();
  final ApiClient _apiClient = ApiClient();
  List<Servicio> _servicios = [];
  List<Categoria> _categorias = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  static const int _pageSize = 20;

  List<Servicio> get servicios => _servicios;
  List<Categoria> get categorias => _categorias;
  List<Categoria> get categoriasRaiz =>
      _categorias.where((c) => c.esRaiz).toList();
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> cargarServicios({
    String? categoriaId,
    String? categoriaPadreId,
    String? proveedorId,
    String? q,
  }) async {
    _loading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      final results = await _service.getServicios(
        categoriaId: categoriaId,
        categoriaPadreId: categoriaPadreId,
        proveedorId: proveedorId,
        q: q,
        skip: 0,
        limit: _pageSize,
      );
      _servicios = results;
      _hasMore = results.length >= _pageSize;
      _page = 1;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarMas({
    String? categoriaId,
    String? categoriaPadreId,
    String? proveedorId,
  }) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final results = await _service.getServicios(
        categoriaId: categoriaId,
        categoriaPadreId: categoriaPadreId,
        proveedorId: proveedorId,
        skip: _page * _pageSize,
        limit: _pageSize,
      );
      _servicios.addAll(results);
      _hasMore = results.length >= _pageSize;
      _page++;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loadingMore = false;
    notifyListeners();
  }

  List<Categoria> subcategoriasDe(String? parentId) {
    if (parentId == null) return [];
    try {
      return _categorias.firstWhere((c) => c.id == parentId).subcategorias;
    } catch (_) {
      return [];
    }
  }

  Future<void> cargarCategorias() async {
    try {
      final response = await _apiClient.get('/categorias');
      final List<dynamic> data = response is List
          ? response
          : (response['items'] ?? []);
      _categorias = data.map((e) => Categoria.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> buscarCercanos(
    double lat,
    double lng, {
    double? radioKm,
    String? categoriaId,
    String? categoriaPadreId,
  }) async {
    _loading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      _servicios = await _service.buscarServicios(
        lat,
        lng,
        radioKm: radioKm,
        categoriaId: categoriaId,
        categoriaPadreId: categoriaPadreId,
        skip: 0,
        limit: _pageSize,
      );
      _hasMore = _servicios.length >= _pageSize;
      _page = 1;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loading = false;
    notifyListeners();
  }

  // CRUD operations centralized in provider
  Future<Servicio> crearServicio(
    String categoriaId,
    String titulo,
    String descripcion, {
    String? subcategoriaId,
    double? precioMin,
    double? precioMax,
    int radioKm = 10,
    String? direccion,
    double? latitud,
    double? longitud,
    List<String>? fotos,
  }) async {
    try {
      final nuevo = await _service.crearServicio(
        categoriaId,
        titulo,
        descripcion,
        subcategoriaId: subcategoriaId,
        precioMin: precioMin,
        precioMax: precioMax,
        radioKm: radioKm,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
      );
      if (fotos != null && fotos.isNotEmpty) {
        final upload = UploadService();
        for (final path in fotos) {
          try {
            await upload.uploadFotoServicio(nuevo.id, path);
          } catch (_) {}
        }
      }
      return nuevo;
    } catch (e) {
      rethrow;
    }
  }

  Future<Servicio> actualizarServicio(
    String id,
    Map<String, dynamic> data, {
    List<String>? fotos,
  }) async {
    try {
      final actualizado = await _service.actualizarServicio(id, data);
      if (fotos != null && fotos.isNotEmpty) {
        final upload = UploadService();
        for (final path in fotos) {
          try {
            await upload.uploadFotoServicio(id, path);
          } catch (_) {}
        }
      }
      return actualizado;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> eliminarServicio(String id) async {
    try {
      await _service.eliminarServicio(id);
      _servicios.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> togglePausar(String id) async {
    try {
      final nuevoStatus = await _service.togglePausar(id);
      final idx = _servicios.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final s = _servicios[idx];
        _servicios[idx] = Servicio(
          id: s.id,
          proveedorId: s.proveedorId,
          categoriaId: s.categoriaId,
          subcategoriaId: s.subcategoriaId,
          titulo: s.titulo,
          descripcion: s.descripcion,
          status: nuevoStatus.toUpperCase(),
          precioMin: s.precioMin,
          precioMax: s.precioMax,
          radioCoberturaKm: s.radioCoberturaKm,
          direccionTexto: s.direccionTexto,
          latitud: s.latitud,
          longitud: s.longitud,
          fotos: s.fotos,
          distancia: s.distancia,
          proveedorNombre: s.proveedorNombre,
          proveedorRating: s.proveedorRating,
          categoriaNombre: s.categoriaNombre,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Servicio> getServicioById(String id) async {
    try {
      return await _service.getServicio(id);
    } catch (e) {
      rethrow;
    }
  }
}
