import 'dart:math';

import 'package:truco_core/truco_core.dart';

/// Textos del juego en español rioplatense.
///
/// Están centralizados (y sin dependencia de Flutter) para poder probarlos
/// fácilmente y, más adelante, internacionalizarlos (RF-24: español, inglés y
/// portugués).
class GameTexts {
  GameTexts._();

  /// Nombre legible de una carta, p. ej. "4 de Basto".
  static String cardName(TrucoCard c) => '${c.number} de ${c.suit.displayName}';

  /// Nombre de un canto para los botones y la barra de estado.
  static String betName(BetCall bet) {
    switch (bet) {
      case BetCall.envido:
        return 'Envido';
      case BetCall.realEnvido:
        return 'Real Envido';
      case BetCall.faltaEnvido:
        return 'Falta Envido';
      case BetCall.flor:
        return 'Flor';
      case BetCall.contraflor:
        return 'Contraflor';
      case BetCall.truco:
        return 'Truco';
      case BetCall.retruco:
        return 'Retruco';
      case BetCall.valeCuatro:
        return 'Vale Cuatro';
    }
  }

  static String betResponseName(BetResponse response) {
    switch (response) {
      case BetResponse.quiero:
        return 'Quiero';
      case BetResponse.noQuiero:
        return 'No quiero';
      case BetResponse.conFlorMeAchico:
        return 'Con Flor me achico';
    }
  }

  static String pointsReason(PointsReason reason) {
    switch (reason) {
      case PointsReason.envidoQuerido:
        return 'Envido querido';
      case PointsReason.envidoNoQuerido:
        return 'Envido no querido';
      case PointsReason.flor:
        return 'Flor';
      case PointsReason.florAmbas:
        return 'Ambos con Flor';
      case PointsReason.contraflorQuerida:
        return 'Contraflor querida';
      case PointsReason.conFlorMeAchico:
        return 'Con Flor me achico';
      case PointsReason.trucoNoQuerido:
        return 'Truco no querido';
      case PointsReason.manoGanada:
        return 'Mano ganada';
      case PointsReason.irseAlMazo:
        return 'Irse al mazo';
    }
  }

  /// Etiqueta de la jerarquía de una carta de la mano (vacía si es común).
  static String cardRole(CardRole role) {
    switch (role) {
      case CardRole.piezaDos:
        return '2 (Pieza)';
      case CardRole.piezaCuatro:
        return '4 (Pieza)';
      case CardRole.piezaCinco:
        return '5 (Pieza)';
      case CardRole.piezaPerico:
        return 'Perico (11)';
      case CardRole.piezaPerica:
        return 'Perica (10)';
      case CardRole.macho:
        return '1 Espada (Macho)';
      case CardRole.hembra:
        return '1 Basto (Hembra)';
      case CardRole.sieteEspada:
        return '7 Espada';
      case CardRole.sieteOro:
        return '7 Oro';
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Frases dichas en los globos de texto
  // ---------------------------------------------------------------------------

  /// Lo que se dice al cantar. [envidoCount] es la cantidad de "Envido" de la
  /// cadena actual (con 2 se dice "Envido, envido").
  static String callPhrase(BetCall bet, {int envidoCount = 1}) {
    switch (bet) {
      case BetCall.envido:
        return envidoCount >= 2 ? '¡Envido, envido!' : '¡Envido!';
      case BetCall.realEnvido:
        return '¡Real envido!';
      case BetCall.faltaEnvido:
        return '¡Falta envido!';
      case BetCall.flor:
        return '¡Flor!';
      case BetCall.contraflor:
        return '¡Contraflor!';
      case BetCall.truco:
        return '¡Truco!';
      case BetCall.retruco:
        return '¡Quiero retruco!';
      case BetCall.valeCuatro:
        return '¡Quiero vale cuatro!';
    }
  }

  static String responsePhrase(BetResponse r, Random rng) {
    switch (r) {
      case BetResponse.quiero:
        return _pick(rng, ['¡Quiero!', '¡Quiero!', '¡Quiero, dale!']);
      case BetResponse.noQuiero:
        return _pick(rng, ['No quiero', 'No quiero', 'No, no quiero']);
      case BetResponse.conFlorMeAchico:
        return 'Con flor me achico';
    }
  }

  static String foldPhrase(Random rng) =>
      _pick(rng, ['Me voy al mazo', 'Al mazo']);

  static String _pick(Random rng, List<String> options) =>
      options[rng.nextInt(options.length)];
}
