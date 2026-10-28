import '../models/card.dart';
import '../models/sample.dart';
import '../models/seat.dart';
import '../rules/envido_calculator.dart';
import '../rules/envido_chain.dart';
import '../rules/flor_calculator.dart';
import '../rules/round_resolver.dart';
import '../rules/rules_config.dart';
import 'actions.dart';
import 'events.dart';

/// Etapa de la disputa de Flor.
enum FlorStage {
  /// Nadie disputa la flor (o ya quedó resuelta).
  none,

  /// Un jugador cantó Flor y el rival, que también tiene, debe responder.
  awaitingResponse,

  /// Se cantó Contraflor y el que cantó la Flor debe aceptarla o achicarse.
  contraflorPending,
}

/// Registro público de una ronda (baza) jugada en la mesa.
class PlayedRound {
  final int number;
  final Seat firstSeat;
  final TrucoCard firstCard;
  final TrucoCard? secondCard;
  final RoundWinner? result;

  const PlayedRound({
    required this.number,
    required this.firstSeat,
    required this.firstCard,
    this.secondCard,
    this.result,
  });

  TrucoCard? cardOf(Seat s) => s == firstSeat ? firstCard : secondCard;

  Map<String, dynamic> toJson() => {
        'number': number,
        'firstSeat': firstSeat.name,
        'firstCard': firstCard.id,
        'secondCard': secondCard?.id,
        'result': result?.name,
      };

  factory PlayedRound.fromJson(Map<String, dynamic> j) => PlayedRound(
        number: j['number'] as int,
        firstSeat: Seat.fromName(j['firstSeat'] as String),
        firstCard: TrucoCard.fromId(j['firstCard'] as String),
        secondCard: j['secondCard'] == null
            ? null
            : TrucoCard.fromId(j['secondCard'] as String),
        result: j['result'] == null
            ? null
            : RoundWinner.values.byName(j['result'] as String),
      );
}

/// Máquina de estados de **una mano** de Truco Uruguayo 1 vs 1.
///
/// Es el único lugar donde se aplican las reglas dinámicas (turnos, cantos,
/// respuestas, pardas y puntaje) y se ejecuta idéntica en el cliente (offline)
/// y en el servidor autoritativo. No hace E/S ni usa relojes: los timeouts los
/// gestiona quien la usa mediante [timeoutAction].
///
/// Uso: consultar [legalActions] y aplicar con [apply]. Cada `apply` devuelve
/// los [GameEvent] públicos producidos.
class TrucoHand {
  final RulesConfig config;
  final Seat mano;
  final Sample sample;
  final int startScoreA;
  final int startScoreB;
  final String? deckCommitment;

  final Map<Seat, List<TrucoCard>> _dealt;
  final Map<Seat, List<TrucoCard>> _remaining;
  final Map<Seat, FlorEvaluation> _flor;
  final Map<Seat, int> _envidoPts;

  // Rondas
  final List<PlayedRound> _rounds = [];
  final List<RoundWinner> _results = [];
  Seat _turn;
  Seat? _toAct;

  // Truco
  int _trucoLevel = 0; // 0 = sin truco; 2, 3 o 4 = nivel aceptado
  Seat? _raiseOwner;
  BetCall? _pendingTruco;
  Seat? _pendingTrucoCaller;

  // Envido
  EnvidoChain _envido = EnvidoChain.empty;
  bool _envidoClosed = false;

  // Flor
  final Set<Seat> _florCalledBy = {};
  FlorStage _florStage = FlorStage.none;
  Seat? _florCaller;
  Seat? _contraflorCaller;
  bool _florResolved = false;

  // Puntos de esta mano
  int _awardedA = 0;
  int _awardedB = 0;
  Seat? _matchWinner;

  bool _finished = false;
  Seat? _handWinner;
  final List<GameEvent> _log = [];

  TrucoHand._({
    required this.config,
    required this.mano,
    required this.sample,
    required this.startScoreA,
    required this.startScoreB,
    required this.deckCommitment,
    required Map<Seat, List<TrucoCard>> dealt,
  })  : _dealt = {for (final e in dealt.entries) e.key: List.unmodifiable(e.value)},
        _remaining = {for (final e in dealt.entries) e.key: List.of(e.value)},
        _flor = {
          for (final e in dealt.entries)
            e.key: config.withFlor
                ? FlorCalculator.evaluate(e.value, sample)
                : FlorEvaluation.noFlor,
        },
        _envidoPts = {
          for (final e in dealt.entries)
            e.key: EnvidoCalculator.calculate(e.value, sample),
        },
        _turn = mano {
    _toAct = mano;
  }

