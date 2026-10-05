import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/usuarios/data/datasources/usuarios_remote_datasource.dart';
import 'package:trabajoya_app/features/usuarios/data/models/certificacion_model.dart';

class CertificacionesProvider extends ChangeNotifier {
  final UsuariosService _service = UsuariosService();
  
  List<Certificacion> _misCertificaciones = [];
  List<Certificacion> get misCertificaciones => _misCertificaciones;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadMisCertificaciones() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _misCertificaciones = await _service.getMisCertificaciones();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Certificacion?> agregarCertificacion(String titulo, String institucion, String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Upload file
      final url = await _service.uploadCertificacionFile(filePath);
      
      // 2. Add certification
      final data = {
        'titulo': titulo,
        'institucion': institucion,
        'archivo_url': url,
      };
      
      final cert = await _service.agregarCertificacion(data);
      _misCertificaciones.add(cert);
      return cert;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Certificacion>> getCertificacionesDeUsuario(String usuarioId) async {
    try {
      return await _service.getCertificacionesUsuario(usuarioId);
    } catch (e) {
      return [];
    }
  }
}
