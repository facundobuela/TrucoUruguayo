import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/app.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_client/features/game/presentation/game_screen.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  testWidgets('TrucoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrucoApp());
    expect(find.text('Truco Uruguayo'), findsOneWidget);
  });

  testWidgets('Verificación de cero overflow en 360x640 (Android compacto)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verificación de cero overflow en 390x844 (iPhone estándar)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verificación de cero overflow en 440x956 (iPhone 16 Pro Max)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('El mazo con la muestra se puede tocar para ampliarla', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pump();

    final deck = find.byWidgetPredicate(
      (w) =>
          w is Semantics && (w.properties.label ?? '').startsWith('Muestra:'),
    );
    expect(deck, findsOneWidget);

    await tester.tap(deck);
    await tester.pumpAndSettle();
    expect(find.text('MUESTRA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El mazo cambia de lado según quién reparte', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final controller = OfflineGameController(botDelayMs: 60000);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          fontFamily: 'sans-serif',
        ),
        home: GameScreen(controller: controller),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'primera mano');

    final deck = find.byWidgetPredicate(
      (w) =>
          w is Semantics && (w.properties.label ?? '').startsWith('Muestra:'),
    );
    expect(
      tester.getRect(deck).center.dx,
      greaterThan(220),
      reason: 'cuando reparte el bot, el mazo va a la izquierda del jugador',
    );

    controller.perform(const FoldAction());
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'mano finalizada');
    controller.startNextHand();
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'siguiente mano');

    expect(
      tester.getRect(deck).center.dx,
      lessThan(220),
      reason: 'cuando reparte el jugador, el mazo va al lado opuesto',
    );
    controller.dispose();
  });

  testWidgets('Al cantar Truco aparece el globo de texto "¡Truco!"', (
    WidgetTester tester,
  ) async {
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