  /// Inicia una mano repartida. [cardsA]/[cardsB] deben ser 3 cartas distintas
  /// y la [sample] no puede estar entre ellas.
  factory TrucoHand.start({
    required Seat mano,
    required List<TrucoCard> cardsA,
    required List<TrucoCard> cardsB,
    required Sample sample,
    int scoreA = 0,
    int scoreB = 0,
    RulesConfig config = const RulesConfig(),
    String? deckCommitment,
  }) {
    final all = [...cardsA, ...cardsB, sample.card];
    if (cardsA.length != 3 || cardsB.length != 3) {
      throw ArgumentError('Cada jugador debe recibir exactamente 3 cartas');
    }
    if (all.toSet().length != 7) {
      throw ArgumentError('Las cartas repartidas deben ser distintas');
    }
    final hand = TrucoHand._(
      config: config,
      mano: mano,
      sample: sample,
      startScoreA: scoreA,
      startScoreB: scoreB,
      deckCommitment: deckCommitment,
      dealt: {Seat.a: cardsA, Seat.b: cardsB},
    );
    hand._log.add(HandStartedEvent(
      mano: mano,
      sample: sample,
      scoreA: scoreA,
      scoreB: scoreB,
      deckCommitment: deckCommitment,
    ));
    return hand;
  }

  // ---------------------------------------------------------------------------
  // Consultas públicas
  // ---------------------------------------------------------------------------

  bool get isFinished => _finished;

  /// Ganador de la mano por rondas, o `null` si terminó por puntos de la
  /// partida antes de resolverse las rondas.
  Seat? get handWinner => _handWinner;

  /// Ganador de la partida si esta mano la decidió.
  Seat? get matchWinner => _matchWinner;

  /// Jugador que debe actuar ahora (jugar carta, cantar o responder).
  Seat? get toAct => _toAct;

  /// Jugador al que le toca tirar la próxima carta.
  Seat get turn => _turn;

  int get currentRound => _rounds.length +
      (_rounds.isNotEmpty && _rounds.last.result == null ? 0 : 1);

  List<PlayedRound> get rounds => List.unmodifiable(_rounds);
  List<RoundWinner> get roundResults => List.unmodifiable(_results);

  /// Nivel de truco aceptado: 0 sin truco, 2 Truco, 3 Retruco, 4 Vale Cuatro.
  int get trucoLevel => _trucoLevel;
  BetCall? get pendingTruco => _pendingTruco;
  Seat? get pendingTrucoCaller => _pendingTrucoCaller;
  Seat? get raiseOwner => _raiseOwner;

  EnvidoChain get envidoChain => _envido;
  bool get envidoPending => !_envidoClosed && !_envido.isEmpty;
  bool get envidoClosed => _envidoClosed;

  FlorStage get florStage => _florStage;
  Set<Seat> get florCalledBy => Set.unmodifiable(_florCalledBy);

  int get awardedA => _awardedA;
  int get awardedB => _awardedB;
  int get scoreA => _clamp(startScoreA + _awardedA);
  int get scoreB => _clamp(startScoreB + _awardedB);
  int scoreOf(Seat s) => s == Seat.a ? scoreA : scoreB;

  List<GameEvent> get log => List.unmodifiable(_log);

  /// Cartas que el jugador aún tiene en la mano.
  List<TrucoCard> cardsOf(Seat s) => List.unmodifiable(_remaining[s]!);

  /// Las 3 cartas repartidas originalmente (sólo para el servidor o el dueño).
  List<TrucoCard> dealtCardsOf(Seat s) => _dealt[s]!;

  bool hasFlor(Seat s) => _flor[s]!.hasFlor;
  int florPointsOf(Seat s) => _flor[s]!.score;
  int envidoPointsOf(Seat s) => _envidoPts[s]!;

  /// Cuántas cartas ya jugó el jugador.
  int cardsPlayedBy(Seat s) => 3 - _remaining[s]!.length;

