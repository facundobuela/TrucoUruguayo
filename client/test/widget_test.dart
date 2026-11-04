import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/app.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_client/features/game/presentation/game_screen.dart';
import 'package:truco_client/features/game/presentation/widgets/thrown_card.dart';
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

  testWidgets('no aparece el cartel "Tirá una carta para comenzar"', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const TrucoApp());
    await tester.pump();
    expect(find.text('Tirá una carta para comenzar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360x640 sin overflow con 12 repartos distintos', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (var seed = 1; seed <= 12; seed++) {
      final controller = OfflineGameController(
        botDelayMs: 60000,
        matchFactory: () => TrucoMatch(
          seedSupplier: () => Uint8List.fromList(List.filled(32, seed)),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(controller: controller)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'reparto $seed');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('la ronda resuelta se ve un momento y luego se recoge al mazo', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = OfflineGameController(
      botDelayMs: 1,
      roundShowMs: 300,
      roundCollectMs: 200,
    );
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller)),
    );
    await tester.pump();

    int resultLabels() =>
        find.text('Ganaste').evaluate().length +
        find.text('Bot').evaluate().length +
        find.text('Parda').evaluate().length;

    // Se juega hasta que se resuelva la primera ronda.
    for (
      var i = 0;
      i < 600 && controller.roundPhase == RoundCollectPhase.none;
      i++
    ) {
      if (controller.isPlayerTurn) {
        final legal = controller.view!.legalActions;
        controller.perform(
          legal.contains(const RespondAction(BetResponse.quiero))
              ? const RespondAction(BetResponse.quiero)
              : legal.firstWhere(
                  (a) => a is PlayCardAction,
                  orElse: () => legal.first,
                ),
        );
      }
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(controller.roundPhase, RoundCollectPhase.showing);
    await tester.pump();
    expect(resultLabels(), 1, reason: 'se ve el resultado de la ronda');
    expect(tester.takeException(), isNull);

    // Cuando termina la recogida la mesa queda despejada.
    for (
      var i = 0;
      i < 100 && controller.roundPhase != RoundCollectPhase.none;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull, reason: 'durante la animación');
    }
    await tester.pump();
    expect(controller.roundPhase, RoundCollectPhase.none);
    expect(resultLabels(), 0, reason: 'las cartas ya no están sobre la mesa');

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('ThrownCard viaja desde su origen hasta su lugar y se queda ahí', (
    WidgetTester tester,
  ) async {
    const key = Key('carta');
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: ThrownCard(
            from: Offset(0, 200),
            child: SizedBox(key: key, width: 40, height: 60),
          ),
        ),
      ),
    );
    final startY = tester.getCenter(find.byKey(key)).dy;

    await tester.pump(const Duration(milliseconds: 600));
    final endY = tester.getCenter(find.byKey(key)).dy;

    expect(startY - endY, closeTo(200, 0.5), reason: 'arranca 200 px más abajo');
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester.getCenter(find.byKey(key)).dy,
      closeTo(endY, 0.01),
      reason: 'la animación corre una sola vez',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ThrownCard con dorso llega dado vuelta: de dorso a frente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: ThrownCard(
            from: Offset(0, -100),
            back: SizedBox(key: Key('dorso'), width: 40, height: 60),
            child: SizedBox(key: Key('frente'), width: 40, height: 60),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('dorso')), findsOneWidget);
    expect(find.byKey(const Key('frente')), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('frente')), findsOneWidget);
    expect(find.byKey(const Key('dorso')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al jugar una carta aparece tirada sobre la mesa y se queda', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = OfflineGameController(botDelayMs: 60000);
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller)),
    );
    await tester.pump();
    expect(find.byType(ThrownCard), findsNothing);

    controller.perform(PlayCardAction(controller.view!.myCards.first));
    await tester.pump();
    expect(find.byType(ThrownCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(ThrownCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
