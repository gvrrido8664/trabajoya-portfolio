import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../storage/storage_io.dart'
    if (dart.library.html) '../storage/storage_web.dart';
import 'constants.dart';
import 'mock_data.dart';

final apiClient = ApiClient();

String formatError(Object e) {
  if (e is ApiException) {
    if (e.statusCode == 401) {
      return 'Sesión expirada o inválida. Por favor, inicia sesión nuevamente.';
    }
    if (e.statusCode == 403) {
      // El backend suele mandar un detail específico y útil ("Debes
      // verificar tu email...", "No tienes acceso a este chat") -- se
      // descartaba siempre a favor de un mensaje genérico. Solo cae al
      // genérico si de verdad no hay nada mejor (detail no parseable).
      return e.message.isNotEmpty && e.message != 'Error del servidor'
          ? e.message
          : 'No tienes autorización para realizar esta acción.';
    }
    if (e.statusCode == 429) {
      return 'Demasiadas solicitudes. Por favor, espera un momento y vuelve a intentarlo.';
    }
    if (e.statusCode != null && e.statusCode! >= 500) {
      return 'Error del servidor. Por favor, intenta de nuevo más tarde.';
    }
    final msg = e.message.toLowerCase();
    if (msg.contains('conexion') ||
        msg.contains('connection') ||
        msg.contains('failed to fetch') ||
        msg.contains('socketexception') ||
        msg.contains('clientexception')) {
      return 'Error de conexión. Revisa tu conexión a internet e intenta de nuevo.';
    }
    return e.message;
  }
  if (e is AuthException) {
    return e.message;
  }
  final str = e.toString().toLowerCase();
  if (str.contains('socketexception') ||
      str.contains('network') ||
      str.contains('conexion') ||
      str.contains('connection') ||
      str.contains('failed to fetch') ||
      str.contains('clientexception')) {
    return 'Error de conexión. Revisa tu conexión a internet e intenta de nuevo.';
  }
  return 'Ocurrió un error inesperado. Por favor, vuelve a intentarlo.';
}

