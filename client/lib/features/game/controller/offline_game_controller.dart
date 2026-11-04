import 'dart:async';
import 'dart:math';

import 'package:truco_core/truco_core.dart';

import '../text/game_texts.dart';
import 'game_controller.dart';
import 'speech_bubbles.dart';

/// Partida local contra el bot: ejecuta `truco_core` en el dispositivo.
///
/// El jugador local es siempre [Seat.a]; el bot es [Seat.b].
class OfflineGameController extends GameController {
  OfflineGameController({
    HeuristicBot? bot,
    TrucoMatch Function()? matchFactory,
    this.botDelayMs = 900,
    this.roundShowMs = 900,
    this.roundCollectMs = 400,
  }) : _bot = bot ?? HeuristicBot(),
       _matchFactory = matchFactory ?? (() => TrucoMatch()) {
    _bubbles = SpeechBubbleQueue(onChanged: _notify);
    startNewMatch();
  }

  /// Espera antes de que el bot juegue (sensación de "pensar").
  final int botDelayMs;

  /// Tiempo que se ven las dos cartas de una ronda resuelta antes de recogerlas.
  final int roundShowMs;

  /// Duración de la animación con la que las cartas viajan al mazo.
  final int roundCollectMs;

  final HeuristicBot _bot;
  final TrucoMatch Function() _matchFactory;
  final Random _rng = Random();
  late final SpeechBubbleQueue _bubbles;
  late TrucoMatch _match;

  bool _isBotThinking = false;
  bool _disposed = false;
  String _statusMessage = '¡Bienvenido al Truco Uruguayo!';
  Timer? _botTimer;
  Timer? _collectTimer;
  RoundCollectPhase _roundPhase = RoundCollectPhase.none;
  int _collectedRounds = 0;

  static const Seat _me = Seat.a;
  static const Seat _opponent = Seat.b;

  // ---------------------------------------------------------------------------
  // Estado expuesto a la UI
  // ---------------------------------------------------------------------------

  @override
  HandView? get view {
    final hand = _match.hand;
    return hand == null ? null : HandView.of(hand, _me);
  }

  @override
  int get handNumber => _match.handNumber;

  @override
  bool get isMatchOver => _match.isOver;

  @override
  Seat? get matchWinner => _match.winner;

  @override
  bool get isPlayerTurn {
    final hand = _match.hand;
    return hand != null &&
        !hand.isFinished &&
        hand.toAct == _me &&
        !_isBotThinking &&
        _roundPhase == RoundCollectPhase.none;
  }

  @override
  bool get isOpponentThinking => _isBotThinking;

  @override
  String get statusMessage => _statusMessage;

  @override
  BubbleMsg? get activeBubble => _bubbles.active;

  @override
  RoundCollectPhase get roundPhase => _roundPhase;

  @override
  int get collectedRounds => _collectedRounds;

  @override
  Duration get roundCollectDuration => Duration(milliseconds: roundCollectMs);

  // ---------------------------------------------------------------------------
  // Ciclo de la partida
  // ---------------------------------------------------------------------------

  @override
  void startNewMatch() {
    _cancelPending();
    _match = _matchFactory();
    _match.startHand();
    _statusMessage = 'Mano 1 iniciada. ¡Buena suerte!';
    _notify();
    _checkBotTurn();
  }

  @override
  void startNextHand() {
    if (_match.isOver) return;
    _cancelPending();
    _match.startHand();
    _statusMessage = 'Mano ${_match.handNumber} iniciada.';
    _notify();
    _checkBotTurn();
  }

