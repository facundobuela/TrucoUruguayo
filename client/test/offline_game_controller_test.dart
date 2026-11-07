import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/audio/game_audio.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_core/truco_core.dart';

import 'helpers/recording_game_audio.dart';

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

  testWidgets(
    'al resolverse una ronda las cartas se recogen y recién después se sigue jugando',
    (WidgetTester tester) async {
      final c = OfflineGameController(
        botDelayMs: 1,
        roundShowMs: 100,
        roundCollectMs: 50,
      );

      // Se juega (aceptando todo lo que cante el bot) hasta que se resuelva
      // la primera ronda.
      for (var i = 0; i < 600 && c.roundPhase == RoundCollectPhase.none; i++) {
        if (c.isPlayerTurn) {
          final legal = c.view!.legalActions;
          final action = legal.contains(const RespondAction(BetResponse.quiero))
              ? const RespondAction(BetResponse.quiero)
              : legal.firstWhere(
                  (a) => a is PlayCardAction,
                  orElse: () => legal.first,
                );
          c.perform(action);
        }
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(c.roundPhase, RoundCollectPhase.showing);
      expect(c.isPlayerTurn, isFalse, reason: 'mientras se recogen no se juega');
      expect(c.perform(const FoldAction()), isNotNull);
      final table = c.view!.table;
      expect(table.length - c.collectedRounds, 1);
      expect(table.last.result, isNotNull);

      var sawCollecting = false;
      for (var i = 0; i < 100 && c.roundPhase != RoundCollectPhase.none; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        if (c.roundPhase == RoundCollectPhase.collecting) sawCollecting = true;
      }
      expect(sawCollecting, isTrue, reason: 'pasa por la fase de recogida');
      expect(c.roundPhase, RoundCollectPhase.none);
      expect(
        c.collectedRounds,
        c.view!.table.where((r) => r.result != null).length,
      );
      c.dispose();
    },
  );

  testWidgets('una mano nueva empieza con la mesa limpia', (
    WidgetTester tester,
  ) async {
    final c = OfflineGameController(
      botDelayMs: 1,
      roundShowMs: 100,
      roundCollectMs: 50,
    );
    c.perform(const FoldAction());
    c.startNextHand();
    expect(c.collectedRounds, 0);
    expect(c.roundPhase, RoundCollectPhase.none);
    expect(c.view!.table, isEmpty);
    c.dispose();
  });

  group('Sonido', () {
    testWidgets('la carta suena cuando aterriza sobre la mesa', (
      WidgetTester tester,
    ) async {
      final audio = RecordingGameAudio();
      final c = OfflineGameController(botDelayMs: 60000, audio: audio);

      c.perform(PlayCardAction(c.view!.myCards.first));
      expect(audio.sfx, isEmpty, reason: 'todavía está en el aire');

      await tester.pump(const Duration(milliseconds: 350));
      expect(audio.sfx, [GameSfx.cardPlace]);
      c.dispose();
    });

    testWidgets('cantar truco dice "¡Truco!" con tu voz', (
      WidgetTester tester,
    ) async {
      final audio = RecordingGameAudio();
      final c = OfflineGameController(botDelayMs: 60000, audio: audio);

      c.perform(const CallAction(BetCall.truco));
      expect(audio.voices, ['truco']);
      expect(audio.voiceFromPlayer, [true]);
      c.dispose();
    });

    testWidgets('irse al mazo suena a cartas que vuelven al mazo y lo dice', (
      WidgetTester tester,
    ) async {
      final audio = RecordingGameAudio();
      final c = OfflineGameController(botDelayMs: 60000, audio: audio);

      c.perform(const FoldAction());
      expect(audio.sfx, contains(GameSfx.cardsToDeck));
      expect(audio.voices.single, anyOf('me_voy_al_mazo', 'al_mazo'));
      c.dispose();
    });

    testWidgets('al silenciar no suena nada y al reactivar vuelve a sonar', (
      WidgetTester tester,
    ) async {
      final audio = RecordingGameAudio();
      final c = OfflineGameController(botDelayMs: 60000, audio: audio);
      expect(c.soundEnabled, isTrue);

      c.toggleSound();
      expect(c.soundEnabled, isFalse);
      c.perform(const CallAction(BetCall.truco));
      expect(audio.voices, isEmpty);

      c.toggleSound();
      expect(c.soundEnabled, isTrue);
      c.dispose();
    });

    testWidgets('al recogerse la ronda suena el efecto del mazo', (
      WidgetTester tester,
    ) async {
      final audio = RecordingGameAudio();
      final c = OfflineGameController(
        botDelayMs: 1,
        roundShowMs: 100,
        roundCollectMs: 50,
        audio: audio,
      );

      for (var i = 0; i < 600 && c.roundPhase == RoundCollectPhase.none; i++) {
        if (c.isPlayerTurn) {
          final legal = c.view!.legalActions;
          c.perform(
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
      expect(audio.sfx, isNot(contains(GameSfx.cardsToDeck)),
          reason: 'recién se ve la ronda');

      for (var i = 0; i < 100 && c.roundPhase != RoundCollectPhase.none; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(audio.sfx, contains(GameSfx.cardsToDeck));
      c.dispose();
    });
  });
}
