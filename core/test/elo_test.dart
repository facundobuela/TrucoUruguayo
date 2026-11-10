import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  const elo = Elo();
  // Jugadores con historial (K = 32) y nuevos (K = 48).
  const veteran = EloEntry(1000, 50);
  const rookie = EloEntry(1000, 0);

  group('Probabilidad esperada', () {
    test('con puntajes parejos es 50 %', () {
      expect(elo.expectedScore(1000, 1000), closeTo(0.5, 1e-9));
    });

    test('las probabilidades de los dos lados suman 1', () {
      for (final (a, b) in [(1000, 1400), (1500, 900), (1200, 1200)]) {
        expect(
          elo.expectedScore(a, b) + elo.expectedScore(b, a),
          closeTo(1, 1e-9),
        );
      }
    });

    test('400 puntos de ventaja = 10 a 1 (≈ 91 %)', () {
      expect(elo.expectedScore(1400, 1000), closeTo(10 / 11, 1e-9));
    });
  });

  group('Duelo 1 contra 1', () {
    test(
      'parejos con K = 32: el que gana suma 16 y el que pierde resta 16',
      () {
        final r = elo.duel(a: veteran, b: veteran, aWon: true);
        expect(r.a.delta, 16);
        expect(r.b.delta, -16);
        expect(r.a.newRating, 1016);
        expect(r.b.newRating, 984);
      },
    );

    test('es de suma cero cuando ambos tienen el mismo K', () {
      for (final (ra, rb) in [(1000, 1300), (1500, 1100), (1234, 1234)]) {
        for (final aWon in [true, false]) {
          final r = elo.duel(
            a: EloEntry(ra, 40),
            b: EloEntry(rb, 40),
            aWon: aWon,
          );
          expect(r.a.delta + r.b.delta, 0, reason: '$ra vs $rb gana A=$aWon');
        }
      }
    });

    test('ganarle a alguien más fuerte da más puntos que a uno más débil', () {
      const strong = EloEntry(1400, 50);
      const weak = EloEntry(800, 50);
      final upset = elo.duel(a: veteran, b: strong, aWon: true).a.delta;
      final expected = elo.duel(a: veteran, b: weak, aWon: true).a.delta;
      expect(upset, greaterThan(expected));
      expect(upset, greaterThan(16));
      expect(expected, lessThan(16));
    });

    test(
      'perder contra alguien más débil resta más que contra uno más fuerte',
      () {
        const strong = EloEntry(1400, 50);
        const weak = EloEntry(800, 50);
        final lossToWeak = elo.duel(a: veteran, b: weak, aWon: false).a.delta;
        final lossToStrong = elo
            .duel(a: veteran, b: strong, aWon: false)
            .a
            .delta;
        expect(lossToWeak, lessThan(lossToStrong));
      },
    );

    test('el jugador nuevo se mueve más rápido (K provisional = 48)', () {
      final r = elo.duel(a: rookie, b: rookie, aWon: true);
      expect(r.a.delta, 24);
      expect(r.b.delta, -24);
    });

    test(
      'el K pasa a ser el normal al llegar a las partidas provisionales',
      () {
        expect(elo.kFor(0), 48);
        expect(elo.kFor(9), 48);
        expect(elo.kFor(10), 32);
      },
    );

    test('nadie baja del puntaje mínimo', () {
      const low = EloEntry(105, 50);
      final r = elo.duel(a: low, b: const EloEntry(105, 50), aWon: false);
      expect(r.a.newRating, 100);
      expect(r.a.delta, -5);
      const atFloor = EloEntry(100, 50);
      final r2 = elo.duel(a: atFloor, b: veteran, aWon: false);
      expect(r2.a.newRating, 100);
      expect(r2.a.delta, 0);
    });
  });

  group('Por equipos (2 vs 2)', () {
    test('el puntaje del equipo es el promedio de sus integrantes', () {
      expect(
        elo.teamRating(const [EloEntry(1000, 5), EloEntry(1200, 5)]),
        1100,
      );
      expect(
        elo.teamRating(const [EloEntry(1001, 5), EloEntry(1000, 5)]),
        1001,
      );
      expect(() => elo.teamRating(const []), throwsArgumentError);
    });

    test('equipos parejos: ganadores suman y perdedores restan lo mismo', () {
      final r = elo.teamDuel(
        teamA: const [EloEntry(1000, 50), EloEntry(1000, 50)],
        teamB: const [EloEntry(1000, 50), EloEntry(1000, 50)],
        teamAWon: true,
      );
      expect(r.a.map((c) => c.delta).toList(), [16, 16]);
      expect(r.b.map((c) => c.delta).toList(), [-16, -16]);
    });

    test(
      'todos los integrantes de un equipo parten de la misma probabilidad',
      () {
        // Con el mismo K, un compañero fuerte y uno débil ganan lo mismo.
        final r = elo.teamDuel(
          teamA: const [EloEntry(800, 50), EloEntry(1400, 50)],
          teamB: const [EloEntry(1100, 50), EloEntry(1100, 50)],
          teamAWon: true,
        );
        expect(r.a[0].delta, r.a[1].delta);
      },
    );

    test('cada integrante usa su propio K', () {
      final r = elo.teamDuel(
        teamA: const [EloEntry(1000, 50), EloEntry(1000, 0)],
        teamB: const [EloEntry(1000, 50), EloEntry(1000, 50)],
        teamAWon: true,
      );
      expect(r.a[0].delta, 16);
      expect(r.a[1].delta, 24);
    });

    test('se mide contra el promedio del rival, no contra cada rival', () {
      // Equipo A promedia 1100; B promedia 1000: A es favorito (gana menos).
      final r = elo.teamDuel(
        teamA: const [EloEntry(1000, 50), EloEntry(1200, 50)],
        teamB: const [EloEntry(1000, 50), EloEntry(1000, 50)],
        teamAWon: true,
      );
      expect(r.a.first.delta, lessThan(16));
      expect(r.b.first.delta, greaterThan(-16));
    });
  });

  group('Configuración', () {
    test('valores por defecto', () {
      const c = EloConfig();
      expect(c.initialRating, 1000);
      expect(c.kFactor, 32);
    });

    test('se puede usar otra configuración', () {
      const strict = Elo(EloConfig(kFactor: 10, provisionalKFactor: 10));
      expect(strict.duel(a: veteran, b: veteran, aWon: true).a.delta, 5);
    });
  });
}