/// Envuelve cualquier llamada a la API absorbiendo excepciones genéricas.
/// Relanza [ApiException] y [AuthException] tal cual; convierte cualquier
/// otro error en [ApiException] con statusCode null.
///
/// Uso en datasources:
///   Future<Contratacion> crear(...) => guard(() async {
///     final r = await _apiClient.post('/contrataciones', body: body);
///     return Contratacion.fromJson(r);
///   });
Future<T> guard<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on ApiException {
    rethrow;
  } on AuthException {
    rethrow;
  } catch (e) {
    throw ApiException(null, 'Error de conexion: $e');
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Called when a 401 response is received and the token is cleared.
  static void Function()? onUnauthorized;

  String get baseUrl => apiBaseUrl;

  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client = http.Client();

  String? _token;

  Future<String> _read(String key) async {
    final v = await AppStorage.read(key);
    return v ?? '';
  }

  Future<void> _write(String key, String value) async {
    await AppStorage.write(key, value);
  }

  Future<void> _delete(String key) async {
    await AppStorage.delete(key);
  }

  Future<void> init() async {
    _token = await _read('auth_token');
    if (_token!.isEmpty) _token = null;
  }

  Future<String?> get token async {
    _token ??= await _read('auth_token');
    if (_token!.isEmpty) _token = null;
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _write('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _delete('auth_token');
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Map<String, String> _authHeaders([String? overrideToken]) {
    final token = overrideToken ?? _token;
    if (token != null) {
      return {..._headers, 'Authorization': 'Bearer $token'};
    }
    return _headers;
  }

  Map<String, String> _multipartHeaders([String? overrideToken]) {
    final token = overrideToken ?? _token;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 429) {
      throw ApiException(
        429,
        'Demasiadas solicitudes. Intenta de nuevo en un momento.',
      );
    }
    if (response.statusCode == 401) {
      String msg = 'Sesion expirada. Inicia sesion nuevamente.';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          final detail = body['detail'];
          msg = detail is String ? detail : msg;
        }
      } catch (_) {}
      if (msg == 'mfa_required') {
        throw ApiException(401, 'mfa_required');
      }
      // Solo tratar el 401 como "sesión expirada" (logout global + redirect) si
      // había una sesión autenticada. Un login fallido no tiene token: si aquí
      // disparáramos onUnauthorized, el redirect a /login destruye el Scaffold y
      // se traga el SnackBar de error, dejando al usuario sin feedback.
      if (_token != null) {
        await clearToken();
        onUnauthorized?.call();
      }
      throw AuthException(msg);
    }
    if (response.statusCode >= 400) {
      String message = 'Error del servidor';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          final detail = body['detail'];
          message = detail is String ? detail : detail.toString();
        }
      } catch (_) {
        message = response.body.isNotEmpty
            ? response.body
            : 'Error ${response.statusCode}';
      }
      throw ApiException(response.statusCode, message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> _request(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(_timeout);
      return await _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        408,
        'Tiempo de espera agotado. Verifica tu conexion.',
      );
    }
  }

  Future<dynamic> _requestMultipart(
    Future<http.StreamedResponse> Function() fn,
  ) async {
    try {
      final streamedResponse = await fn().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return await _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        408,
        'Tiempo de espera agotado. Verifica tu conexion.',
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 220));
      return MockApi.handle('GET', path, null, queryParams);
    }
    final uri = Uri.parse(
      '$apiBaseUrl$path',
    ).replace(queryParameters: queryParams);
    return _request(
      () => _client.get(uri, headers: _authHeaders(overrideToken)),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 260));
      return MockApi.handle('POST', path, body, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _request(
      () => _client.post(
        uri,
        headers: _authHeaders(overrideToken),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 240));
      return MockApi.handle('PUT', path, body, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _request(
      () => _client.put(
        uri,
        headers: _authHeaders(overrideToken),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 230));
      return MockApi.handle('PATCH', path, body, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _request(
      () => _client.patch(
        uri,
        headers: _authHeaders(overrideToken),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> delete(String path, {String? overrideToken}) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 210));
      return MockApi.handle('DELETE', path, null, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _request(
      () => _client.delete(uri, headers: _authHeaders(overrideToken)),
    );
  }

  Future<dynamic> uploadMultipart(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String>? fields,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockApi.handle('POST', path, null, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _requestMultipart(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(overrideToken));
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      return request.send();
    });
  }

  Future<dynamic> uploadMultipartFromBytes(
    String path, {
    required List<int> bytes,
    required String filename,
    String fileField = 'file',
    String? contentType,
    Map<String, String>? fields,
    String? overrideToken,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return MockApi.handle('POST', path, null, null);
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    return _requestMultipart(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(overrideToken));
      if (fields != null) {
        request.fields.addAll(fields);
      }
      final mediaType = contentType != null
          ? MediaType.parse(contentType)
          : MediaType('image', 'jpeg');
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );
      return request.send();
    });
  }

  Future<dynamic> uploadAvatar({
    required List<int> fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'url': 'https://mock.url/avatar.png'};
    }
    final uri = Uri.parse('$apiBaseUrl/upload/avatar');
    return _requestMultipart(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(null));
      
      final mediaType = MediaType.parse(fileType);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
      return request.send();
    });
  }

  /// Sube selfie + documento de identidad a /upload/documento (dos archivos).
  Future<dynamic> uploadDocumentos({
    required List<int> selfieBytes,
    required String selfieName,
    required String selfieType,
    required List<int> docBytes,
    required String docName,
    required String docType,
  }) async {
    if (kDebugMode && (mockMode || _token == 'social_mock_token_12345')) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {'estado': 'pending'};
    }
    final uri = Uri.parse('$apiBaseUrl/upload/documento');
    return _requestMultipart(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_multipartHeaders(null));
      request.files.add(
        http.MultipartFile.fromBytes(
          'selfie',
          selfieBytes,
          filename: selfieName,
          contentType: MediaType.parse(selfieType),
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'documento',
          docBytes,
          filename: docName,
          contentType: MediaType.parse(docType),
        ),
      );
      return request.send();
    });
  }

  void dispose() {
    _client.close();
  }
}
