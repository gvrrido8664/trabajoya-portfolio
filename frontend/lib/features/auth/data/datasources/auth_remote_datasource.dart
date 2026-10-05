import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/data/models/usuario_model.dart';
import 'package:trabajoya_app/shared/data/upload_service.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Usuario> login(
    String email,
    String password, {
    String? totpCode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
          if (totpCode != null && totpCode.isNotEmpty) 'totp_code': totpCode,
        },
      );
      // Si la cuenta tiene 2FA, el backend responde 200 con {mfa_required: true}
      // y sin token. Señalamos el mismo 'mfa_required' que el provider ya maneja
      // (sin generar un 401 en la consola del navegador).
      if (response is Map && response['mfa_required'] == true) {
        throw AuthException('mfa_required');
      }
      // Backend solo devuelve {access_token, token_type}. Traemos el usuario con /auth/me.
      final token = response['access_token'] as String? ?? '';
      await _apiClient.setToken(token);
      return await getMe();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Usuario> loginSocial(
    String provider,
    String idToken, {
    String rol = 'cliente',
  }) async {
    try {
      final response = await _apiClient.post(
        '/auth/social',
        body: {'provider': provider, 'id_token': idToken, 'rol': rol},
      );
      final token = response['access_token'] as String? ?? '';
      await _apiClient.setToken(token);
      return Usuario.fromJson(response['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion social: $e');
    }
  }

  /// Canjea el código de intercambio de 60s (emitido por el callback del
  /// backend tras el redirect a Google) por el JWT de sesión real.
  Future<Usuario> completeOAuthRedirect(String exchangeCode) async {
    try {
      final response = await _apiClient.post(
        '/auth/oauth/exchange',
        body: {'code': exchangeCode},
      );
      final token = response['access_token'] as String? ?? '';
      await _apiClient.setToken(token);
      return Usuario.fromJson(response['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  /// Genera el secreto TOTP y devuelve {otpauth_uri, secret}.
  Future<Map<String, dynamic>> totpSetup() async {
    final r = await _apiClient.post('/auth/totp/setup', body: {});
    return Map<String, dynamic>.from(r as Map);
  }

  /// Confirma el primer código y activa MFA; devuelve la lista de backup codes.
  Future<List<String>> totpEnable(String code) async {
    final r = await _apiClient.post('/auth/totp/enable', body: {'code': code});
    return List<String>.from((r as Map)['backup_codes'] ?? const []);
  }

  Future<void> totpDisable(String password) async {
    await _apiClient.post('/auth/totp/disable', body: {'password': password});
  }

  Future<Usuario> register(
    String email,
    String password,
    String nombre,
    String apellido,
    String rol, {
    String? telefono,
    String? ref,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'nombre': nombre,
        'apellido': apellido,
        'rol': rol,
      };
      if (telefono != null) body['telefono'] = telefono;

      String path = '/auth/register';
      if (ref != null && ref.isNotEmpty) {
        path += '?ref=$ref';
      }
      final response = await _apiClient.post(path, body: body);
      final token = response['access_token'] as String? ?? '';
      await _apiClient.setToken(token);
      return Usuario.fromJson(response['user'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Usuario> getMe() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return Usuario.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  /// Activa la capacidad proveedor sobre la cuenta actual (requiere
  /// verificación de identidad aprobada; el backend valida doc_estado).
  Future<Usuario> activarProveedor() async {
    try {
      final response = await _apiClient.post('/usuarios/me/activar-proveedor', body: {});
      return Usuario.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      await _apiClient.get('/auth/verify-email?token=$token');
      return true;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _apiClient.post('/auth/forgot-password', body: {'email': email});
      return true;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      await _apiClient.post(
        '/auth/reset-password',
        body: {'token': token, 'new_password': newPassword},
      );
      return true;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Usuario> updateProfile({
    String? nombre,
    String? apellido,
    String? telefono,
    String? comuna,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (apellido != null) body['apellido'] = apellido;
      if (telefono != null) body['telefono'] = telefono;
      if (comuna != null) body['comuna'] = comuna;
      final response = await _apiClient.patch('/auth/me', body: body);
      return Usuario.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _apiClient.post(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return true;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Usuario> updateFullProfile({
    String? nombre,
    String? apellido,
    String? telefono,
    String? bio,
    String? habilidades,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (apellido != null) body['apellido'] = apellido;
      if (telefono != null) body['telefono'] = telefono;
      if (bio != null) body['bio'] = bio;
      if (habilidades != null) body['habilidades'] = habilidades;
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      final response = await _apiClient.put('/usuarios/me', body: body);
      return Usuario.fromJson(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> updateUbicacion(double lat, double lng) async {
    try {
      await _apiClient.patch(
        '/usuarios/me/ubicacion',
        body: {'lat': lat, 'lng': lng},
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Map<String, dynamic>> getReferidos() async {
    try {
      final response = await _apiClient.get('/usuarios/me/referidos');
      return response is Map<String, dynamic> ? response : {};
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<Usuario> uploadAvatar(String filePath) async {
    final upload = UploadService();
    await upload.uploadAvatar(filePath);
    return await getMe();
  }

  Future<bool> resendVerification() async {
    try {
      await _apiClient.post('/auth/resend-verification');
      return true;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ApiException(null, 'Error de conexion: $e');
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<bool> get isLoggedIn async {
    final token = await _apiClient.token;
    return token != null && token.isNotEmpty;
  }
}
