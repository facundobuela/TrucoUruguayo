import 'dart:math';
import '../models/card.dart';
import '../models/sample.dart';

/// Calculador determinista de puntos de Envido en el Truco Uruguayo.
class EnvidoCalculator {
  /// Calcula el puntaje óptimo de envido para una mano de 3 cartas dada una Muestra.
  static int calculate(List<TrucoCard> hand, Sample sample) {
    if (hand.length != 3) {
      throw ArgumentError('Una mano de Truco debe contener exactamente 3 cartas');
    }

    // Clasificar las 3 cartas según la muestra
    final classified = hand.map((c) {
      final role = sample.classify(c);
      return (card: c, role: role);
    }).toList();

    final pieces = classified.where((item) => item.role.isPiece).toList();
    final nonPieces = classified.where((item) => !item.role.isPiece).toList();

    // Caso 1: Tiene 2 o más piezas
    if (pieces.length >= 2) {
      // Ordenar piezas de mayor a menor valor
      pieces.sort((a, b) => b.role.envidoScore.compareTo(a.role.envidoScore));
      // Suman las dos piezas de mayor valor
      return pieces[0].role.envidoScore + pieces[1].role.envidoScore;
    }

    // Caso 2: Tiene exactamente 1 pieza
    if (pieces.length == 1) {
      final pieceScore = pieces.first.role.envidoScore;
      // Una pieza liga con CUALQUIER carta de la mano sin importar el palo.
      // Se elige la carta no-pieza que otorgue mayor valor facial (las figuras suman 0).
      int highestOtherValue = 0;
      for (final np in nonPieces) {
        highestOtherValue = max(highestOtherValue, np.card.envidoFaceValue);
      }
      return pieceScore + highestOtherValue;
    }

    // Caso 3: No tiene piezas
    // Agrupar por palo
    final suitGroups = <dynamic, List<TrucoCard>>{};
    for (final item in classified) {
      suitGroups.putIfAbsent(item.card.suit, () => []).add(item.card);
    }

    int bestEnvido = 0;

    // Buscar si hay dos o más cartas del mismo palo
    for (final cardsInSuit in suitGroups.values) {
      if (cardsInSuit.length >= 2) {
        cardsInSuit.sort((a, b) => b.envidoFaceValue.compareTo(a.envidoFaceValue));
        final suitEnvido = 20 + cardsInSuit[0].envidoFaceValue + cardsInSuit[1].envidoFaceValue;
        bestEnvido = max(bestEnvido, suitEnvido);
      }
    }

    if (bestEnvido > 0) {
      return bestEnvido;
    }

    // Caso 4: Las 3 cartas son de distinto palo y sin piezas
    // El envido es el valor facial más alto de las 3 cartas (las figuras valen 0)
    for (final item in classified) {
      bestEnvido = max(bestEnvido, item.card.envidoFaceValue);
    }

    return bestEnvido;
  }
}
