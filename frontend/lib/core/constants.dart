import 'package:flutter/foundation.dart';

const mockMode = false;

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:8000/api/v1';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}
