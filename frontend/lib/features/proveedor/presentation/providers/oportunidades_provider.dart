import 'package:flutter/foundation.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/proveedor/data/datasources/oportunidades_remote_datasource.dart';

class OportunidadesProvider extends ChangeNotifier {
  final OportunidadesService _service = OportunidadesService();

  List<dynamic> _items = [];
  List<dynamic> get items => _items;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<void> loadOportunidades({int? limit}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.getOportunidades(limit: limit);
      _error = null;
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
