import '../models/card.dart';
import '../models/sample.dart';

/// Resultado de la evaluación de Flor para una mano dada.
class FlorEvaluation {
  final bool hasFlor;
  final int score;
  final String description;

  const FlorEvaluation({
    required this.hasFlor,
    required this.score,
    required this.description,
  });

  static const noFlor = FlorEvaluation(
    hasFlor: false,
    score: 0,
    description: 'No posee Flor',
  );
}

/// Evaluador oficial de combinaciones y cálculo de Flor en Truco Uruguayo.
class FlorCalculator {
  static FlorEvaluation evaluate(List<TrucoCard> hand, Sample sample) {
    if (hand.length != 3) {
      throw ArgumentError('Una mano de Truco debe contener exactamente 3 cartas');
    }

    final classified = hand.map((c) {
      final role = sample.classify(c);
      return (card: c, role: role);
    }).toList();

    final pieces = classified.where((item) => item.role.isPiece).toList();
    final nonPieces = classified.where((item) => !item.role.isPiece).toList();

    // Combinación 4: 3 piezas de la muestra
    if (pieces.length == 3) {
      final score = pieces[0].role.envidoScore +
          pieces[1].role.envidoScore +
          pieces[2].role.envidoScore;
      return FlorEvaluation(
        hasFlor: true,
        score: score,
        description: 'Flor con 3 piezas de la muestra',
      );
    }

    // Combinación 3: 2 piezas de la muestra + 1 carta cualquiera
    if (pieces.length == 2) {
      final score = pieces[0].role.envidoScore +
          pieces[1].role.envidoScore +
          nonPieces.first.card.envidoFaceValue;
      return FlorEvaluation(
        hasFlor: true,
        score: score,
        description: 'Flor con 2 piezas de la muestra y 1 carta',
      );
    }

    // Combinación 2: 1 pieza de la muestra + 2 cartas del mismo palo entre sí
    if (pieces.length == 1) {
      if (nonPieces.length == 2 &&
          nonPieces[0].card.suit == nonPieces[1].card.suit) {
        final score = pieces.first.role.envidoScore +
            nonPieces[0].card.envidoFaceValue +
            nonPieces[1].card.envidoFaceValue;
        return FlorEvaluation(
          hasFlor: true,
          score: score,
          description: 'Flor con 1 pieza y 2 cartas del mismo palo',
        );
      }
      return FlorEvaluation.noFlor;
    }

    // Combinación 1: 3 cartas del mismo palo sin piezas
    if (pieces.isEmpty) {
      if (hand[0].suit == hand[1].suit && hand[1].suit == hand[2].suit) {
        final score = 20 +
            hand[0].envidoFaceValue +
            hand[1].envidoFaceValue +
            hand[2].envidoFaceValue;
        return FlorEvaluation(
          hasFlor: true,
          score: score,
          description: 'Flor tradicional con 3 cartas del mismo palo',
        );
      }
    }

    return FlorEvaluation.noFlor;
  }
}
