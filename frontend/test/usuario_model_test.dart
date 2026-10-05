import 'package:flutter_test/flutter_test.dart';
import 'package:trabajoya_app/features/auth/data/models/usuario_model.dart';

void main() {
  group('Usuario.fromJson', () {
    final baseJson = {
      'id': 'u1',
      'email': 'test@test.com',
      'nombre': 'Ana',
      'apellido': 'López',
      'rol': 'cliente',
      'is_active': true,
      'is_verified': true,
      'avg_rating': 4.5,
      'referidos_count': 2,
      'created_at': '2024-01-15T10:00:00.000Z',
    };

    test('parsea campos snake_case correctamente', () {
      final u = Usuario.fromJson(baseJson);
      expect(u.id, 'u1');
      expect(u.email, 'test@test.com');
      expect(u.nombre, 'Ana');
      expect(u.apellido, 'López');
      expect(u.rol, 'cliente');
      expect(u.isActive, true);
      expect(u.isVerified, true);
      expect(u.avgRating, 4.5);
      expect(u.referidosCount, 2);
    });

    test('parsea avg_rating desde int sin perder precisión', () {
      final u = Usuario.fromJson({...baseJson, 'avg_rating': 5});
      expect(u.avgRating, 5.0);
      expect(u.avgRating, isA<double>());
    });

    test('campos opcionales nulos no fallan', () {
      final u = Usuario.fromJson(baseJson);
      expect(u.telefono, isNull);
      expect(u.avatarUrl, isNull);
      expect(u.bio, isNull);
    });

    test('defaults seguros cuando faltan campos booleanos', () {
      final minimal = {
        'id': 'u2',
        'email': 'x@x.com',
        'nombre': 'X',
        'apellido': 'Y',
        'rol': 'proveedor',
      };
      final u = Usuario.fromJson(minimal);
      expect(u.isActive, true);
      expect(u.isVerified, false);
      expect(u.totpEnabled, false);
      expect(u.avgRating, 0.0);
      expect(u.referidosCount, 0);
    });

    test('acepta claves camelCase como fallback', () {
      final json = {
        'id': 'u3',
        'email': 'c@c.com',
        'nombre': 'B',
        'apellido': 'C',
        'rol': 'admin',
        'isActive': true,
        'isVerified': true,
        'avgRating': 3.7,
        'referidosCount': 0,
      };
      final u = Usuario.fromJson(json);
      expect(u.isActive, true);
      expect(u.avgRating, 3.7);
    });

    test('getters de rol son mutuamente excluyentes', () {
      final cliente = Usuario.fromJson({...baseJson, 'rol': 'cliente'});
      expect(cliente.isCliente, true);
      expect(cliente.isProveedor, false);
      expect(cliente.isAdmin, false);

      final proveedor = Usuario.fromJson({...baseJson, 'rol': 'proveedor'});
      expect(proveedor.isProveedor, true);
      expect(proveedor.isCliente, false);

      final admin = Usuario.fromJson({...baseJson, 'rol': 'admin'});
      expect(admin.isAdmin, true);
    });

    test('nombreCompleto concatena nombre y apellido', () {
      final u = Usuario.fromJson(baseJson);
      expect(u.nombreCompleto, 'Ana López');
    });

    test('createdAt se parsea desde ISO8601', () {
      final u = Usuario.fromJson(baseJson);
      expect(u.createdAt.year, 2024);
      expect(u.createdAt.month, 1);
      expect(u.createdAt.day, 15);
    });
  });
}