  int _clamp(int v) => v > config.targetPoints ? config.targetPoints : v;

  // ---------------------------------------------------------------------------
  // Acciones legales
  // ---------------------------------------------------------------------------

  bool _florAvailable(Seat s) =>
      config.withFlor && _flor[s]!.hasFlor && !_florCalledBy.contains(s);

  bool _canCallEnvido(Seat s, {required bool inResponse}) {
    if (currentRound != 1 || _envidoClosed) return false;
    if (_florCalledBy.isNotEmpty) return false;
    if (_florAvailable(s)) return false; // con flor no se canta envido
    if (_trucoLevel != 0) return false; // truco ya aceptado
    if (!inResponse && cardsPlayedBy(s) > 0) return false; // preclusión
    return true;
  }

  bool _canCallFlor(Seat s, {required bool inResponse}) {
    if (currentRound != 1 || _florResolved) return false;
    if (!_florAvailable(s)) return false;
    if (!inResponse && cardsPlayedBy(s) > 0) return false; // preclusión
    return true;
  }

  BetCall? _nextTrucoFor(Seat s) {
    if (_pendingTruco != null) return null;
    if (_trucoLevel == 0) return BetCall.truco;
    if (_raiseOwner == s) {
      if (_trucoLevel == 2) return BetCall.retruco;
      if (_trucoLevel == 3) return BetCall.valeCuatro;
    }
    return null;
  }

  /// Acciones que [seat] puede realizar ahora. Vacío si no le corresponde actuar.
  List<GameAction> legalActions(Seat seat) {
    if (_finished || seat != _toAct) return const [];

    if (_florStage == FlorStage.awaitingResponse) {
      return const [CallAction(BetCall.flor), CallAction(BetCall.contraflor)];
    }
    if (_florStage == FlorStage.contraflorPending) {
      return const [
        RespondAction(BetResponse.quiero),
        RespondAction(BetResponse.conFlorMeAchico),
      ];
    }

    if (envidoPending) {
      if (_florAvailable(seat)) return const [CallAction(BetCall.flor)];
      return [
        const RespondAction(BetResponse.quiero),
        const RespondAction(BetResponse.noQuiero),
        for (final b in _envido.allowedNext) CallAction(b),
      ];
    }

    if (_pendingTruco != null) {
      final raise = _pendingTruco == BetCall.truco
          ? BetCall.retruco
          : _pendingTruco == BetCall.retruco
              ? BetCall.valeCuatro
              : null;
      return [
        const RespondAction(BetResponse.quiero),
        const RespondAction(BetResponse.noQuiero),
        if (raise != null) CallAction(raise),
        // "El envido está primero" / flor antes de responder el truco.
        if (_canCallFlor(seat, inResponse: true)) const CallAction(BetCall.flor),
        if (_canCallEnvido(seat, inResponse: true))
          for (final b in EnvidoChain.empty.allowedNext) CallAction(b),
      ];
    }

    // Turno normal: tirar carta, cantar o irse al mazo.
    final truco = _nextTrucoFor(seat);
    return [
      for (final c in _remaining[seat]!) PlayCardAction(c),
      if (_canCallFlor(seat, inResponse: false)) const CallAction(BetCall.flor),
      if (_canCallEnvido(seat, inResponse: false))
        for (final b in EnvidoChain.empty.allowedNext) CallAction(b),
      if (truco != null) CallAction(truco),
      const FoldAction(),
    ];
  }

  /// Acción automática cuando expira el tiempo del jugador que debe actuar
  /// (RNF-DIS-03): responder "No Quiero" o tirar la carta de menor valor.
  GameAction? timeoutAction() {
    final seat = _toAct;
    if (_finished || seat == null) return null;
    final legal = legalActions(seat);
    if (_florStage == FlorStage.awaitingResponse) {
      return const CallAction(BetCall.flor);
    }
    for (final pref in const [
      RespondAction(BetResponse.noQuiero),
      RespondAction(BetResponse.conFlorMeAchico),
    ]) {
      if (legal.contains(pref)) return pref;
    }
    if (legal.length == 1) return legal.first;
    final cards = _remaining[seat]!.toList()
      ..sort((x, y) => sample
          .classify(x)
          .trickPower
          .compareTo(sample.classify(y).trickPower));
    return PlayCardAction(cards.first);
  }

