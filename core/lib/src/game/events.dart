import '../models/card.dart';
import '../models/sample.dart';
import '../models/seat.dart';
import '../rules/round_resolver.dart';
import 'actions.dart';

/// Motivo por el que se otorgan puntos.
enum PointsReason {
  envidoQuerido('ENVIDO_QUERIDO'),
  envidoNoQuerido('ENVIDO_NO_QUERIDO'),
  flor('FLOR'),
  florAmbas('FLOR_AMBAS'),
  contraflorQuerida('CONTRAFLOR_QUERIDA'),
  conFlorMeAchico('CON_FLOR_ME_ACHICO'),
  trucoNoQuerido('TRUCO_NO_QUERIDO'),
  manoGanada('MANO_GANADA'),
  irseAlMazo('IRSE_AL_MAZO');

  final String wire;
  const PointsReason(this.wire);
}

/// Evento público de la mano. Todo lo que contiene lo pueden ver ambos
/// jugadores: nunca incluye cartas no jugadas ni puntos de envido/flor que no
/// hayan sido mostrados reglamentariamente.
sealed class GameEvent {
  const GameEvent();
  Map<String, dynamic> toJson();
}

final class HandStartedEvent extends GameEvent {
  final Seat mano;
  final Sample sample;
  final int scoreA;
  final int scoreB;

  /// Compromiso SHA-256 de la semilla del mazo (puede ser null en modo offline).
  final String? deckCommitment;
  const HandStartedEvent({
    required this.mano,
    required this.sample,
    required this.scoreA,
    required this.scoreB,
    this.deckCommitment,
  });
  @override
  Map<String, dynamic> toJson() => {
        'type': 'HAND_STARTED',
        'mano': mano.name,
        'sampleCard': sample.toJson(),
        'scoreA': scoreA,
        'scoreB': scoreB,
        if (deckCommitment != null) 'deckCommitment': deckCommitment,
      };
}

final class CardPlayedEvent extends GameEvent {
  final Seat seat;
  final TrucoCard card;
  final int round; // 1..3
  const CardPlayedEvent(this.seat, this.card, this.round);
  @override
  Map<String, dynamic> toJson() => {
        'type': 'CARD_PLAYED',
        'playerId': seat.name,
        'card': card.toJson(),
        'round': round,
      };
}

final class BetCalledEvent extends GameEvent {
  final Seat seat;
  final BetCall bet;
  const BetCalledEvent(this.seat, this.bet);
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'BET_CALLED', 'playerId': seat.name, 'betType': bet.wire};
}

final class BetRespondedEvent extends GameEvent {
  final Seat seat;
  final BetResponse response;
  const BetRespondedEvent(this.seat, this.response);
  @override
  Map<String, dynamic> toJson() => {
        'type': 'BET_RESPONDED',
        'playerId': seat.name,
        'response': response.wire,
      };
}

/// El envido pendiente quedó sin efecto porque se cantó Flor.
final class EnvidoAnnulledEvent extends GameEvent {
  const EnvidoAnnulledEvent();
  @override
  Map<String, dynamic> toJson() => {'type': 'ENVIDO_ANNULLED'};
}

/// Envido querido y resuelto. El mano declara siempre su tanto; el pie sólo
/// lo muestra si iguala o supera ("son buenas" en caso contrario).
final class EnvidoResolvedEvent extends GameEvent {
  final Seat winner;
  final int manoPoints;
  final int? piePoints;
  final int pointsAwarded;
  const EnvidoResolvedEvent({
    required this.winner,
    required this.manoPoints,
    required this.piePoints,
    required this.pointsAwarded,
  });
  @override
  Map<String, dynamic> toJson() => {
        'type': 'ENVIDO_RESOLVED',
        'winner': winner.name,
        'manoPoints': manoPoints,
        'piePoints': piePoints,
        'pointsAwarded': pointsAwarded,
      };
}

/// Contraflor querida: se muestran ambas flores.
final class FlorComparedEvent extends GameEvent {
  final Seat winner;
  final int scoreA;
  final int scoreB;
  final int pointsAwarded;
  const FlorComparedEvent({
    required this.winner,
    required this.scoreA,
    required this.scoreB,
    required this.pointsAwarded,
  });
  @override
  Map<String, dynamic> toJson() => {
        'type': 'FLOR_COMPARED',
        'winner': winner.name,
        'scoreA': scoreA,
        'scoreB': scoreB,
        'pointsAwarded': pointsAwarded,
      };
}

final class PointsAwardedEvent extends GameEvent {
  final Seat seat;
  final int points;
  final PointsReason reason;
  const PointsAwardedEvent(this.seat, this.points, this.reason);
  @override
  Map<String, dynamic> toJson() => {
        'type': 'POINTS_AWARDED',
        'playerId': seat.name,
        'points': points,
        'reason': reason.wire,
      };
}

final class RoundResolvedEvent extends GameEvent {
  final int round;
  final RoundWinner winner;
  const RoundResolvedEvent(this.round, this.winner);
  @override
  Map<String, dynamic> toJson() => {
        'type': 'ROUND_RESOLVED',
        'round': round,
        'winnerPlayerId': switch (winner) {
          RoundWinner.bandoA => 'a',
          RoundWinner.bandoB => 'b',
          RoundWinner.parda => null,
        },
        'isTied': winner == RoundWinner.parda,
      };
}

final class HandFinishedEvent extends GameEvent {
  final Seat? winner; // quien se llevó la mano (null si terminó por puntos antes)
  final int scoreA;
  final int scoreB;
  const HandFinishedEvent({
    required this.winner,
    required this.scoreA,
    required this.scoreB,
  });
  @override
  Map<String, dynamic> toJson() => {
        'type': 'HAND_SCORED',
        'winnerPlayerId': winner?.name,
        'scoreA': scoreA,
        'scoreB': scoreB,
      };
}

final class MatchFinishedEvent extends GameEvent {
  final Seat winner;
  const MatchFinishedEvent(this.winner);
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'MATCH_FINISHED', 'winnerPlayerId': winner.name};
}
