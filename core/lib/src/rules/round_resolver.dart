import '../models/card.dart';
import '../models/sample.dart';

enum RoundWinner {
  bandoA,
  bandoB,
  parda;
}

enum HandWinner {
  bandoA,
  bandoB;
}

/// Árbitro determinista para la resolución de rondas y pardas en el Truco Uruguayo.
class RoundResolver {
  /// Determina el ganador de una carta individual contra otra según la Muestra.
  static RoundWinner compareCards({
    required TrucoCard cardA,
    required TrucoCard cardB,
    required Sample sample,
  }) {
    final roleA = sample.classify(cardA);
    final roleB = sample.classify(cardB);

    if (roleA.trickPower > roleB.trickPower) {
      return RoundWinner.bandoA;
    } else if (roleB.trickPower > roleA.trickPower) {
      return RoundWinner.bandoB;
    } else {
      return RoundWinner.parda;
    }
  }

  /// Evalúa el desenlace definitivo de la mano basándose en los resultados de las rondas.
  /// [isManoBandoA]: Indica si el Bando A posee la condición reglamentaria de MANO.
  static HandWinner? evaluateHandWinner({
    required List<RoundWinner> rounds,
    required bool isManoBandoA,
  }) {
    if (rounds.isEmpty) return null;

    final r1 = rounds[0];

    // Con sólo 2 rondas jugadas:
    if (rounds.length == 2) {
      final r2 = rounds[1];

      // Caso P5: Ganó A la 1ª y la 2ª fue parda -> Gana A
      if (r1 == RoundWinner.bandoA && r2 == RoundWinner.parda) {
        return HandWinner.bandoA;
      }
      // Caso inverso P5: Ganó B la 1ª y la 2ª fue parda -> Gana B
      if (r1 == RoundWinner.bandoB && r2 == RoundWinner.parda) {
        return HandWinner.bandoB;
      }
      // Caso P2: 1ª parda, y 2ª ganada por A -> Gana A
      if (r1 == RoundWinner.parda && r2 == RoundWinner.bandoA) {
        return HandWinner.bandoA;
      }
      // Caso inverso P2: 1ª parda, y 2ª ganada por B -> Gana B
      if (r1 == RoundWinner.parda && r2 == RoundWinner.bandoB) {
        return HandWinner.bandoB;
      }
      // Ganar dos seguidas (2 a 0)
      if (r1 == RoundWinner.bandoA && r2 == RoundWinner.bandoA) {
        return HandWinner.bandoA;
      }
      if (r1 == RoundWinner.bandoB && r2 == RoundWinner.bandoB) {
        return HandWinner.bandoB;
      }

      return null; // Aún requiere 3ª ronda
    }

    if (rounds.length == 3) {
      final r2 = rounds[1];
      final r3 = rounds[2];

      // Caso P4: Parda en las tres rondas -> Gana el jugador que es MANO
      if (r1 == RoundWinner.parda &&
          r2 == RoundWinner.parda &&
          r3 == RoundWinner.parda) {
        return isManoBandoA ? HandWinner.bandoA : HandWinner.bandoB;
      }

      // Caso P3: 1ª parda, 2ª parda, 3ª define
      if (r1 == RoundWinner.parda && r2 == RoundWinner.parda) {
        if (r3 == RoundWinner.bandoA) return HandWinner.bandoA;
        if (r3 == RoundWinner.bandoB) return HandWinner.bandoB;
      }

      // Caso P6: Ganó uno la 1ª, otro la 2ª y la 3ª fue parda -> Gana quien ganó la 1ª
      if (r3 == RoundWinner.parda) {
        if (r1 == RoundWinner.bandoA) return HandWinner.bandoA;
        if (r1 == RoundWinner.bandoB) return HandWinner.bandoB;
      }

      // Conteo simple de rondas (2 de 3)
      final winsA = rounds.where((r) => r == RoundWinner.bandoA).length;
      final winsB = rounds.where((r) => r == RoundWinner.bandoB).length;

      if (winsA > winsB) return HandWinner.bandoA;
      if (winsB > winsA) return HandWinner.bandoB;
    }

    return null;
  }
}