  // ---------------------------------------------------------------------------
  // Aplicación de acciones
  // ---------------------------------------------------------------------------

  /// Aplica la [action] del jugador [seat]. Lanza [IllegalActionException] si no
  /// es reglamentaria. Devuelve los eventos públicos generados.
  List<GameEvent> apply(Seat seat, GameAction action) {
    if (_finished) {
      throw const IllegalActionException('La mano ya terminó');
    }
    if (seat != _toAct) {
      throw IllegalActionException('No es el turno de ${seat.name}');
    }
    if (!legalActions(seat).contains(action)) {
      throw IllegalActionException('Acción no permitida: $action');
    }
    final ev = <GameEvent>[];
    switch (action) {
      case PlayCardAction(:final card):
        _playCard(seat, card, ev);
      case CallAction(:final bet):
        ev.add(BetCalledEvent(seat, bet));
        _call(seat, bet, ev);
      case RespondAction(:final response):
        ev.add(BetRespondedEvent(seat, response));
        _respond(seat, response, ev);
      case FoldAction():
        _fold(seat, ev);
    }
    if (_matchWinner != null && !_finished) {
      _endHand(ev, handWinner: null);
    }
    _log.addAll(ev);
    return ev;
  }

  void _award(Seat seat, int pts, PointsReason reason, List<GameEvent> ev) {
    if (pts <= 0) return;
    if (seat == Seat.a) {
      _awardedA += pts;
    } else {
      _awardedB += pts;
    }
    ev.add(PointsAwardedEvent(seat, pts, reason));
    final raw = seat == Seat.a ? startScoreA + _awardedA : startScoreB + _awardedB;
    if (raw >= config.targetPoints && _matchWinner == null) {
      _matchWinner = seat;
    }
  }

  void _endHand(List<GameEvent> ev, {required Seat? handWinner}) {
    _finished = true;
    _handWinner = handWinner;
    _toAct = null;
    ev.add(HandFinishedEvent(winner: handWinner, scoreA: scoreA, scoreB: scoreB));
    if (_matchWinner != null) ev.add(MatchFinishedEvent(_matchWinner!));
  }

  void _afterBetResolved() {
    _toAct = _pendingTruco != null ? _pendingTrucoCaller!.other : _turn;
  }

  void _playCard(Seat seat, TrucoCard card, List<GameEvent> ev) {
    _remaining[seat]!.remove(card);
    final number = _rounds.length + (_rounds.isNotEmpty && _rounds.last.result == null ? 0 : 1);
    ev.add(CardPlayedEvent(seat, card, number));

    // Primera carta de la ronda.
    if (_rounds.isEmpty || _rounds.last.result != null) {
      _rounds.add(PlayedRound(number: number, firstSeat: seat, firstCard: card));
      _turn = seat.other;
      _toAct = _turn;
      return;
    }

    // Segunda carta: se resuelve la ronda.
    final first = _rounds.last;
    final cardA = seat == Seat.a ? card : first.firstCard;
    final cardB = seat == Seat.b ? card : first.firstCard;
    final result = RoundResolver.compareCards(cardA: cardA, cardB: cardB, sample: sample);
    _rounds[_rounds.length - 1] = PlayedRound(
      number: first.number,
      firstSeat: first.firstSeat,
      firstCard: first.firstCard,
      secondCard: card,
      result: result,
    );
    _results.add(result);
    ev.add(RoundResolvedEvent(first.number, result));

    final verdict = RoundResolver.evaluateHandWinner(
      rounds: _results,
      isManoBandoA: mano == Seat.a,
    );
    if (verdict != null) {
      final winner = verdict == HandWinner.bandoA ? Seat.a : Seat.b;
      _award(winner, _trucoLevel > 0 ? _trucoLevel : 1, PointsReason.manoGanada, ev);
      _endHand(ev, handWinner: winner);
      return;
    }
    // Abre la próxima ronda quien ganó la anterior; si hubo parda, quien tiró
    // primero en la ronda empatada.
    _turn = switch (result) {
      RoundWinner.bandoA => Seat.a,
      RoundWinner.bandoB => Seat.b,
      RoundWinner.parda => first.firstSeat,
    };
    _toAct = _turn;
  }

