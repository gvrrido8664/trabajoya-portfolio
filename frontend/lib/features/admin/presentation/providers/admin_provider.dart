import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/admin/data/datasources/admin_remote_datasource.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();
  Map<String, dynamic>? _stats;
  List<dynamic> _usuarios = [];
  List<dynamic> _disputas = [];
  List<dynamic> _servicios = [];
  List<dynamic> _pagos = [];
  List<dynamic> _suscripciones = [];
  Map<String, dynamic>? _resultadosBusqueda;
  bool _loading = false;

  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get usuarios => _usuarios;
  List<dynamic> get disputas => _disputas;
  List<dynamic> get servicios => _servicios;
  List<dynamic> get pagos => _pagos;
  List<dynamic> get suscripciones => _suscripciones;
  Map<String, dynamic>? get resultadosBusqueda => _resultadosBusqueda;
  bool get loading => _loading;

  Future<void> cargarStats() async {
    _loading = true;
    notifyListeners();
    try {
      _stats = await _service.getStats();
    } catch (_) {
      _stats = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarUsuarios({String? rol, String? email}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getUsuarios(rol: rol, email: email);
      _usuarios = (result['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      _usuarios = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleUsuarioActivo(String id) async {
    final result = await _service.toggleUsuarioActivo(id);
    final idx = _usuarios.indexWhere((u) => u['id']?.toString() == id);
    if (idx >= 0) {
      _usuarios[idx] = {
        ..._usuarios[idx],
        'is_active':
            result['is_active'] ?? !(_usuarios[idx]['is_active'] ?? true),
      };
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> crearUsuario(Map<String, dynamic> data) async {
    final result = await _service.createUser(data);
    _usuarios.insert(0, result);
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> actualizarUsuario(
    String id,
    Map<String, dynamic> data,
  ) async {
    final result = await _service.updateUser(id, data);
    final idx = _usuarios.indexWhere((u) => u['id']?.toString() == id);
    if (idx >= 0) {
      _usuarios[idx] = result;
      notifyListeners();
    }
    return result;
  }

  Future<void> cargarServicios({String? status}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getServiciosAdmin(status: status);
      _servicios = (result['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      _servicios = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarPagos({String? status}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getPagosAdmin(status: status);
      _pagos = (result['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      _pagos = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> cargarDisputas({String? status}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getDisputas(status: status);
      _disputas = (result['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      _disputas = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> resolverDisputa(
    String disputaId,
    String resolucion,
    String accion,
  ) async {
    final result = await _service.resolverDisputa(
      disputaId,
      resolucion,
      accion,
    );
    await cargarDisputas();
    return result;
  }

  Future<void> cargarSuscripcionesAdmin() async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.getSuscripcionesAdmin();
      _suscripciones = (result['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      _suscripciones = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> cancelarSuscripcionAdmin(String id) async {
    try {
      await _service.cancelarSuscripcionAdmin(id);
      final idx = _suscripciones.indexWhere((s) => s['id']?.toString() == id);
      if (idx >= 0) {
        _suscripciones[idx] = {..._suscripciones[idx], 'status': 'cancelada'};
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> asignarPlanSuscripcion(String usuarioId, String planSlug) async {
    try {
      await _service.asignarSuscripcionAdmin(usuarioId, planSlug);
      await cargarSuscripcionesAdmin(); // Recargar para obtener la nueva suscripción
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cambiarEstadoSuscripcion(String id, String status) async {
    try {
      await _service.updateSuscripcionStatusAdmin(id, status);
      final idx = _suscripciones.indexWhere((s) => s['id']?.toString() == id);
      if (idx >= 0) {
        _suscripciones[idx] = {..._suscripciones[idx], 'status': status};
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> buscarGlobal(String query) async {
    if (query.trim().isEmpty) {
      _resultadosBusqueda = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _resultadosBusqueda = await _service.buscarGlobal(query.trim());
    } catch (_) {
      _resultadosBusqueda = null;
    }
    _loading = false;
    notifyListeners();
  }
}
