import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/contrataciones/data/models/contratacion_model.dart';
import 'package:trabajoya_app/services/contrataciones_service.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

class ContratacionesProvider extends ChangeNotifier {
  final ContratacionesService _service = ContratacionesService();
  List<Contratacion> _contrataciones = [];
  Contratacion? _selected;
  bool _loading = false;
  String? _error;

  List<Contratacion> get contrataciones => _contrataciones;
  Contratacion? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargarContrataciones() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _contrataciones = await _service.getMisContrataciones();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar contrataciones';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> getContratacion(String id) async {
    _error = null;
    try {
      _selected = await _service.getContratacion(id);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar contrataci\u00f3n';
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
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al aceptar';
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
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al rechazar';
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
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al finalizar';
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
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error al crear rese\u00f1a';
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
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Error al abrir disputa';
      notifyListeners();
      return null;
    }
  }
}
