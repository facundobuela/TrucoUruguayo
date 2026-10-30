import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/main.dart';

void main() {
  testWidgets('TrucoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrucoApp());
    expect(find.text('Truco Uruguayo'), findsOneWidget);
  });

  testWidgets('Verificación de cero overflow en 360x640 (Android compacto)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verificación de cero overflow en 390x844 (iPhone estándar)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verificación de cero overflow en 440x956 (iPhone 16 Pro Max)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('El mazo con la muestra se puede tocar para ampliarla', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pump();

    final deck = find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label ?? '').startsWith('Muestra:'),
    );
    expect(deck, findsOneWidget);

    await tester.tap(deck);
    await tester.pumpAndSettle();
    expect(find.text('MUESTRA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Al cantar Truco aparece el globo de texto "¡Truco!"', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pump();

    await tester.tap(find.text('Truco'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('¡Truco!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Desmontar la pantalla cancela los temporizadores pendientes (bot y globos).
    await tester.pumpWidget(const SizedBox());
  });
}