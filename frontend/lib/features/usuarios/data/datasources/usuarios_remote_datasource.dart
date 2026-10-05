import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/data/models/usuario_model.dart';
import 'package:trabajoya_app/features/usuarios/data/models/certificacion_model.dart';

class UsuariosService {
  final ApiClient _api = ApiClient();

  Future<Usuario> getUsuario(String id) async {
    try {
      final response = await _api.get('/usuarios/$id');
      return Usuario.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Certificacion>> getMisCertificaciones() async {
    try {
      final response = await _api.get('/usuarios/me/certificaciones');
      if (response is List) {
        return response.map((e) => Certificacion.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Certificacion>> getCertificacionesUsuario(String usuarioId) async {
    try {
      final response = await _api.get('/usuarios/$usuarioId/certificaciones');
      if (response is List) {
        return response.map((e) => Certificacion.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Certificacion> agregarCertificacion(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/usuarios/me/certificaciones', body: data);
      return Certificacion.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadCertificacionFile(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_api.baseUrl}/usuarios/me/certificaciones/upload'),
      );
      
      final token = await _api.token;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);
        return data['url'];
      } else {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      rethrow;
    }
  }
}

