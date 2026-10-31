import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  testWidgets('arranca una partida con la mano 1 repartida', (
    WidgetTester tester,
  ) async {
    final c = OfflineGameController(botDelayMs: 10);

    expect(c.handNumber, 1);
    expect(c.isMatchOver, isFalse);
    final v = c.view!;
    expect(v.myCards.length, 3);
    expect(v.opponentCardsLeft, 3);
    expect(v.scoreA, 0);
    expect(v.scoreB, 0);
    // La primera mano la abre el jugador local.
    expect(c.isPlayerTurn, isTrue);
    expect(v.legalActions, isNotEmpty);
    c.dispose();
  });

  testWidgets(
    'el marcador se acumula entre manos (regresión del bug del marcador)',
    (WidgetTester tester) async {
      final c = OfflineGameController(botDelayMs: 10);

      // El jugador se va al mazo: el bot se lleva 1 punto.
      expect(c.perform(const FoldAction()), isNull);
      expect(c.view!.finished, isTrue);
      expect(c.view!.scoreB, 1);
      expect(c.statusMessage, contains('Fin de la mano'));

      c.startNextHand();
      expect(c.handNumber, 2);
      expect(
        c.view!.scoreB,
        1,
        reason: 'el puntaje debe arrastrarse a la mano siguiente',
      );
      expect(c.view!.mano, Seat.b, reason: 'el mano rota en cada mano');
      c.dispose();
    },
  );

  testWidgets('perform devuelve un error legible si la acción no es válida', (
    WidgetTester tester,
  ) async {
    final c = OfflineGameController(botDelayMs: 10);

    // Una carta que el jugador no tiene en la mano.
    final mine = c.view!.myCards;
    final notMine = Deck.standard().firstWhere((x) => !mine.contains(x));
    final error = c.perform(PlayCardAction(notMine));
    expect(error, isNotNull);
    expect(error, contains('Acción no permitida'));
    expect(c.view!.myCards.length, 3, reason: 'el estado no debe cambiar');
    c.dispose();
  });

  testWidgets(
    'perform rechaza acciones fuera de turno y después de terminar la mano',
    (WidgetTester tester) async {
      final c = OfflineGameController(botDelayMs: 60000);

      expect(c.perform(const FoldAction()), isNull);
      expect(c.perform(const FoldAction()), 'La mano ya finalizó.');

      c.startNextHand();
      expect(c.isOpponentThinking, isTrue);
      expect(c.perform(const FoldAction()), 'No es tu turno.');
      expect(
        c.view!.finished,
        isFalse,
        reason: 'la acción rechazada no debe cambiar la mano',
      );

      c.dispose();
    },
  );

  testWidgets('el bot juega tras su demora y devuelve el turno al jugador', (
    WidgetTester tester,
  ) async {
    final c = OfflineGameController(botDelayMs: 10);
    c.perform(const FoldAction());
    c.startNextHand(); // en la mano 2 abre el bot

    expect(c.isOpponentThinking, isTrue);
    expect(c.isPlayerTurn, isFalse);

    // Se deja pasar el tiempo (demora del bot + globos) hasta que te toque.
    for (var i = 0; i < 200 && !c.isPlayerTurn; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(c.isPlayerTurn, isTrue);
    expect(c.isOpponentThinking, isFalse);
    expect(c.view!.legalActions, isNotEmpty);
    c.dispose();
  });

  testWidgets(
    'reiniciar la partida mientras el bot piensa no deja nada colgado',
    (WidgetTester tester) async {
      final c = OfflineGameController(botDelayMs: 10);
      c.perform(const FoldAction());
      c.startNextHand();
      expect(c.isOpponentThinking, isTrue);

      c.startNewMatch();
      expect(c.handNumber, 1);
      expect(c.isOpponentThinking, isFalse);
      expect(c.view!.scoreA, 0);
      expect(c.view!.scoreB, 0);

      await tester.pump(const Duration(seconds: 3));
      expect(c.handNumber, 1);
      expect(c.view!.opponentCardsLeft, 3);
      c.dispose();
    },
  );

  testWidgets('el controlador notifica a quien lo escucha', (
    WidgetTester tester,
  ) async {
    final c = OfflineGameController(botDelayMs: 10);
    var notifications = 0;
    c.addListener(() => notifications++);

    c.perform(const FoldAction());
    expect(notifications > 0, isTrue);
    c.dispose();
  });
}
