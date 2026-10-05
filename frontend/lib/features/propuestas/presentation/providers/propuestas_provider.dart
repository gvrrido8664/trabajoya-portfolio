import 'package:flutter/foundation.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/propuestas/data/datasources/propuestas_remote_datasource.dart';
import 'package:trabajoya_app/features/propuestas/data/models/propuesta_model.dart';

class PropuestasProvider extends ChangeNotifier {
  final PropuestasService _service = PropuestasService();

  List<Propuesta> _propuestas = [];
  bool _loading = false;
  String? _error;

  List<Propuesta> get propuestas => _propuestas;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargarMisPropuestas() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _propuestas = await _service.getMisPropuestas();
    } on ApiException catch (e) {
      _error = formatError(e);
    } catch (e) {
      _error = formatError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
