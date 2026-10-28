import '../models/card.dart';
import '../models/sample.dart';
import '../models/seat.dart';
import '../rules/envido_chain.dart';
import 'actions.dart';
import 'hand.dart';

/// Vista **filtrada** de la mano para un jugador (RNF-SEG-01, Zero-Trust).
///
/// Contiene únicamente lo que ese jugador tiene derecho a saber: sus propias
/// cartas, la Muestra, lo ya jugado en la mesa y el estado público de los
/// cantos. Es lo que el servidor serializa hacia el cliente (HAND_DEALT y
/// RECONNECT_SNAPSHOT) y lo que usa el bot para decidir.
class HandView {
  final Seat me;
  final Seat mano;
  final Sample sample;
  final List<TrucoCard> myCards;
  final List<TrucoCard> myDealtCards;
  final int opponentCardsLeft;
  final List<PlayedRound> table;
  final int scoreA;
  final int scoreB;
  final int targetPoints;
  final int trucoLevel;
  final BetCall? pendingTruco;
  final Seat? pendingTrucoCaller;
  final List<EnvidoStep> envidoSteps;
  final bool envidoPending;
  final FlorStage florStage;
  final Seat? toAct;
  final bool finished;
  final Seat? matchWinner;
  final bool iHaveFlor;
  final int myEnvidoPoints;
  final int myFlorPoints;
  final Seat? raiseOwner;

  /// Acciones disponibles para [me] en este instante (vacío si no le toca).
  final List<GameAction> legalActions;

  const HandView({
    required this.me,
    required this.mano,
    required this.sample,
    required this.myCards,
    required this.myDealtCards,
    required this.opponentCardsLeft,
    required this.table,
    required this.scoreA,
    required this.scoreB,
    required this.targetPoints,
    required this.trucoLevel,
    required this.pendingTruco,
    required this.pendingTrucoCaller,
    required this.envidoSteps,
    required this.envidoPending,
    required this.florStage,
    required this.toAct,
    required this.finished,
    required this.matchWinner,
    required this.iHaveFlor,
    required this.myEnvidoPoints,
    required this.myFlorPoints,
    required this.raiseOwner,
    required this.legalActions,
  });

  factory HandView.of(TrucoHand h, Seat me) => HandView(
        me: me,
        mano: h.mano,
        sample: h.sample,
        myCards: h.cardsOf(me),
        myDealtCards: h.dealtCardsOf(me),
        opponentCardsLeft: h.cardsOf(me.other).length,
        table: h.rounds,
        scoreA: h.scoreA,
        scoreB: h.scoreB,
        targetPoints: h.config.targetPoints,
        trucoLevel: h.trucoLevel,
        pendingTruco: h.pendingTruco,
        pendingTrucoCaller: h.pendingTrucoCaller,
        envidoSteps: h.envidoChain.steps,
        envidoPending: h.envidoPending,
        florStage: h.florStage,
        toAct: h.toAct,
        finished: h.isFinished,
        matchWinner: h.matchWinner,
        iHaveFlor: h.config.withFlor && h.hasFlor(me),
        myEnvidoPoints: h.envidoPointsOf(me),
        myFlorPoints: h.florPointsOf(me),
        raiseOwner: h.raiseOwner,
        legalActions: h.legalActions(me),
      );

  int scoreOf(Seat s) => s == Seat.a ? scoreA : scoreB;
  bool get isMyTurn => toAct == me;

  /// Cartas que el rival ya jugó en la mesa.
  List<TrucoCard> get opponentPlayed => [
        for (final r in table)
          if (r.cardOf(me.other) != null) r.cardOf(me.other)!
      ];

  Map<String, dynamic> toJson() => {
        'me': me.name,
        'mano': mano.name,
        'sampleCard': sample.toJson(),
        'myCards': [for (final c in myCards) c.id],
        'opponentCardsLeft': opponentCardsLeft,
        'table': [for (final r in table) r.toJson()],
        'scoreA': scoreA,
        'scoreB': scoreB,
        'targetPoints': targetPoints,
        'trucoLevel': trucoLevel,
        'pendingTruco': pendingTruco?.wire,
        'pendingTrucoCaller': pendingTrucoCaller?.name,
        'envido': [for (final s in envidoSteps) s.toJson()],
        'envidoPending': envidoPending,
        'florStage': florStage.name,
        'toAct': toAct?.name,
        'finished': finished,
        'matchWinner': matchWinner?.name,
        'iHaveFlor': iHaveFlor,
        'legalActions': [for (final a in legalActions) a.toJson()],
      };
}