  @override
  String? perform(GameAction action) {
    final hand = _match.hand;
    if (hand == null) return 'No hay una mano activa.';
    if (hand.isFinished) return 'La mano ya finalizó.';
    if (hand.toAct != _me) return 'No es tu turno.';
    if (_roundPhase != RoundCollectPhase.none) {
      return 'Esperá: se están recogiendo las cartas.';
    }

    try {
      // Siempre a través de TrucoMatch para que se actualice el marcador.
      final events = _match.apply(_me, action);
      _onEvents(events, actor: _me, action: action);
      _checkBotTurn();
      return null;
    } on IllegalActionException catch (e) {
      return 'Acción no permitida: ${e.message}';
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _botTimer?.cancel();
    _collectTimer?.cancel();
    _bubbles.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Turno del bot
  // ---------------------------------------------------------------------------

  /// Cancela temporizadores y globos pendientes (nueva partida / nueva mano).
  void _cancelPending() {
    _botTimer?.cancel();
    _botTimer = null;
    _collectTimer?.cancel();
    _collectTimer = null;
    _roundPhase = RoundCollectPhase.none;
    _collectedRounds = 0;
    _bubbles.clear();
    _isBotThinking = false;
  }

  void _checkBotTurn() {
    final hand = _match.hand;
    if (hand == null || hand.isFinished || _match.isOver) return;

    if (hand.toAct == _opponent && !_isBotThinking) {
      _isBotThinking = true;
      _notify();
      _scheduleBotMove(botDelayMs);
    }
  }

  void _scheduleBotMove(int delayMs) {
    _botTimer?.cancel();
    _botTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_disposed) return;
      // Esperar a que terminen los globos (para leer lo dicho) y a que se
      // despeje la mesa antes de jugar.
      if (_bubbles.busy || _roundPhase != RoundCollectPhase.none) {
        _scheduleBotMove(300);
        return;
      }
      final currentHand = _match.hand;
      if (currentHand != null &&
          currentHand.toAct == _opponent &&
          !currentHand.isFinished) {
        final botView = HandView.of(currentHand, _opponent);
        final action = _bot.choose(botView);
        final events = _match.apply(_opponent, action);
        _onEvents(events, actor: _opponent, action: action);
      }
      _isBotThinking = false;
      _notify();
      _checkBotTurn();
    });
  }

  // ---------------------------------------------------------------------------
  // Eventos -> barra de estado y globos de texto
  // ---------------------------------------------------------------------------

  void _onEvents(
    List<GameEvent> events, {
    required Seat actor,
    required GameAction action,
  }) {
    _announceEvents(events, actor, action);
    if (events.any((e) => e is RoundResolvedEvent)) _startRoundCollect();
    for (final e in events) {
      if (e is BetCalledEvent) {
        final who = e.seat == _me ? 'Vos cantaste' : 'El Bot cantó';
        _statusMessage = '$who: ${GameTexts.betName(e.bet)}';
      } else if (e is BetRespondedEvent) {
        final who = e.seat == _me ? 'Vos respondiste' : 'El Bot respondió';
        _statusMessage = '$who: ${GameTexts.betResponseName(e.response)}';
      } else if (e is PointsAwardedEvent) {
        final receiver = e.seat == _me ? 'Vos' : 'el Bot';
        _statusMessage =
            '+${e.points} pts para $receiver (${GameTexts.pointsReason(e.reason)})';
      } else if (e is HandFinishedEvent) {
        final winnerStr = e.winner == null
            ? (_match.isOver
                  ? (_match.winner == _me
                        ? '¡Llegaste a 30!'
                        : 'El Bot llegó a 30')
                  : 'Parda')
            : (e.winner == _me ? '¡Ganaste la mano!' : 'El Bot ganó la mano.');
        _statusMessage = 'Fin de la mano. $winnerStr';
      }
    }
    _notify();
  }

  /// Ronda resuelta: se muestran las dos cartas un momento, viajan al mazo y
  /// recién entonces se puede seguir jugando. La mesa nunca acumula cartas.
  void _startRoundCollect() {
    _collectTimer?.cancel();
    _roundPhase = RoundCollectPhase.showing;
    _collectTimer = Timer(Duration(milliseconds: roundShowMs), () {
      if (_disposed) return;
      _roundPhase = RoundCollectPhase.collecting;
      _notify();
      _collectTimer = Timer(Duration(milliseconds: roundCollectMs), () {
        if (_disposed) return;
        _roundPhase = RoundCollectPhase.none;
        _collectedRounds = _match.hand?.roundResults.length ?? 0;
        _notify();
        _checkBotTurn(); // el bot puede abrir la próxima ronda
      });
    });
  }

  /// Traduce los eventos de la jugada en globos de texto.
  void _announceEvents(List<GameEvent> events, Seat actor, GameAction action) {
    final hand = _match.hand;
    for (final e in events) {
      if (e is BetCalledEvent) {
        _bubbles.say(
          e.seat,
          GameTexts.callPhrase(
            e.bet,
            envidoCount: hand?.envidoChain.envidoCount ?? 1,
          ),
        );
      } else if (e is BetRespondedEvent) {
        _bubbles.say(e.seat, GameTexts.responsePhrase(e.response, _rng));
      } else if (e is EnvidoResolvedEvent && hand != null) {
        // El mano canta su tanto; el pie lo iguala/supera o dice "son buenas".
        _bubbles.say(hand.mano, 'Tengo ${e.manoPoints}');
        _bubbles.say(
          hand.mano.other,
          e.piePoints == null ? 'Son buenas' : 'Tengo ${e.piePoints}',
        );
      } else if (e is FlorComparedEvent && hand != null) {
        final manoScore = hand.mano == Seat.a ? e.scoreA : e.scoreB;
        final pieScore = hand.mano == Seat.a ? e.scoreB : e.scoreA;
        _bubbles.say(hand.mano, 'Flor de $manoScore');
        _bubbles.say(hand.mano.other, 'Flor de $pieScore');
      }
    }
    if (action is FoldAction) {
      _bubbles.say(actor, GameTexts.foldPhrase(_rng));
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
