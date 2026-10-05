import 'package:flutter/material.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/solicitudes/data/datasources/solicitudes_remote_datasource.dart';
import 'package:trabajoya_app/features/solicitudes/data/models/solicitud_model.dart';

class SolicitudesProvider extends ChangeNotifier {
  final SolicitudesService _service = SolicitudesService();
  List<Solicitud> _solicitudes = [];
  List<Solicitud> _misSolicitudes = [];
  Solicitud? _selected;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  static const int _pageSize = 20;

  List<Solicitud> get solicitudes => _solicitudes;
  List<Solicitud> get misSolicitudes => _misSolicitudes;
  Solicitud? get selected => _selected;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> cargarSolicitudes({String? categoriaId}) async {
    _loading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      _solicitudes = await _service.getSolicitudes(
        categoriaId: categoriaId,
        skip: 0,
        limit: _pageSize,
      );
      _hasMore = _solicitudes.length >= _pageSize;
      _page = 1;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarMas({String? categoriaId}) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final results = await _service.getSolicitudes(
        categoriaId: categoriaId,
        skip: _page * _pageSize,
        limit: _pageSize,
      );
      _solicitudes.addAll(results);
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

  Future<void> getSolicitud(String id) async {
    _error = null;
    try {
      _selected = await _service.getSolicitud(id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = formatError(e);
      notifyListeners();
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
    }
  }

  Future<void> cargarMisSolicitudes({int? limit}) async {
    _loading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      _misSolicitudes = await _service.getMisSolicitudes(
        skip: 0,
        limit: limit ?? _pageSize,
      );
      _hasMore = _misSolicitudes.length >= (limit ?? _pageSize);
      _page = 1;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarMasMisSolicitudes({int? limit}) async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final results = await _service.getMisSolicitudes(
        skip: _page * (limit ?? _pageSize),
        limit: limit ?? _pageSize,
      );
      _misSolicitudes.addAll(results);
      _hasMore = results.length >= (limit ?? _pageSize);
      _page++;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<bool> crearSolicitud({
    required String titulo,
    required String descripcion,
    String? categoriaId,
    double? presupuestoMax,
    String? ubicacionTexto,
  }) async {
    _error = null;
    try {
      await _service.crearSolicitud(
        titulo: titulo,
        descripcion: descripcion,
        categoriaId: categoriaId,
        presupuestoMax: presupuestoMax,
        ubicacionTexto: ubicacionTexto,
      );
      await cargarMisSolicitudes();
      return true;
    } on ApiException catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> cerrarSolicitud(String id) async {
    _error = null;
    try {
      await _service.cerrarSolicitud(id);
      await getSolicitud(id);
      await cargarMisSolicitudes();
      return true;
    } on ApiException catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    }
  }
}
