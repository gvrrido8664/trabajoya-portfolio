import 'package:trabajoya_app/core/api/constants.dart';

class Config {
  /// Base WebSocket URL for global updates.
  static String get wsUrl {
    final base = apiBaseUrl
        .replaceFirst('http', 'ws')
        .replaceFirst('/api/v1', '');
    return '$base/api/v1/ws';
  }

  /// Builds WebSocket URL for a chat room. Token goes as query param (WebSocket limitation) only if provided.
  static String wsChatUrl(String contratacionId, [String? token]) {
    final base = apiBaseUrl
        .replaceFirst('http', 'ws')
        .replaceFirst('/api/v1', '');
    if (token != null) {
      return '$base/api/v1/chat/ws/$contratacionId?token=$token';
    }
    return '$base/api/v1/chat/ws/$contratacionId';
  }
}
