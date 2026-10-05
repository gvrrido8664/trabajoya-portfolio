import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/contrataciones/data/models/contratacion_model.dart';
import 'package:trabajoya_app/features/contrataciones/data/datasources/contrataciones_remote_datasource.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

class ContratacionesProvider extends ChangeNotifier {
  final ContratacionesService _service = ContratacionesService();
  List<Contratacion> _contrataciones = [];
  Contratacion? _selected;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;
  static const int _pageSize = 20;

  List<Contratacion> get contrataciones => _contrataciones;
  Contratacion? get selected => _selected;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> cargarContrataciones() async {
    _loading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      _contrataciones = await _service.getMisContrataciones(
        skip: 0,
        limit: _pageSize,
      );
      _hasMore = _contrataciones.length >= _pageSize;
      _page = 1;
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarMas() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final results = await _service.getMisContrataciones(
        skip: _page * _pageSize,
        limit: _pageSize,
      );
      _contrataciones.addAll(results);
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

  Future<void> getContratacion(String id) async {
    _error = null;
    // Evita mostrar la contratación anterior mientras carga la nueva o si
    // el id pedido no existe/no es accesible.
    _selected = null;
    try {
      _selected = await _service.getContratacion(id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = formatError(e);
      notifyListeners();
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
    }
  }

  Future<bool> aceptar(String id) async {
    _error = null;
    try {
      await _service.aceptarContratacion(id);
      await getContratacion(id);
      await cargarContrataciones();
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

  Future<bool> rechazar(String id) async {
    _error = null;
    try {
      await _service.rechazarContratacion(id);
      await getContratacion(id);
      await cargarContrataciones();
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

  Future<bool> finalizar(String id) async {
    _error = null;
    try {
      await _service.finalizarContratacion(id);
      await getContratacion(id);
      await cargarContrataciones();
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

  Future<bool> cancelar(String id) async {
    _error = null;
    try {
      await _service.cancelarContratacion(id);
      await getContratacion(id);
      await cargarContrataciones();
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

  Future<bool> actualizarMonto(String id, double nuevoMonto) async {
    _error = null;
    try {
      await _service.actualizarMonto(id, nuevoMonto);
      await getContratacion(id);
      await cargarContrataciones();
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

  Future<bool> crearResena({
    required String contratacionId,
    required int puntuacion,
    String? comentario,
  }) async {
    _error = null;
    try {
      await _service.crearResena(
        contratacionId,
        puntuacion,
        comentario: comentario,
      );
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

  Future<Map<String, dynamic>?> abrirDisputa({
    required String contratacionId,
    required String motivo,
  }) async {
    _error = null;
    try {
      final result = await _service.abrirDisputa(contratacionId, motivo);
      await getContratacion(contratacionId);
      return result;
    } on ApiException catch (e) {
      _error = formatError(e);
      notifyListeners();
      return null;
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
      return null;
    }
  }
}
