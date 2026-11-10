import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_client/features/modes/game_mode.dart';
import 'package:truco_client/features/modes/game_session_factory.dart';
import 'package:truco_client/features/ranked/ranked_service.dart';

void main() {
  group('Catálogo de modos', () {
    test('los ids son únicos y se pueden buscar', () {
      final ids = GameModes.all.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final m in GameModes.all) {
        expect(GameModes.byId(m.id), same(m));
      }
      expect(GameModes.byId('no_existe'), isNull);
    });

    test('hoy sólo se puede jugar 1 vs 1 contra el Bot', () {
      final playable = GameModes.all.where((m) => m.isPlayable).toList();
      expect(playable, [GameModes.vsBot]);
    });

    test('el menú "Jugar" ofrece los tres modos pedidos', () {
      expect(GameModes.casual, [
        GameModes.vsBot,
        GameModes.vsPlayer,
        GameModes.twoVsTwo,
      ]);
      expect(GameModes.casual.every((m) => !m.ranked), isTrue);
    });

    test('el menú de Elo sólo tiene modos clasificatorios', () {
      expect(GameModes.rankedModes.every((m) => m.ranked), isTrue);
      expect(GameModes.rankedModes.map((m) => m.playersPerTeam).toList(), [
        1,
        2,
      ]);
    });

    test('las partidas contra el Bot nunca suman Elo (RF-02)', () {
      expect(GameModes.vsBot.countsForElo, isFalse);
      for (final m in GameModes.all) {
        if (m.opponent == OpponentKind.bot) expect(m.countsForElo, isFalse);
      }
    });

    test('las clasificatorias suman Elo y exigen cuenta (RF-01)', () {
      for (final m in GameModes.rankedModes) {
        expect(m.countsForElo, isTrue, reason: m.title);
        expect(m.requiresAccount, isTrue, reason: m.title);
      }
      expect(GameModes.vsPlayer.countsForElo, isFalse);
    });

    test('la cantidad de jugadores sale de los equipos', () {
      expect(GameModes.vsBot.seats, 2);
      expect(GameModes.twoVsTwo.seats, 4);
    });
  });

  group('Fábrica de partidas', () {
    test('1 vs 1 contra el Bot arma una partida local', () {
      final controller = const DefaultGameSessionFactory().create(
        GameModes.vsBot,
      );
      expect(controller, isA<OfflineGameController>());
      expect(controller.view!.myCards.length, 3);
      controller.dispose();
    });

    test('los modos sin implementar lanzan ModeNotAvailableException', () {
      const factory = DefaultGameSessionFactory();
      for (final m in [
        GameModes.vsPlayer,
        GameModes.twoVsTwo,
        GameModes.ranked1v1,
        GameModes.ranked2v2,
      ]) {
        expect(
          () => factory.create(m),
          throwsA(isA<ModeNotAvailableException>()),
          reason: m.title,
        );
      }
    });
  });

  group('Partidas Elo (estructura)', () {
    test('sin servidor: no disponible, sin perfil y sin partidas', () async {
      const service = UnavailableRankedService();
      expect(service.availability, RankedAvailability.unavailable);
      expect(await service.loadProfile(), isNull);
      await expectLater(
        service.findMatch(GameModes.ranked1v1),
        throwsA(isA<ModeNotAvailableException>()),
      );
    });

    test('el porcentaje de victorias del perfil', () {
      const p = RankedProfile(
        rating: 1100,
        gamesPlayed: 10,
        wins: 7,
        losses: 3,
      );
      expect(p.winRate, closeTo(0.7, 1e-9));
      const nuevo = RankedProfile(
        rating: 1000,
        gamesPlayed: 0,
        wins: 0,
        losses: 0,
      );
      expect(nuevo.winRate, 0);
    });
  });
}
