import 'package:flutter_test/flutter_test.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

void main() {
  group('formatError', () {
    test('401 → mensaje de sesión expirada', () {
      final msg = formatError(ApiException(401, 'Unauthorized'));
      expect(msg, contains('sesión'));
    });

    test('403 → mensaje de autorización', () {
      final msg = formatError(ApiException(403, ''));
      expect(msg, contains('autorización'));
    });

    test('429 → mensaje de rate limit', () {
      final msg = formatError(ApiException(429, 'Too Many Requests'));
      expect(msg, contains('Demasiadas solicitudes'));
    });

    test('500 → mensaje de servidor', () {
      final msg = formatError(ApiException(500, 'Internal Server Error'));
      expect(msg, contains('servidor'));
    });

    test('503 → también mensaje de servidor (>= 500)', () {
      final msg = formatError(ApiException(503, 'Service Unavailable'));
      expect(msg, contains('servidor'));
    });

    test('ApiException con mensaje de conexión → mensaje amigable', () {
      final msg = formatError(
        ApiException(null, 'SocketException: Connection refused'),
      );
      expect(msg, contains('conexión'));
    });

    test(
      'ApiException con mensaje arbitrario 4xx → devuelve el mensaje original',
      () {
        const original = 'El email ya está registrado.';
        final msg = formatError(ApiException(422, original));
        expect(msg, original);
      },
    );

    test('AuthException → devuelve su propio mensaje', () {
      final msg = formatError(AuthException('Sesión inválida'));
      expect(msg, 'Sesión inválida');
    });

    test('Excepción genérica de red → mensaje de conexión', () {
      final msg = formatError(Exception('SocketException: Failed to connect'));
      expect(msg, contains('conexión'));
    });

    test('Excepción genérica desconocida → mensaje genérico seguro', () {
      final msg = formatError(Exception('algo raro ocurrió'));
      expect(msg, contains('error inesperado'));
      // No debe exponer el stack ni detalles internos
      expect(msg, isNot(contains('algo raro')));
    });
  });
}
