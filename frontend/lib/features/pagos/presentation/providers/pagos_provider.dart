import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/pagos/data/datasources/pagos_remote_datasource.dart';

class PagosProvider extends ChangeNotifier {
  final PagosService _service = PagosService();
  bool _loading = false;
  bool get loading => _loading;

  // ─── MercadoPago ──────────────────────────────────────

  Future<Map<String, dynamic>> crearPagoMP(String contratacionId) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.crearPagoMP(contratacionId);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acordarEnPersona(String contratacionId) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.acordarEnPersona(contratacionId);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─── Estado común ─────────────────────────────────────

  Future<Map<String, dynamic>> getEstadoPago(String contratacionId) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getEstadoPago(contratacionId);
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
