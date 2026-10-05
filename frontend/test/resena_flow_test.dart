import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trabajoya_app/features/resenas/presentation/pages/resena_screen.dart';
import 'package:trabajoya_app/features/contrataciones/data/datasources/contrataciones_remote_datasource.dart';
import 'package:trabajoya_app/features/resenas/data/models/resena_model.dart';

class FakeContratacionesService extends ContratacionesService {
  bool called = false;
  @override
  Future<Resena> crearResena(
    String contratacionId,
    int puntuacion, {
    String? comentario,
  }) async {
    called = true;
    return Resena(
      id: 'r1',
      contratacionId: contratacionId,
      calificadorId: 'u1',
      calificadoId: 'u2',
      puntuacion: puntuacion,
      comentario: comentario,
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('ResenaScreen posts and pops on success', (
    WidgetTester tester,
  ) async {
    final fake = FakeContratacionesService();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ResenaScreen(contratacionId: 'c1', service: fake),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    // Open ResenaScreen
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Dejar Resena'), findsOneWidget);

    // Tap submit
    await tester.tap(find.text('Enviar Resena'));
    await tester.pump();

    // Wait for async work
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Should have called the fake service and popped back
    expect(fake.called, isTrue);
    expect(find.text('Dejar Resena'), findsNothing);
  });
}
