import 'dart:math';

import '../game/actions.dart';
import '../game/hand.dart';
import '../game/view.dart';
import '../models/card.dart';

/// Bot de heurística básica para el modo offline y el relleno de partidas
/// (RF-MVP-08 y RF-MVP-10). Sólo mira su [HandView], por lo que no puede hacer
/// trampa: nunca ve las cartas del rival.
///
/// Siempre devuelve una acción presente en `view.legalActions`.
class HeuristicBot {
  final Random rng;

  /// 0.0 = nunca farolea; valores bajos recomendados (por defecto 0.08).
  final double bluffRate;

  HeuristicBot({Random? rng, this.bluffRate = 0.08}) : rng = rng ?? Random();

  int _power(HandView v, TrucoCard c) => v.sample.classify(c).trickPower;

  /// Cantidad de cartas "fuertes" (7 de Oro o superior) que aún conservo.
  int _strong(HandView v) => v.myCards.where((c) => _power(v, c) >= 35).length;

  int _myRoundWins(HandView v) => v.table
      .where((r) => r.result == v.me.asRoundWinner)
      .length;

  int _oppRoundWins(HandView v) => v.table
      .where((r) => r.result == v.me.other.asRoundWinner)
      .length;

  bool _can(HandView v, GameAction a) => v.legalActions.contains(a);

  /// Elige la acción a realizar. Lanza [StateError] si no es su turno.
  GameAction choose(HandView v) {
    final legal = v.legalActions;
    if (legal.isEmpty) throw StateError('No es el turno del bot');
    if (legal.length == 1) return legal.first;

    // --- Disputa de flor ---------------------------------------------------
    if (v.florStage == FlorStage.awaitingResponse) {
      return v.myFlorPoints >= 35 && _can(v, const CallAction(BetCall.contraflor))
          ? const CallAction(BetCall.contraflor)
          : const CallAction(BetCall.flor);
    }
    if (v.florStage == FlorStage.contraflorPending) {
      return v.myFlorPoints >= 31
          ? const RespondAction(BetResponse.quiero)
          : const RespondAction(BetResponse.conFlorMeAchico);
    }

    // --- Envido pendiente ----------------------------------------------------
    if (v.envidoPending) {
      if (_can(v, const CallAction(BetCall.flor))) {
        return const CallAction(BetCall.flor);
      }
      final pts = v.myEnvidoPoints;
      if (pts >= 33 && _can(v, const CallAction(BetCall.realEnvido))) {
        return const CallAction(BetCall.realEnvido);
      }
      if (pts >= 27 || (pts >= 24 && rng.nextDouble() < 0.3)) {
        return const RespondAction(BetResponse.quiero);
      }
      return const RespondAction(BetResponse.noQuiero);
    }

    // --- Truco pendiente -----------------------------------------------------
    if (v.pendingTruco != null) {
      // "El envido está primero" con buen tanto.
      if (v.iHaveFlor && _can(v, const CallAction(BetCall.flor))) {
        return const CallAction(BetCall.flor);
      }
      if (v.myEnvidoPoints >= 29 && _can(v, const CallAction(BetCall.envido))) {
        return const CallAction(BetCall.envido);
      }
      final strong = _strong(v);
      final ahead = _myRoundWins(v) > _oppRoundWins(v);
      final level = switch (v.pendingTruco!) {
        BetCall.truco => 2,
        BetCall.retruco => 3,
        _ => 4,
      };
      final threshold = level; // más caro -> pide más fuerza
      final score = strong * 2 + (ahead ? 2 : 0) + (v.myCards.length >= 2 ? 1 : 0);
      if (score >= threshold + 2) {
        final raise = level == 2
            ? const CallAction(BetCall.retruco)
            : const CallAction(BetCall.valeCuatro);
        if (score >= threshold + 4 && level < 4 && _can(v, raise)) return raise;
      }
      if (score >= threshold || rng.nextDouble() < bluffRate) {
        return const RespondAction(BetResponse.quiero);
      }
      return const RespondAction(BetResponse.noQuiero);
    }

    // --- Turno normal ----------------------------------------------------------
    if (_can(v, const CallAction(BetCall.flor))) {
      return const CallAction(BetCall.flor);
    }
    final pts = v.myEnvidoPoints;
    if (_can(v, const CallAction(BetCall.envido)) &&
        (pts >= 28 || rng.nextDouble() < bluffRate)) {
      if (pts >= 32 && _can(v, const CallAction(BetCall.realEnvido))) {
        return const CallAction(BetCall.realEnvido);
      }
      return const CallAction(BetCall.envido);
    }
    final strong = _strong(v);
    for (final t in const [
      BetCall.truco,
      BetCall.retruco,
      BetCall.valeCuatro,
    ]) {
      if (_can(v, CallAction(t))) {
        final need = switch (t) { BetCall.truco => 2, BetCall.retruco => 2, _ => 3 };
        if (strong >= need || (_myRoundWins(v) > 0 && strong >= 1)) {
          return CallAction(t);
        }
        if (rng.nextDouble() < bluffRate / 2) return CallAction(t);
      }
    }
    return _chooseCard(v);
  }

  PlayCardAction _chooseCard(HandView v) {
    final cards = [...v.myCards]
      ..sort((a, b) => _power(v, a).compareTo(_power(v, b)));
    final oppCard = _opponentCardThisRound(v);
    if (oppCard != null) {
      final oppPower = _power(v, oppCard);
      // Gana con la carta más baja que alcance; si no alcanza, tira la peor.
      for (final c in cards) {
        if (_power(v, c) > oppPower) return PlayCardAction(c);
      }
      return PlayCardAction(cards.first);
    }
    // Abre la ronda: carta intermedia en general, la mejor si ya perdió una.
    if (_oppRoundWins(v) > 0) return PlayCardAction(cards.last);
    return PlayCardAction(cards[cards.length ~/ 2]);
  }

  TrucoCard? _opponentCardThisRound(HandView v) {
    if (v.table.isEmpty) return null;
    final last = v.table.last;
    if (last.result != null) return null;
    return last.firstSeat == v.me.other ? last.firstCard : null;
  }
}