  void _call(Seat seat, BetCall bet, List<GameEvent> ev) {
    final opp = seat.other;
    if (bet.isEnvido) {
      _envido = _envido.add(seat, bet);
      _toAct = opp;
      return;
    }
    if (bet.isTruco) {
      _pendingTruco = bet;
      _pendingTrucoCaller = seat;
      _toAct = opp;
      return;
    }
    // Flor / Contraflor
    if (bet == BetCall.contraflor) {
      _florStage = FlorStage.contraflorPending;
      _contraflorCaller = seat;
      _toAct = _florCaller; // debe responder quien cantó la Flor
      return;
    }
    // bet == flor
    if (_florStage == FlorStage.awaitingResponse) {
      // El rival también tiene flor y se limita a reconocerla: ambos cobran 3.
      _florCalledBy.add(seat);
      _florStage = FlorStage.none;
      _florResolved = true;
      _award(_florCaller!, 3, PointsReason.florAmbas, ev);
      _award(seat, 3, PointsReason.florAmbas, ev);
      _afterBetResolved();
      return;
    }
    _florCalledBy.add(seat);
    _florCaller = seat;
    if (envidoPending) {
      _envido = EnvidoChain.empty;
      ev.add(const EnvidoAnnulledEvent());
    }
    _envidoClosed = true; // con flor no hay envido
    if (_florAvailable(opp)) {
      _florStage = FlorStage.awaitingResponse;
      _toAct = opp;
    } else {
      _florResolved = true;
      _award(seat, 3, PointsReason.flor, ev);
      _afterBetResolved();
    }
  }

  void _respond(Seat seat, BetResponse response, List<GameEvent> ev) {
    if (_florStage == FlorStage.contraflorPending) {
      final challenger = _contraflorCaller!;
      _florStage = FlorStage.none;
      _florResolved = true;
      if (response == BetResponse.conFlorMeAchico) {
        _award(challenger, 4, PointsReason.conFlorMeAchico, ev);
      } else {
        final sa = _flor[Seat.a]!.score;
        final sb = _flor[Seat.b]!.score;
        final winner = sa > sb ? Seat.a : sb > sa ? Seat.b : mano;
        ev.add(FlorComparedEvent(winner: winner, scoreA: sa, scoreB: sb, pointsAwarded: 6));
        _award(winner, 6, PointsReason.contraflorQuerida, ev);
      }
      _afterBetResolved();
      return;
    }

    if (envidoPending) {
      final lastCaller = _envido.last.seat;
      _envidoClosed = true;
      if (response == BetResponse.noQuiero) {
        _award(lastCaller, _envido.pointsIfRejected, PointsReason.envidoNoQuerido, ev);
      } else {
        final falta = EnvidoChain.faltaEnvidoPoints(
          scoreA: scoreA,
          scoreB: scoreB,
          targetPoints: config.targetPoints,
        );
        final pts = _envido.pointsIfAccepted(falta);
        final pie = mano.other;
        final m = _envidoPts[mano]!;
        final p = _envidoPts[pie]!;
        final winner = p > m ? pie : mano; // empate: gana el mano
        ev.add(EnvidoResolvedEvent(
          winner: winner,
          manoPoints: m,
          piePoints: p >= m ? p : null,
          pointsAwarded: pts,
        ));
        _award(winner, pts, PointsReason.envidoQuerido, ev);
      }
      _afterBetResolved();
      return;
    }

    // Respuesta al truco pendiente.
    final level = switch (_pendingTruco!) {
      BetCall.truco => 2,
      BetCall.retruco => 3,
      _ => 4,
    };
    final caller = _pendingTrucoCaller!;
    _pendingTruco = null;
    _pendingTrucoCaller = null;
    if (response == BetResponse.noQuiero) {
      _award(caller, level - 1, PointsReason.trucoNoQuerido, ev);
      _endHand(ev, handWinner: caller);
    } else {
      _trucoLevel = level;
      _raiseOwner = seat; // quien quiere tiene derecho a subir
      _toAct = _turn;
    }
  }

  void _fold(Seat seat, List<GameEvent> ev) {
    final winner = seat.other;
    _award(winner, _trucoLevel > 0 ? _trucoLevel : 1, PointsReason.irseAlMazo, ev);
    _endHand(ev, handWinner: winner);
  }

