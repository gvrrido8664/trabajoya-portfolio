import 'package:flutter_test/flutter_test.dart';
import 'package:trabajoya_app/core/api/api_client.dart';

void main() {
  group('guard<T>', () {
    test('devuelve el valor cuando no hay excepción', () async {
      final result = await guard(() async => 42);
      expect(result, 42);
    });

    test('relanza ApiException sin modificarla', () async {
      final original = ApiException(404, 'No encontrado');
      expect(
        () => guard(() async => throw original),
        throwsA(
          predicate(
            (e) =>
                e is ApiException &&
                e.statusCode == 404 &&
                e.message == 'No encontrado',
          ),
        ),
      );
    });

    test('relanza AuthException sin modificarla', () async {
      final original = AuthException('Token expirado');
      expect(
        () => guard(() async => throw original),
        throwsA(
          predicate((e) => e is AuthException && e.message == 'Token expirado'),
        ),
      );
    });

    test(
      'convierte excepción genérica en ApiException con statusCode null',
      () async {
        expect(
          () => guard(() async => throw Exception('timeout')),
          throwsA(predicate((e) => e is ApiException && e.statusCode == null)),
        );
      },
    );

    test('funciona con tipos genéricos distintos (String, Map)', () async {
      final s = await guard(() async => 'hola');
      expect(s, 'hola');

      final m = await guard(() async => {'key': 'val'});
      expect(m['key'], 'val');
    });
  });
}
