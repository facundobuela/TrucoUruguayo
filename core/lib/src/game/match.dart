import '../deck/deck.dart';
import '../models/seat.dart';
import '../rules/rules_config.dart';
import 'actions.dart';
import 'events.dart';
import 'hand.dart';

/// Partida completa a 30 puntos (15 malas y 15 buenas) entre dos bandos.
///
/// Se encarga de rotar el mano, repartir cada mano con una semilla auditable
/// y acumular el marcador. La semilla de cada mano se pide a [seedSupplier]
/// (CSPRNG por defecto); inyectar una semilla fija hace la partida determinista
/// para pruebas y auditoría.
class TrucoMatch {
  final RulesConfig config;
  final List<int> Function() seedSupplier;

  int _scoreA = 0;
  int _scoreB = 0;
  Seat _mano;
  int _handNumber = 0;
  TrucoHand? _hand;
  List<int>? _currentSeed;
  Seat? _winner;

  /// Semillas de manos ya terminadas, reveladas para auditoría.
  final List<List<int>> revealedSeeds = [];

  TrucoMatch({
    this.config = const RulesConfig(),
    Seat firstMano = Seat.a,
    List<int> Function()? seedSupplier,
  })  : _mano = firstMano,
        seedSupplier = seedSupplier ?? Deck.generateSeed;

  int get scoreA => _scoreA;
  int get scoreB => _scoreB;
  int scoreOf(Seat s) => s == Seat.a ? _scoreA : _scoreB;
  int get handNumber => _handNumber;
  bool get isOver => _winner != null;
  Seat? get winner => _winner;

  /// Mano actualmente en juego (null si no se inició o la partida terminó).
  TrucoHand? get hand => _hand;

  /// Semilla de la mano en curso. **Secreta** hasta que la mano termina.
  List<int>? get currentSeed => _currentSeed;

  /// Reparte y comienza la siguiente mano. Devuelve la mano creada.
  TrucoHand startHand() {
    if (isOver) throw StateError('La partida ya terminó');
    if (_hand != null && !_hand!.isFinished) {
      throw StateError('La mano anterior no terminó');
    }
    final seed = seedSupplier();
    final dealt = Deck.deal(seed);
    _currentSeed = seed;
    _handNumber++;
    _hand = TrucoHand.start(
      mano: _mano,
      cardsA: dealt.cardsA,
      cardsB: dealt.cardsB,
      sample: dealt.sample,
      scoreA: _scoreA,
      scoreB: _scoreB,
      config: config,
      deckCommitment: Deck.commitment(seed),
    );
    return _hand!;
  }

  /// Aplica una acción a la mano en curso y, si la mano termina, actualiza el
  /// marcador, rota el mano y detecta el fin de la partida.
  List<GameEvent> apply(Seat seat, GameAction action) {
    final h = _hand;
    if (h == null) throw StateError('No hay una mano en curso');
    final events = h.apply(seat, action);
    if (h.isFinished) _closeHand(h);
    return events;
  }

  void _closeHand(TrucoHand h) {
    _scoreA = h.scoreA;
    _scoreB = h.scoreB;
    revealedSeeds.add(_currentSeed!);
    _mano = _mano.other;
    if (h.matchWinner != null) _winner = h.matchWinner;
  }

  /// Verifica que una mano ya terminada fue repartida con [seed].
  static bool auditHand({required List<int> seed, required String commitment}) =>
      Deck.verifyCommitment(seed, commitment);
}
