// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web WebSocket client with exponential backoff and heartbeat.
class WsClient {
  final Uri url;
  final List<String>? protocols;

  web.WebSocket? _socket;
  final StreamController<dynamic> _controller = StreamController.broadcast();

  bool _closed = false;
  bool _connecting = false;
  int _reconnectAttempt = 0;

  // Exponential backoff: 1s → 2s → 4s → … → 60s max
  static const Duration _minDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 60);

  // Heartbeat: ping every 30s, expect pong within 10s
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _heartbeatTimeout = Duration(seconds: 10);
  Timer? _heartbeatTimer;
  Timer? _pongTimer;

  JSFunction? _onMessageListener;
  JSFunction? _onCloseListener;
  JSFunction? _onErrorListener;

  Stream<dynamic> get stream => _controller.stream;
  bool get connected =>
      _socket != null && _socket!.readyState == web.WebSocket.OPEN;
  bool get isClosed => _closed;

  WsClient(this.url, {this.protocols});

  Future<void> connect() async {
    if (_connecting || _closed) return;
    _connecting = true;
    try {
      final completer = Completer<void>();

      JSAny? jsProtocols;
      if (protocols != null) {
        jsProtocols = protocols!.map((p) => p.toJS).toList().toJS;
      }

      final socket = jsProtocols != null
          ? web.WebSocket(url.toString(), jsProtocols)
          : web.WebSocket(url.toString());

      JSFunction? onOpenListener;
      JSFunction? onErrorListener;

      onOpenListener = (web.Event _) {
        if (!completer.isCompleted) completer.complete();
        socket.removeEventListener('open', onOpenListener!);
        socket.removeEventListener('error', onErrorListener!);
      }.toJS;

      onErrorListener = (web.Event event) {
        if (!completer.isCompleted) completer.completeError(event);
        socket.removeEventListener('open', onOpenListener!);
        socket.removeEventListener('error', onErrorListener!);
      }.toJS;

      socket.addEventListener('open', onOpenListener);
      socket.addEventListener('error', onErrorListener);

      await completer.future.timeout(const Duration(seconds: 15));

      _socket = socket;
      _reconnectAttempt = 0;
      _connecting = false;
      _setupListeners();
      _startHeartbeat();
    } catch (_) {
      _socket = null;
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    _onMessageListener = (web.MessageEvent event) {
      dynamic parsed;
      try {
        final dartData = event.data.dartify();
        parsed = jsonDecode(dartData.toString());
      } catch (_) {
        parsed = event.data.dartify();
      }
      // Reset pong timer on any message (server is alive)
      _pongTimer?.cancel();
      _pongTimer = null;
      _controller.add(parsed);
    }.toJS;

    _onCloseListener = (web.CloseEvent _) {
      _stopHeartbeat();
      _cleanupSocket();
      if (!_closed) _scheduleReconnect();
    }.toJS;

    _onErrorListener = (web.Event _) {
      _stopHeartbeat();
      _cleanupSocket();
      if (!_closed) _scheduleReconnect();
    }.toJS;

    _socket!.addEventListener('message', _onMessageListener!);
    _socket!.addEventListener('close', _onCloseListener!);
    _socket!.addEventListener('error', _onErrorListener!);
  }

  // ── Heartbeat ──────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendPing());
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;
  }

  void _sendPing() {
    if (!connected) return;
    send({'type': 'ping'});
    // If no message arrives within timeout, assume connection is dead
    _pongTimer = Timer(_heartbeatTimeout, () {
      _stopHeartbeat();
      _cleanupSocket();
      if (!_closed) _scheduleReconnect();
    });
  }

  // ── Reconnect with exponential backoff ─────────────────────────────────────

  void _scheduleReconnect() {
    if (_closed) return;
    final delay = _backoffDelay(_reconnectAttempt);
    _reconnectAttempt++;
    Future.delayed(delay, () {
      if (!_closed) connect();
    });
  }

  Duration _backoffDelay(int attempt) {
    final ms = _minDelay.inMilliseconds * (1 << attempt.clamp(0, 10));
    return Duration(
      milliseconds: ms.clamp(
        _minDelay.inMilliseconds,
        _maxDelay.inMilliseconds,
      ),
    );
  }

  // ── Socket cleanup ─────────────────────────────────────────────────────────

  void _cleanupSocket() {
    if (_socket != null) {
      if (_onMessageListener != null) {
        _socket!.removeEventListener('message', _onMessageListener!);
      }
      if (_onCloseListener != null) {
        _socket!.removeEventListener('close', _onCloseListener!);
      }
      if (_onErrorListener != null) {
        _socket!.removeEventListener('error', _onErrorListener!);
      }
    }
    _onMessageListener = null;
    _onCloseListener = null;
    _onErrorListener = null;
    _socket = null;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void send(dynamic data) {
    try {
      if (connected) {
        final txt = data is String ? data : jsonEncode(data);
        _socket!.send(txt.toJS);
      }
    } catch (_) {}
  }

  Future<void> close() async {
    _closed = true;
    _stopHeartbeat();
    try {
      _socket?.close();
    } catch (_) {}
    _cleanupSocket();
    try {
      await _controller.close();
    } catch (_) {}
  }
}
