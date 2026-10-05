import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // URLs resueltas en tiempo de compilación desde --dart-define=ENV. NO dependen
  // del asset .env en runtime: ese archivo está gitignoreado (.gitignore `.env*`)
  // y nunca llega al deploy de Vercel, así que en web dotenv.env queda vacío.
  // Antes eso caía a un fallback `localhost:8000` y rompía toda la app en prod.
  static const String _prodApiUrl = 'http://localhost:8000/api/v1';
  static const String _devApiUrl = 'http://localhost:8000/api/v1';

  static String get apiUrl {
    // Override opcional vía .env (útil solo en dev local con backend propio).
    final override = dotenv.env['API_URL'];
    if (override != null && override.isNotEmpty) {
      // En Android emulador 10.0.2.2 == localhost del host; en web usar localhost.
      return kIsWeb ? override.replaceAll('10.0.2.2', 'localhost') : override;
    }
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    return env == 'production' ? _prodApiUrl : _devApiUrl;
  }

  static String get fintocPublicKey {
    return dotenv.env['FINTOC_PUBLIC_KEY'] ?? '';
  }
}
