import 'package:flutter/material.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/suscripciones/data/datasources/suscripciones_remote_datasource.dart';

class SuscripcionesProvider extends ChangeNotifier {
  final SuscripcionesService _service = SuscripcionesService();
  Map<String, dynamic>? _miSuscripcion;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get miSuscripcion => _miSuscripcion;
  bool get loading => _loading;
  String? get error => _error;
  List<dynamic> _planes = [];
  List<dynamic> get planes => _planes;

  Future<void> cargarPlanes() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _planes = await _service.getPlanes();
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (_) {
      _planes = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarSuscripcion() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _miSuscripcion = await _service.getMiSuscripcion();
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (_) {
      _miSuscripcion = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> suscribirse(String planSlug) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _service.crearSuscripcion(planSlug);
      _loading = false;
      notifyListeners();
      return res['init_point'] as String?;
    } on ApiException catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelar() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.cancelarSuscripcion();
      _miSuscripcion = null;
      _loading = false;
      notifyListeners();
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
