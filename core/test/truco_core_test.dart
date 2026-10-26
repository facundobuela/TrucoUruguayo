import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  group('1. Jerarquía y Carta Sustituta (J1 - J11)', () {
    final sampleEspada = Sample(const TrucoCard(7, Suit.espada));

    test('J1: 2 de Espada es la Pieza Máxima', () {
      final role = sampleEspada.classify(const TrucoCard(2, Suit.espada));
      expect(role, CardRole.piezaDos);
      expect(role.envidoScore, 30);
    });

    test('J2: 4 de Espada es la 2ª Pieza', () {
      final role = sampleEspada.classify(const TrucoCard(4, Suit.espada));
      expect(role, CardRole.piezaCuatro);
      expect(role.envidoScore, 29);
    });

    test('J3: 5 de Espada es la 3ª Pieza', () {
      final role = sampleEspada.classify(const TrucoCard(5, Suit.espada));
      expect(role, CardRole.piezaCinco);
      expect(role.envidoScore, 28);
    });

    test('J4: 11 de Espada es el Perico', () {
      final role = sampleEspada.classify(const TrucoCard(11, Suit.espada));
      expect(role, CardRole.piezaPerico);
      expect(role.envidoScore, 27);
    });

    test('J5: 10 de Espada es la Perica', () {
      final role = sampleEspada.classify(const TrucoCard(10, Suit.espada));
      expect(role, CardRole.piezaPerica);
      expect(role.envidoScore, 27);
    });

    test('J6: 1 de Espada es Macho', () {
      final role = sampleEspada.classify(const TrucoCard(1, Suit.espada));
      expect(role, CardRole.macho);
    });

    test('J7: Muestra 2 de Oro -> 12 de Oro sustituye al 2 (30 pts)', () {
      final sample = Sample(const TrucoCard(2, Suit.oro));
      final role = sample.classify(const TrucoCard(12, Suit.oro));
      expect(role, CardRole.piezaDos);
      expect(role.envidoScore, 30);
    });

    test('J8: Muestra 4 de Basto -> 12 de Basto sustituye al 4 (29 pts)', () {
      final sample = Sample(const TrucoCard(4, Suit.basto));
      final role = sample.classify(const TrucoCard(12, Suit.basto));
      expect(role, CardRole.piezaCuatro);
      expect(role.envidoScore, 29);
    });

    test('J9: Muestra 5 de Copa -> 12 de Copa sustituye al 5 (28 pts)', () {
      final sample = Sample(const TrucoCard(5, Suit.copa));
      final role = sample.classify(const TrucoCard(12, Suit.copa));
      expect(role, CardRole.piezaCinco);
      expect(role.envidoScore, 28);
    });

    test('J10: Muestra 11 de Basto -> 12 de Basto sustituye al Perico (27 pts)', () {
      final sample = Sample(const TrucoCard(11, Suit.basto));
      final role = sample.classify(const TrucoCard(12, Suit.basto));
      expect(role, CardRole.piezaPerico);
      expect(role.envidoScore, 27);
    });

    test('J11: Muestra 10 de Copa -> 12 de Copa sustituye a la Perica (27 pts)', () {
      final sample = Sample(const TrucoCard(10, Suit.copa));
      final role = sample.classify(const TrucoCard(12, Suit.copa));
      expect(role, CardRole.piezaPerica);
      expect(role.envidoScore, 27);
    });
  });

  group('2. Resolución de Rondas y Pardas (P1 - P6)', () {
    test('P1: Bando A gana 1ª y 3ª -> Gana Bando A (2 a 1)', () {
      final winner = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.bandoA, RoundWinner.bandoB, RoundWinner.bandoA],
        isManoBandoA: false,
      );
      expect(winner, HandWinner.bandoA);
    });

    test('P2: 1ª Parda, 2ª Bando A -> Gana Bando A', () {
      final winner = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.parda, RoundWinner.bandoA],
        isManoBandoA: false,
      );
      expect(winner, HandWinner.bandoA);
    });

    test('P3: 1ª y 2ª Pardas, 3ª Bando B -> Gana Bando B', () {
      final winner = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.parda, RoundWinner.parda, RoundWinner.bandoB],
        isManoBandoA: true,
      );
      expect(winner, HandWinner.bandoB);
    });

    test('P4: Tres Pardas -> Gana el jugador MANO', () {
      final winnerA = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.parda, RoundWinner.parda, RoundWinner.parda],
        isManoBandoA: true,
      );
      expect(winnerA, HandWinner.bandoA);

      final winnerB = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.parda, RoundWinner.parda, RoundWinner.parda],
        isManoBandoA: false,
      );
      expect(winnerB, HandWinner.bandoB);
    });

    test('P5: Bando A gana 1ª y 2ª es Parda -> Gana Bando A', () {
      final winner = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.bandoA, RoundWinner.parda],
        isManoBandoA: false,
      );
      expect(winner, HandWinner.bandoA);
    });

    test('P6: Bando B gana 1ª, Bando A gana 2ª, 3ª es Parda -> Gana Bando B', () {
      final winner = RoundResolver.evaluateHandWinner(
        rounds: [RoundWinner.bandoB, RoundWinner.bandoA, RoundWinner.parda],
        isManoBandoA: false,
      );
      expect(winner, HandWinner.bandoB);
    });
  });

  group('3. Cálculo de Flor (F1 - F5)', () {
    final sampleBasto = Sample(const TrucoCard(1, Suit.basto));

    test('F1: Flor tradicional 3 del mismo palo (2, 6, 7 de Oro) -> 35 pts', () {
      final sample = Sample(const TrucoCard(3, Suit.basto));
      final hand = [
        const TrucoCard(2, Suit.oro),
        const TrucoCard(6, Suit.oro),
        const TrucoCard(7, Suit.oro),
      ];
      final res = FlorCalculator.evaluate(hand, sample);
      expect(res.hasFlor, true);
      expect(res.score, 35); // 2 + 6 + 7 + 20 = 35
    });

    test('F2: Flor tradicional con figuras (10, 11, 7 de Copa) -> 27 pts', () {
      final sample = Sample(const TrucoCard(3, Suit.basto));
      final hand = [
        const TrucoCard(10, Suit.copa),
        const TrucoCard(11, Suit.copa),
        const TrucoCard(7, Suit.copa),
      ];
      final res = FlorCalculator.evaluate(hand, sample);
      expect(res.hasFlor, true);
      expect(res.score, 27); // 0 + 0 + 7 + 20 = 27
    });

    test('F3: 1 Pieza (2 Basto=30) + 2 Espada (4 y 7) -> 41 pts', () {
      final hand = [
        const TrucoCard(2, Suit.basto),
        const TrucoCard(4, Suit.espada),
        const TrucoCard(7, Suit.espada),
      ];
      final res = FlorCalculator.evaluate(hand, sampleBasto);
      expect(res.hasFlor, true);
      expect(res.score, 41); // 30 + 4 + 7 = 41
    });

    test('F4: 2 Piezas (2 y 4 de Basto) + 1 Oro -> 60 pts', () {
      final hand = [
        const TrucoCard(2, Suit.basto),
        const TrucoCard(4, Suit.basto),
        const TrucoCard(1, Suit.oro),
      ];
      final res = FlorCalculator.evaluate(hand, sampleBasto);
      expect(res.hasFlor, true);
      expect(res.score, 60); // 30 + 29 + 1 = 60
    });

    test('F5: 3 Piezas (2, 4, 5 de Basto) -> 87 pts', () {
      final hand = [
        const TrucoCard(2, Suit.basto),
        const TrucoCard(4, Suit.basto),
        const TrucoCard(5, Suit.basto),
      ];
      final res = FlorCalculator.evaluate(hand, sampleBasto);
      expect(res.hasFlor, true);
      expect(res.score, 87); // 30 + 29 + 28 = 87
    });
  });

  group('4. Cálculo de Envido (E1 - E5)', () {
    test('E1: Envido sin pieza (1 y 5 de Copa) -> 26 pts', () {
      final sample = Sample(const TrucoCard(7, Suit.espada));
      final hand = [
        const TrucoCard(1, Suit.copa),
        const TrucoCard(5, Suit.copa),
        const TrucoCard(3, Suit.basto),
      ];
      expect(EnvidoCalculator.calculate(hand, sample), 26);
    });

    test('E2: 1 Pieza (4 de Basto=29) + 6 de Basto -> 35 pts', () {
      final sample = Sample(const TrucoCard(1, Suit.basto));
      final hand = [
        const TrucoCard(4, Suit.basto),
        const TrucoCard(6, Suit.basto),
        const TrucoCard(2, Suit.copa),
      ];
      expect(EnvidoCalculator.calculate(hand, sample), 35); // 29 + 6 = 35
    });

    test('E3: 1 Pieza (2 de Basto=30) liga con carta ajena (3 de Copa) -> 33 pts', () {
      final sample = Sample(const TrucoCard(1, Suit.basto));
      final hand = [
        const TrucoCard(2, Suit.basto),
        const TrucoCard(3, Suit.copa),
        const TrucoCard(1, Suit.oro),
      ];
      expect(EnvidoCalculator.calculate(hand, sample), 33); // 30 + 3 = 33
    });

    test('E4: Muestra 2 de Basto -> Sustituto 12 de Basto (30) + 7 de Oro -> 37 pts', () {
      final sample = Sample(const TrucoCard(2, Suit.basto));
      final hand = [
        const TrucoCard(12, Suit.basto), // Sustituto del 2
        const TrucoCard(7, Suit.oro),
        const TrucoCard(3, Suit.copa),
      ];
      expect(EnvidoCalculator.calculate(hand, sample), 37); // 30 + 7 = 37
    });

    test('E5: Sin pares ni piezas -> Carta más alta (3 de Basto)', () {
      final sample = Sample(const TrucoCard(7, Suit.espada));
      final hand = [
        const TrucoCard(1, Suit.copa),
        const TrucoCard(12, Suit.oro),
        const TrucoCard(3, Suit.basto),
      ];
      expect(EnvidoCalculator.calculate(hand, sample), 3);
    });
  });
}
