import '../models/card.dart';

/// Cantos que un jugador puede realizar. Subir una apuesta ("revirar") es
/// simplemente realizar el canto superior: no existe una respuesta REVIRAR.
enum BetCall {
  envido('ENVIDO'),
  realEnvido('REAL_ENVIDO'),
  faltaEnvido('FALTA_ENVIDO'),
  flor('FLOR'),
  contraflor('CONTRAFLOR'),
  truco('TRUCO'),
  retruco('RETRUCO'),
  valeCuatro('VALE_CUATRO');

  final String wire;
  const BetCall(this.wire);

  static BetCall fromWire(String w) => BetCall.values.firstWhere(
      (b) => b.wire == w,
      orElse: () => throw FormatException('Canto inválido: $w'));

  bool get isEnvido =>
      this == envido || this == realEnvido || this == faltaEnvido;
  bool get isTruco => this == truco || this == retruco || this == valeCuatro;
  bool get isFlor => this == flor || this == contraflor;
}

/// Respuestas a un canto pendiente.
enum BetResponse {
  quiero('QUIERO'),
  noQuiero('NO_QUIERO'),
  conFlorMeAchico('CON_FLOR_ME_ACHICO');

  final String wire;
  const BetResponse(this.wire);

  static BetResponse fromWire(String w) => BetResponse.values.firstWhere(
      (b) => b.wire == w,
      orElse: () => throw FormatException('Respuesta inválida: $w'));
}

/// Acción de un jugador sobre la mano en curso.
sealed class GameAction {
  const GameAction();

  /// Representación para el protocolo WebSocket (ver docs/ARQUITECTURA.md).
  Map<String, dynamic> toJson();

  static GameAction fromJson(Map<String, dynamic> j) {
    switch (j['type']) {
      case 'PLAY_CARD':
        return PlayCardAction(TrucoCard.fromId(j['cardId'] as String));
      case 'CALL_BET':
        return CallAction(BetCall.fromWire(j['betType'] as String));
      case 'RESPOND_BET':
        return RespondAction(BetResponse.fromWire(j['response'] as String));
      case 'FOLD_HAND':
        return const FoldAction();
      default:
        throw FormatException('Acción desconocida: ${j['type']}');
    }
  }
}

final class PlayCardAction extends GameAction {
  final TrucoCard card;
  const PlayCardAction(this.card);

  @override
  Map<String, dynamic> toJson() => {'type': 'PLAY_CARD', 'cardId': card.id};

  @override
  bool operator ==(Object o) => o is PlayCardAction && o.card == card;
  @override
  int get hashCode => Object.hash('play', card);
  @override
  String toString() => 'Jugar $card';
}

final class CallAction extends GameAction {
  final BetCall bet;
  const CallAction(this.bet);

  @override
  Map<String, dynamic> toJson() => {'type': 'CALL_BET', 'betType': bet.wire};

  @override
  bool operator ==(Object o) => o is CallAction && o.bet == bet;
  @override
  int get hashCode => Object.hash('call', bet);
  @override
  String toString() => 'Cantar ${bet.wire}';
}

final class RespondAction extends GameAction {
  final BetResponse response;
  const RespondAction(this.response);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'RESPOND_BET', 'response': response.wire};

  @override
  bool operator ==(Object o) => o is RespondAction && o.response == response;
  @override
  int get hashCode => Object.hash('respond', response);
  @override
  String toString() => 'Responder ${response.wire}';
}

/// Irse al mazo.
final class FoldAction extends GameAction {
  const FoldAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'FOLD_HAND'};

  @override
  bool operator ==(Object o) => o is FoldAction;
  @override
  int get hashCode => 'fold'.hashCode;
  @override
  String toString() => 'Irse al mazo';
}

/// Se lanza cuando un jugador intenta una acción que no es reglamentaria.
class IllegalActionException implements Exception {
  final String message;
  const IllegalActionException(this.message);
  @override
  String toString() => 'IllegalActionException: $message';
}
