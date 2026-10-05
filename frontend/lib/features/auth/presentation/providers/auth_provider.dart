import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trabajoya_app/core/ws_client.dart';
import 'package:trabajoya_app/core/config.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/core/storage/storage_io.dart'
    if (dart.library.html) 'package:trabajoya_app/core/storage/storage_web.dart';

import 'package:trabajoya_app/features/auth/data/models/usuario_model.dart';
import 'package:trabajoya_app/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  Usuario? _usuario;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  // ─────────────────────────── Modo activo ───────────────────────────
  // Identidad única con capacidades: el "modo activo" (cliente|proveedor)
  // decide qué shell ve el usuario, independiente de su rol legacy fijo.
  String _activeMode = 'cliente';
  String get activeMode => _activeMode;
  bool get isProveedorMode => _activeMode == 'proveedor';

  /// Resuelve el modo activo tras cada login/refresh: respeta lo guardado en
  /// AppStorage si la cuenta todavía tiene esa capacidad; si no hay nada
  /// guardado y el rol legacy es 'proveedor', arranca ahí (no descoloca a
  /// los proveedores existentes); en cualquier otro caso, 'cliente'.
  Future<void> _resolveActiveMode() async {
    final usuario = _usuario;
    if (usuario == null) return;
    final stored = await AppStorage.read('active_mode');
    String mode;
    if (stored == 'proveedor' && usuario.esProveedor) {
      mode = 'proveedor';
    } else if (stored == null && usuario.rol == 'proveedor') {
      mode = 'proveedor';
    } else {
      mode = 'cliente';
    }
    _activeMode = mode;
    await AppStorage.write('active_mode', mode);
  }

  /// Cambia el modo activo (requiere que la cuenta tenga esa capacidad).
  Future<void> switchMode(String mode) async {
    if (_usuario == null) return;
    if (mode == 'proveedor' && !_usuario!.esProveedor) return;
    if (mode == 'cliente' && !_usuario!.esCliente) return;
    if (mode == _activeMode) return;
    _activeMode = mode;
    await AppStorage.write('active_mode', mode);
    notifyListeners();
  }

  /// Activa la capacidad proveedor (requiere verificación de identidad
  /// aprobada; el backend valida doc_estado) y cambia al modo proveedor.
  Future<bool> activarModoProveedor() async {
    try {
      _usuario = await _service.activarProveedor();
      await switchMode('proveedor');
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    }
  }

  WsClient? _globalWs;
  StreamSubscription? _globalWsSub;
  Timer? _reconnectTimer;
  int _unreadMessages = 0;
  int get unreadMessages => _unreadMessages;
  void clearUnreadMessages() {
    if (_unreadMessages == 0) return;
    _unreadMessages = 0;
    notifyListeners();
  }

  Future<void> _connectGlobalWs() async {
    _reconnectTimer?.cancel();
    if (_globalWs != null && _globalWs!.connected) return;
    _globalWsSub?.cancel();
    _globalWs?.close();

    try {
      final t = await ApiClient().token;
      if (t == null) return;
      final url = Config.wsUrl;
      _globalWs = WsClient(Uri.parse(url), protocols: ['access_token.$t']);
      await _globalWs!.connect();
      _globalWsSub = _globalWs!.stream.listen(
        (event) {
          if (event is Map &&
              event.containsKey('emisor_id') &&
              event.containsKey('contratacion_id')) {
            final emisorId = event['emisor_id']?.toString();
            final esPropio = emisorId == _usuario?.id;
            if (!esPropio) {
              _unreadMessages++;
              notifyListeners();
            }
          }
        },
        onError: (_) {
          if (_usuario != null) {
            _reconnectTimer = Timer(const Duration(seconds: 5), _connectGlobalWs);
          }
        },
        onDone: () {
          if (_usuario != null) {
            _reconnectTimer = Timer(const Duration(seconds: 5), _connectGlobalWs);
          }
        },
      );
    } catch (e) {
      if (_usuario != null) {
        _reconnectTimer = Timer(const Duration(seconds: 5), _connectGlobalWs);
      }
    }
  }

  void _disconnectGlobalWs() {
    _reconnectTimer?.cancel();
    _globalWsSub?.cancel();
    _globalWs?.close();
    _globalWs = null;
  }

  @override
  void dispose() {
    _disconnectGlobalWs();
    super.dispose();
  }

  AuthProvider() {
    // Diferido al post-frame para no bloquear el primer render. El router maneja
    // initialized=false devolviendo null (sin redirect) hasta que checkAuth resuelva.
    SchedulerBinding.instance.addPostFrameCallback((_) => checkAuth());
  }

  Usuario? get usuario => _usuario;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get error => _error;
  bool get isLoggedIn => _usuario != null;
  bool get isProveedor => _usuario?.isProveedor ?? false;
  bool get isAdmin => _usuario?.isAdmin ?? false;
  bool get isCliente => _usuario?.isCliente ?? true;

  /// True cuando el último login falló porque la cuenta requiere código MFA.
  bool _mfaRequired = false;
  bool get mfaRequired => _mfaRequired;

  Future<bool> checkAuth() async {
    if (_initialized) return _usuario != null;
    try {
      final loggedIn = await _service.isLoggedIn;
      if (loggedIn) {
        _usuario = await _service.getMe();
        await _resolveActiveMode();
        _connectGlobalWs();
      }
      _initialized = true;
      notifyListeners();
      return loggedIn;
    } catch (_) {
      _initialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, {String? totpCode}) async {
    _loading = true;
    _error = null;
    _mfaRequired = false;
    notifyListeners();
    try {
      _usuario = await _service.login(email, password, totpCode: totpCode);
      await _resolveActiveMode();
      _connectGlobalWs();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // El backend responde 401 con detalle "mfa_required" cuando falta el 2FA.
      if (e.toString().contains('mfa_required')) {
        _mfaRequired = true;
        _error = null;
      } else {
        _error = formatError(e);
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In instance (scoped to email + profile)
  static final _googleSignIn = GoogleSignIn(
    clientId:
        '107612518969-184lbrc2mttq27odffbusk91a73bhuft.apps.googleusercontent.com',
    scopes: ['openid', 'email', 'profile'],
  );

  /// Login real con Google — solo móvil (popup OAuth imperativo nativo). En
  /// web el login pasa por el flujo de redirect completo (ver
  /// GoogleCallbackScreen / completeGoogleRedirect), no por este método.
  Future<bool> loginWithGoogle({String rol = 'cliente'}) async {
    if (kIsWeb) {
      _error = 'Usa el botón "Continuar con Google" para iniciar sesión.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Forzar selección de cuenta siempre (evita reutilizar sesión anterior)
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // El usuario cerró el popup sin seleccionar cuenta
        _loading = false;
        notifyListeners();
        return false;
      }
      return await _exchangeGoogleAccount(account, rol);
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Completa el login iniciado por el flujo de redirect en web: canjea el
  /// código de intercambio de 60s (recibido en la URL de
  /// /auth/google/callback) por la sesión real. Ver GoogleCallbackScreen.
  Future<bool> completeGoogleRedirect(String exchangeCode) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _service.completeOAuthRedirect(exchangeCode);
      await _resolveActiveMode();
      _initialized = true;
      _loading = false;
      _connectGlobalWs();
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Intercambia una cuenta de Google ya autenticada por un JWT propio
  /// (flujo imperativo — solo móvil).
  Future<bool> _exchangeGoogleAccount(
    GoogleSignInAccount account,
    String rol,
  ) async {
    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _error = 'No se pudo obtener el token de Google. Intenta nuevamente.';
        _loading = false;
        notifyListeners();
        return false;
      }
      _usuario = await _service.loginSocial('google', idToken, rol: rol);
      await _resolveActiveMode();
      _initialized = true;
      _loading = false;
      _connectGlobalWs();
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Solo en debug: login de demo sin credenciales reales.
  Future<bool> loginSocialMock(String provider, {String? rol}) async {
    if (!kDebugMode) {
      _error =
          'El inicio de sesión de prueba no está disponible en producción.';
      notifyListeners();
      return false;
    }
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      await ApiClient().setToken('social_mock_token_12345');
      _usuario = Usuario(
        id: 'user_social_mock_id',
        email: '${provider.toLowerCase()}_user@trabajoya.cl',
        nombre: 'Usuario',
        apellido: provider,
        rol: rol ?? 'cliente',
        telefono: '+56900000000',
        totpEnabled: false,
        isActive: true,
        isVerified: true,
        avgRating: 5.0,
        referidosCount: 0,
        createdAt: DateTime.now(),
      );
      _initialized = true;
      _loading = false;
      _connectGlobalWs();
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Activa MFA TOTP: setup → muestra QR; el caller confirma con [enableTotp].
  Future<Map<String, dynamic>> setupTotp() => _service.totpSetup();

  Future<List<String>> enableTotp(String code) async {
    final codes = await _service.totpEnable(code);
    await refreshUser();
    return codes;
  }

  Future<bool> disableTotp(String password) async {
    try {
      await _service.totpDisable(password);
      await refreshUser();
      return true;
    } catch (e) {
      _error = formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String rol,
    String? telefono,
    String? ref,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _service.register(
        email,
        password,
        nombre,
        apellido,
        rol,
        telefono: telefono,
        ref: ref,
      );
      await _resolveActiveMode();
      _connectGlobalWs();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _disconnectGlobalWs();
    await _service.logout();
    _usuario = null;
    _activeMode = 'cliente';
    // No se borra 'active_mode': _resolveActiveMode() ya está pensado para
    // persistirlo entre logins ("respeta lo guardado... tras cada login"),
    // y ya valida que la cuenta que inicie sesión después tenga la
    // capacidad correspondiente antes de aplicarlo. Borrarlo acá hacía que
    // el modo activo siempre volviera a "cliente" tras cerrar sesión.
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.forgotPassword(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.verifyEmail(token);
      // Refresca el usuario en memoria para que banner/perfil reflejen el cambio al instante.
      await refreshUser();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.resetPassword(token, newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.changePassword(currentPassword, newPassword);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.resendVerification();
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _service.uploadAvatar(filePath);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      _usuario = await _service.getMe();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.refreshUser failed: $e');
    }
  }

  void setUsuario(Usuario usuario) {
    _usuario = usuario;
    _connectGlobalWs();
    notifyListeners();
  }

  Future<void> updateUbicacion(double lat, double lng) async {
    try {
      await _service.updateUbicacion(lat, lng);
    } catch (e) {
      debugPrint('AuthProvider.updateUbicacion failed: $e');
    }
  }

  Future<bool> actualizarPerfil({
    String? nombre,
    String? apellido,
    String? telefono,
    String? comuna,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedUser = await _service.updateProfile(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        comuna: comuna,
      );

      // Si el backend aún no retorna comuna o retorna un string vacío, forzamos su asignación localmente.
      if (comuna != null && comuna.isNotEmpty && (updatedUser.comuna == null || updatedUser.comuna!.isEmpty)) {
        _usuario = updatedUser.copyWith(comuna: comuna);
      } else {
        _usuario = updatedUser;
      }
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarPerfilCompleto({
    String? nombre,
    String? apellido,
    String? telefono,
    String? bio,
    String? habilidades,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _usuario = await _service.updateFullProfile(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        bio: bio,
        habilidades: habilidades,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
