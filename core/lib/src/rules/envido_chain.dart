import '../game/actions.dart' show BetCall;
import '../models/seat.dart';

/// Cadena de cantos de Envido en disputa (Envido, Envido-Envido, Real, Falta).
///
/// Es una estructura de valor: cada canto devuelve una cadena nueva.
class EnvidoChain {
  /// Cantos en orden, con el asiento que los realizó.
  final List<EnvidoStep> steps;

  const EnvidoChain._(this.steps);

  static const empty = EnvidoChain._([]);

  bool get isEmpty => steps.isEmpty;

  EnvidoStep get last => steps.last;

  bool get hasFalta => steps.any((s) => s.bet == BetCall.faltaEnvido);

  int get envidoCount => steps.where((s) => s.bet == BetCall.envido).length;

  /// Cantos que pueden realizarse a continuación del estado actual.
  Set<BetCall> get allowedNext {
    if (steps.isEmpty) {
      return {BetCall.envido, BetCall.realEnvido, BetCall.faltaEnvido};
    }
    switch (last.bet) {
      case BetCall.envido:
        return envidoCount >= 2
            ? {BetCall.realEnvido, BetCall.faltaEnvido}
            : {BetCall.envido, BetCall.realEnvido, BetCall.faltaEnvido};
      case BetCall.realEnvido:
        return {BetCall.faltaEnvido};
      default:
        return {};
    }
  }

  EnvidoChain add(Seat who, BetCall bet) {
    if (!allowedNext.contains(bet)) {
      throw StateError('Canto $bet no permitido tras ${steps.map((s) => s.bet)}');
    }
    return EnvidoChain._([...steps, EnvidoStep(who, bet)]);
  }

  static int _value(BetCall b) => b == BetCall.envido ? 2 : 3;

  /// Puntos que se llevan si el último canto es aceptado ("Quiero").
  /// [faltaPoints] es lo que vale la Falta Envido en el marcador actual.
  int pointsIfAccepted(int faltaPoints) {
    if (hasFalta) return faltaPoints;
    return steps.fold(0, (a, s) => a + _value(s.bet));
  }

  /// Puntos para quien cantó el último envite si se responde "No Quiero":
  /// 1 si fue el canto inicial; si no, lo acumulado antes del último revire.
  int get pointsIfRejected {
    if (steps.length <= 1) return 1;
    return steps
        .sublist(0, steps.length - 1)
        .fold(0, (a, s) => a + _value(s.bet));
  }

  /// Falta Envido: puntos que le faltan al puntero para terminar las malas
  /// (si ambos están en las malas) o para ganar la partida (si no).
  static int faltaEnvidoPoints({
    required int scoreA,
    required int scoreB,
    required int targetPoints,
  }) {
    final leader = scoreA > scoreB ? scoreA : scoreB;
    final malas = targetPoints ~/ 2;
    return leader < malas ? malas - leader : targetPoints - leader;
  }

  List<Map<String, dynamic>> toJson() => [for (final s in steps) s.toJson()];

  factory EnvidoChain.fromJson(List<dynamic> j) => EnvidoChain._([
        for (final e in j) EnvidoStep.fromJson(e as Map<String, dynamic>)
      ]);
}

class EnvidoStep {
  final Seat seat;
  final BetCall bet;
  const EnvidoStep(this.seat, this.bet);

  Map<String, dynamic> toJson() => {'seat': seat.name, 'bet': bet.wire};

  factory EnvidoStep.fromJson(Map<String, dynamic> j) =>
      EnvidoStep(Seat.fromName(j['seat'] as String), BetCall.fromWire(j['bet'] as String));
}
