import 'dart:async';
import 'dart:math';

import 'package:truco_core/truco_core.dart';

import '../audio/game_audio.dart';
import '../audio/game_voices.dart';
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
    GameAudio? audio,
  }) : _audio = audio ?? SilentGameAudio(),
       _bot = bot ?? HeuristicBot(),
       _matchFactory = matchFactory ?? (() => TrucoMatch()) {
    _bubbles = SpeechBubbleQueue(onChanged: _notify, onShow: _onBubbleShown);
    startNewMatch();
  }

  /// Espera antes de que el bot juegue (sensación de "pensar").
  final int botDelayMs;

  /// Tiempo que se ven las dos cartas de una ronda resuelta antes de recogerlas.
  final int roundShowMs;

  /// Duración de la animación con la que las cartas viajan al mazo.
  final int roundCollectMs;

  final HeuristicBot _bot;
  final GameAudio _audio;
  final List<Timer> _sfxTimers = [];
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

  @override
  bool get soundEnabled => !_audio.muted;

  @override
  void toggleSound() {
    _audio.muted = !_audio.muted;
    _notify();
  }

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
    _cancelSfx();
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
    _cancelSfx();
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
      _audio.playSfx(GameSfx.cardsToDeck); // las cartas vuelven al mazo
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

  // ---------------------------------------------------------------------------
  // Sonido
  // ---------------------------------------------------------------------------

  /// Dice [text] con globo de texto y, si tiene, con su voz. La duración del
  /// globo no baja de lo que dura el audio (más un pequeño margen).
  void _say(Seat seat, String text) {
    final voice = GameVoices.keyFor(text);
    final voiceMs = voice == null ? 0 : (GameVoices.durationMs(voice) ?? 0);
    _bubbles.say(
      seat,
      text,
      voice: voice,
      minDurationMs: voiceMs == 0 ? 0 : voiceMs + 250,
    );
  }

  /// Suena la voz de un globo en el momento en que aparece.
  void _onBubbleShown(BubbleMsg msg) {
    final voice = msg.voice;
    if (voice != null) _audio.playVoice(voice, fromPlayer: msg.seat == _me);
  }

  /// Programa un efecto para dentro de [ms] (p. ej. cuando la carta aterriza).
  void _sfxAfter(int ms, GameSfx sfx) {
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _sfxTimers.remove(timer);
      if (!_disposed) _audio.playSfx(sfx);
    });
    _sfxTimers.add(timer);
  }

  void _cancelSfx() {
    for (final t in _sfxTimers) {
      t.cancel();
    }
    _sfxTimers.clear();
  }

  /// Traduce los eventos de la jugada en globos de texto.
  void _announceEvents(List<GameEvent> events, Seat actor, GameAction action) {
    final hand = _match.hand;
    for (final e in events) {
      if (e is CardPlayedEvent) {
        // Suena cuando la carta aterriza (el rival tarda más: se da vuelta).
        _sfxAfter(e.seat == _me ? 300 : 400, GameSfx.cardPlace);
      } else if (e is BetCalledEvent) {
        _say(
          e.seat,
          GameTexts.callPhrase(
            e.bet,
            envidoCount: hand?.envidoChain.envidoCount ?? 1,
          ),
        );
      } else if (e is BetRespondedEvent) {
        _say(e.seat, GameTexts.responsePhrase(e.response, _rng));
      } else if (e is EnvidoResolvedEvent && hand != null) {
        // El mano canta su tanto; el pie lo iguala/supera o dice "son buenas".
        _say(hand.mano, 'Tengo ${e.manoPoints}');
        _say(
          hand.mano.other,
          e.piePoints == null ? 'Son buenas' : 'Tengo ${e.piePoints}',
        );
      } else if (e is FlorComparedEvent && hand != null) {
        final manoScore = hand.mano == Seat.a ? e.scoreA : e.scoreB;
        final pieScore = hand.mano == Seat.a ? e.scoreB : e.scoreA;
        _say(hand.mano, 'Flor de $manoScore');
        _say(hand.mano.other, 'Flor de $pieScore');
      }
    }
    if (action is FoldAction) {
      _audio.playSfx(GameSfx.cardsToDeck); // las cartas vuelven al mazo
      _say(actor, GameTexts.foldPhrase(_rng));
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
