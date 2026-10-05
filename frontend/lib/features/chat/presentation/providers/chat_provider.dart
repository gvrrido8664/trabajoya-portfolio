import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/chat/data/models/mensaje_model.dart';
import 'package:trabajoya_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'dart:async';
import 'package:trabajoya_app/core/ws_client.dart';
import 'dart:convert';
import 'package:trabajoya_app/core/config.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  List<dynamic> _conversaciones = [];
  List<Mensaje> _mensajes = [];
  bool _loading = false;

  // WebSocket client
  WsClient? _wsClient;
  StreamSubscription? _wsSub;

  /// Sala (contratación) actualmente conectada por WebSocket.
  String? _activeContratacionId;

  /// ID del usuario actual, seteado externamente para evitar timing issues con AuthProvider.
  String currentUserId = '';

  List<dynamic> get conversaciones => _conversaciones;
  List<Mensaje> get mensajes => _mensajes;
  bool get loading => _loading;
  bool get wsConnected => _wsClient?.connected ?? false;

  /// Connects to a specific chat room WebSocket. Idempotente: si ya está
  /// conectado a la misma sala, no reconecta.
  Future<void> connectToChat(String contratacionId, String token) async {
    if (_activeContratacionId == contratacionId && wsConnected) return;

    _wsSub?.cancel();
    _wsClient?.close();

    try {
      final url = Config.wsChatUrl(contratacionId);
      _activeContratacionId = contratacionId;
      _wsClient = WsClient(Uri.parse(url), protocols: ['access_token.$token']);
      await _wsClient!.connect();
      _wsSub = _wsClient!.stream.listen(
        _handleWsEvent,
        onError: (err) {
          // Handle stream error
        },
        onDone: () {
          // Handle done
        },
      );
      notifyListeners();
    } catch (e) {
      // Handle connection failure
      notifyListeners();
    }
  }

  /// Disconnects from any active WebSocket.
  void disconnectFromChat() {
    _wsSub?.cancel();
    _wsClient?.close();
    _wsClient = null;
    _activeContratacionId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsClient?.close();
    super.dispose();
  }

  int get totalUnread {
    try {
      return _conversaciones.fold<int>(
        0,
        (sum, c) =>
            sum +
            ((c is Map && c['unread_count'] is int)
                ? c['unread_count'] as int
                : 0),
      );
    } catch (_) {
      return 0;
    }
  }

  Future<void> cargarConversaciones({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _conversaciones = await _service.getConversaciones();
    } catch (_) {
      _conversaciones = [];
    }
    if (!silent) {
      _loading = false;
    }
    notifyListeners();
  }

  // Mensajes paginados
  int _mensajesPage = 0;
  final int _mensajesPageSize = 20;
  bool _hasMoreMensajes = true;
  bool _loadingMensajes = false;

  Future<void> cargarMensajes(
    String contratacionId, {
    bool reset = false,
  }) async {
    if (reset) {
      _mensajesPage = 0;
      _hasMoreMensajes = true;
      _mensajes = [];
    }

    _loading = true;
    _loadingMensajes = true;
    notifyListeners();
    try {
      final skip = _mensajesPage * _mensajesPageSize;
      final res = await _service.getMensajes(
        contratacionId,
        skip: skip,
        limit: _mensajesPageSize,
      );

      if (reset) {
        _mensajes = res;
      } else {
        _mensajes.addAll(res);
      }

      if (res.length < _mensajesPageSize) {
        _hasMoreMensajes = false;
      } else {
        _mensajesPage += 1;
      }
    } catch (_) {
      if (reset) _mensajes = [];
    } finally {
      _loading = false;
      _loadingMensajes = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasMensajes(String contratacionId) async {
    if (_loadingMensajes || !_hasMoreMensajes) return;
    await cargarMensajes(contratacionId, reset: false);
  }

  /// Poll rápido: trae solo el último mensaje y si hay uno nuevo lo inserta directo
  /// (sin limpiar la lista ni hacer refetch completo).
  Future<void> pollMensajes(String contratacionId) async {
    if (_loadingMensajes) return;
    try {
      final res = await _service.getMensajes(contratacionId, skip: 0, limit: 1);
      if (res.isEmpty) return;
      final nuevo = res.first;
      if (_mensajes.isEmpty || _mensajes.first.id != nuevo.id) {
        // Insertar directo si es más nuevo (caso normal)
        if (_mensajes.isNotEmpty &&
            nuevo.createdAt.isAfter(_mensajes.first.createdAt)) {
          addMensaje(nuevo);
        } else {
          // Gap en la historia (reconexión, etc) — refetch completo
          await cargarMensajes(contratacionId, reset: true);
        }
      }
    } catch (e) {
      debugPrint('ChatProvider.pollMensajes failed: $e');
    }
  }

  void addMensaje(Mensaje mensaje) {
    if (mensaje.id.isNotEmpty && _mensajes.any((m) => m.id == mensaje.id)) {
      return;
    }
    // Near-duplicate: WS echo arrives after local optimistic insert.
    // Match only local-prefixed IDs (not real echoes from other users).
    final dupIdx = _mensajes.indexWhere(
      (m) =>
          m.id.startsWith('local_') &&
          m.emisorId == mensaje.emisorId &&
          m.contenido == mensaje.contenido &&
          m.contratacionId == mensaje.contratacionId,
    );
    if (dupIdx >= 0) {
      _mensajes[dupIdx] = mensaje;
      notifyListeners();
      return;
    }
    _mensajes.insert(0, mensaje);
    notifyListeners();
  }

  /// Quita un mensaje por id. Se usa para revertir un mensaje optimista
  /// (local_xxx) cuando el envío falla, para que no quede aparentando enviado.
  void removeMensaje(String id) {
    final before = _mensajes.length;
    _mensajes.removeWhere((m) => m.id == id);
    if (_mensajes.length != before) notifyListeners();
  }

  void _handleWsEvent(dynamic event) {
    try {
      final e = event is String ? jsonDecode(event) : event;
      if (e is! Map) return;

      if (e['contenido'] != null &&
          (e['id'] != null || e['created_at'] != null)) {
        _addMensajeDesdeMap(Map<String, dynamic>.from(e));
        cargarConversaciones(silent: true);
        // Mark as read when a message arrives (user is watching this chat)
        if (_activeContratacionId != null) {
          marcarLeidos(_activeContratacionId!);
        }
        return;
      }

      switch (e['type']) {
        case 'mensaje':
          if (e['data'] is Map) {
            _addMensajeDesdeMap(Map<String, dynamic>.from(e['data']));
            cargarConversaciones(silent: true);
          }
          break;
        case 'mensajes:leido':
          // El servidor solo manda este evento al emisor original, avisando
          // que EL OTRO leyó sus mensajes: acá solo se confirman como leídos
          // los mensajes que YO envié (emisorId == currentUserId), nunca los
          // del otro usuario (eso lo maneja marcarLeidos, no este evento).
          final leidoContratacionId = e['contratacion_id']?.toString();
          if (leidoContratacionId != null) {
            _mensajes = _mensajes.map((m) {
              if (m.contratacionId == leidoContratacionId &&
                  !m.leido &&
                  m.emisorId.trim().toLowerCase() ==
                      currentUserId.trim().toLowerCase()) {
                return Mensaje(
                  id: m.id,
                  contratacionId: m.contratacionId,
                  emisorId: m.emisorId,
                  contenido: m.contenido,
                  leido: true,
                  createdAt: m.createdAt,
                );
              }
              return m;
            }).toList();
            notifyListeners();
          }
          break;
        case 'conversaciones:update':
          cargarConversaciones(silent: true);
          break;
        case 'estado:update':
          cargarConversaciones(silent: true);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('ChatProvider._handleWsEvent failed to process message: $e');
    }
  }

  void _addMensajeDesdeMap(Map<String, dynamic> map) {
    try {
      final m = Mensaje.fromJson(map);
      if (_activeContratacionId != null &&
          m.contratacionId.isNotEmpty &&
          m.contratacionId != _activeContratacionId) {
        return;
      }
      addMensaje(m);
    } catch (e) {
      debugPrint(
        'ChatProvider._addMensajeDesdeMap failed to parse message JSON: $e',
      );
    }
  }

  Future<void> marcarLeidos(String contratacionId) async {
    try {
      final api = ApiClient();
      await api.put('/chat/$contratacionId/leer');
      // Actualizar localmente para que las flechas cambien sin esperar refetch.
      // El backend solo marca leídos los mensajes del OTRO emisor (ver
      // routes_chat.py); replicar el mismo filtro acá evita marcar como
      // "leído" un mensaje propio recién enviado (llega por el eco del WS).
      _mensajes = _mensajes.map((m) {
        if (m.contratacionId == contratacionId &&
            !m.leido &&
            m.emisorId.trim().toLowerCase() !=
                currentUserId.trim().toLowerCase()) {
          return Mensaje(
            id: m.id,
            contratacionId: m.contratacionId,
            emisorId: m.emisorId,
            contenido: m.contenido,
            leido: true,
            createdAt: m.createdAt,
          );
        }
        return m;
      }).toList();
      await cargarConversaciones(silent: true);
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider.marcarLeidos failed: $e');
    }
  }

  Future<bool> sendMessage(String contratacionId, String contenido) async {
    try {
      if (wsConnected && _wsClient != null) {
        _wsClient!.send({
          'action': 'send_mensaje',
          'contratacion_id': contratacionId,
          'contenido': contenido,
        });
        return true;
      }
      // Sin WS: persistir por REST. NO llamar cargarMensajes porque
      // hace _mensajes = [] y se traga el mensaje optimista local_xxx.
      final api = ApiClient();
      await api.post(
        '/chat/$contratacionId/mensajes',
        body: {'contenido': contenido},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
