import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads and renders the registered font families', (tester) async {
    const assets = [
      'assets/fonts/BigShouldersDisplay[wght].ttf',
      'assets/fonts/Archivo[wdth,wght].ttf',
      'assets/fonts/IBMPlexMono-Regular.ttf',
      'assets/fonts/IBMPlexMono-Medium.ttf',
      'assets/fonts/IBMPlexMono-SemiBold.ttf',
    ];
    for (final asset in assets) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            Text(
              'TrabajoYa 400',
              style: TextStyle(
                fontFamily: 'BigShouldersDisplay',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'TrabajoYa 700',
              style: TextStyle(
                fontFamily: 'BigShouldersDisplay',
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'TrabajoYa 900',
              style: TextStyle(
                fontFamily: 'BigShouldersDisplay',
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'TrabajoYa 400',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'TrabajoYa 600',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'TrabajoYa 800',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'OT-2026 400',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              'OT-2026 500',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'OT-2026 600',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(Text), findsNWidgets(9));
  });
}