  // ---------------------------------------------------------------------------
  // Serialización completa (sólo servidor: contiene todas las cartas)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'config': config.toJson(),
        'mano': mano.name,
        'sample': sample.card.id,
        'startScoreA': startScoreA,
        'startScoreB': startScoreB,
        'deckCommitment': deckCommitment,
        'dealtA': [for (final c in _dealt[Seat.a]!) c.id],
        'dealtB': [for (final c in _dealt[Seat.b]!) c.id],
        'remainingA': [for (final c in _remaining[Seat.a]!) c.id],
        'remainingB': [for (final c in _remaining[Seat.b]!) c.id],
        'rounds': [for (final r in _rounds) r.toJson()],
        'results': [for (final r in _results) r.name],
        'turn': _turn.name,
        'toAct': _toAct?.name,
        'trucoLevel': _trucoLevel,
        'raiseOwner': _raiseOwner?.name,
        'pendingTruco': _pendingTruco?.wire,
        'pendingTrucoCaller': _pendingTrucoCaller?.name,
        'envido': _envido.toJson(),
        'envidoClosed': _envidoClosed,
        'florCalledBy': [for (final s in _florCalledBy) s.name],
        'florStage': _florStage.name,
        'florCaller': _florCaller?.name,
        'contraflorCaller': _contraflorCaller?.name,
        'florResolved': _florResolved,
        'awardedA': _awardedA,
        'awardedB': _awardedB,
        'matchWinner': _matchWinner?.name,
        'finished': _finished,
        'handWinner': _handWinner?.name,
      };

  static Seat? _seatOrNull(dynamic v) => v == null ? null : Seat.fromName(v as String);

  static List<TrucoCard> _cards(dynamic l) =>
      [for (final id in l as List) TrucoCard.fromId(id as String)];

  /// Reconstruye una mano desde [toJson]. El historial de eventos ([log]) no se
  /// persiste; el servidor debe guardarlo aparte si lo necesita.
  factory TrucoHand.fromJson(Map<String, dynamic> j) {
    final h = TrucoHand._(
      config: RulesConfig.fromJson(j['config'] as Map<String, dynamic>),
      mano: Seat.fromName(j['mano'] as String),
      sample: Sample.fromId(j['sample'] as String),
      startScoreA: j['startScoreA'] as int,
      startScoreB: j['startScoreB'] as int,
      deckCommitment: j['deckCommitment'] as String?,
      dealt: {Seat.a: _cards(j['dealtA']), Seat.b: _cards(j['dealtB'])},
    );
    h._remaining[Seat.a] = _cards(j['remainingA']);
    h._remaining[Seat.b] = _cards(j['remainingB']);
    h._rounds.addAll([
      for (final r in j['rounds'] as List) PlayedRound.fromJson(r as Map<String, dynamic>)
    ]);
    h._results.addAll([
      for (final r in j['results'] as List) RoundWinner.values.byName(r as String)
    ]);
    h._turn = Seat.fromName(j['turn'] as String);
    h._toAct = _seatOrNull(j['toAct']);
    h._trucoLevel = j['trucoLevel'] as int;
    h._raiseOwner = _seatOrNull(j['raiseOwner']);
    h._pendingTruco =
        j['pendingTruco'] == null ? null : BetCall.fromWire(j['pendingTruco'] as String);
    h._pendingTrucoCaller = _seatOrNull(j['pendingTrucoCaller']);
    h._envido = EnvidoChain.fromJson(j['envido'] as List);
    h._envidoClosed = j['envidoClosed'] as bool;
    h._florCalledBy.addAll([
      for (final s in j['florCalledBy'] as List) Seat.fromName(s as String)
    ]);
    h._florStage = FlorStage.values.byName(j['florStage'] as String);
    h._florCaller = _seatOrNull(j['florCaller']);
    h._contraflorCaller = _seatOrNull(j['contraflorCaller']);
    h._florResolved = j['florResolved'] as bool;
    h._awardedA = j['awardedA'] as int;
    h._awardedB = j['awardedB'] as int;
    h._matchWinner = _seatOrNull(j['matchWinner']);
    h._finished = j['finished'] as bool;
    h._handWinner = _seatOrNull(j['handWinner']);
    return h;
  }
}
