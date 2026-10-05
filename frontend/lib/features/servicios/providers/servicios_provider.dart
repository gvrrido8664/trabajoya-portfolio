import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/services/servicios_service.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

class ServiciosProvider extends ChangeNotifier {
  final ServiciosService _service = ServiciosService();
  final ApiClient _apiClient = ApiClient();
  List<Servicio> _servicios = [];
  List<Categoria> _categorias = [];
  bool _loading = false;
  String? _error;

  List<Servicio> get servicios => _servicios;
  List<Categoria> get categorias => _categorias;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> cargarServicios({String? categoriaId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _servicios = await _service.getServicios(categoriaId: categoriaId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al cargar servicios';
    }
    _loading = false;
    notifyListeners();
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
    double radioKm = 10,
    String? categoriaId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _servicios = await _service.buscarServicios(
        lat,
        lng,
        radioKm: radioKm,
        categoriaId: categoriaId,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al buscar servicios cercanos';
    }
    _loading = false;
    notifyListeners();
  }
}
