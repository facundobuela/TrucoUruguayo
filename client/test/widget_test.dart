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
}
