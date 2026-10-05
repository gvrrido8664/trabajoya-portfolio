import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Native (mobile/desktop) implementation of WsClient.
class WsClient {
  final Uri url;
  WebSocket? _socket;
  final StreamController<dynamic> _controller = StreamController.broadcast();
  bool _connecting = false;
  bool _closed = false;
  static const int _maxRetries = 3;
  static const Duration _connectTimeout = Duration(seconds: 15);

  Stream<dynamic> get stream => _controller.stream;
  bool get connected => _socket != null;
  bool get isClosed => _closed;

  final Iterable<String>? protocols;

  WsClient(this.url, {this.protocols});

  Future<void> connect() async {
    if (_connecting || _closed) return;
    _connecting = true;
    int attempt = 0;
    while (!_closed && attempt < _maxRetries) {
      try {
        _socket = await WebSocket.connect(
          url.toString(),
          protocols: protocols,
        ).timeout(_connectTimeout);
        _socket!.pingInterval = const Duration(seconds: 20);
        _socket!.listen(
          (data) {
            dynamic parsed;
            try {
              parsed = jsonDecode(data.toString());
            } catch (_) {
              parsed = data;
            }
            _controller.add(parsed);
          },
          onDone: () {
            _socket = null;
            if (!_closed) _scheduleReconnect(++attempt);
          },
          onError: (err) {
            _socket = null;
            if (!_closed) _scheduleReconnect(++attempt);
          },
          cancelOnError: true,
        );

        attempt = 0;
        _connecting = false;
        return;
      } catch (e) {
        _socket = null;
        attempt++;
        if (attempt >= _maxRetries) break;
        await Future.delayed(
          Duration(milliseconds: (500 * attempt).clamp(500, 5000)),
        );
      }
    }
    _connecting = false;
    throw Exception('WebSocket connection failed after $_maxRetries attempts');
  }

  void _scheduleReconnect(int attempt) {
    if (_closed) return;
    if (attempt >= _maxRetries) return;
    final delayMs = (500 * attempt).clamp(500, 5000);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_closed) return;
      connect();
    });
  }

  void send(dynamic data) {
    try {
      final txt = data is String ? data : jsonEncode(data);
      _socket?.add(txt);
    } catch (_) {}
  }

  Future<void> close() async {
    _closed = true;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    try {
      await _controller.close();
    } catch (_) {}
  }
}
