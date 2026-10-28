import 'dart:math';
import 'dart:typed_data';

import '../crypto/sha256.dart';
import '../models/card.dart';
import '../models/sample.dart';
import '../models/suit.dart';

/// Flujo pseudoaleatorio determinista a partir de una semilla (SHA-256 en modo
/// contador). Dada la misma semilla produce siempre la misma secuencia, lo que
/// permite auditar un reparto una vez revelada la semilla (RNF-SEG-02).
class SeededStream {
  final Uint8List _seed;
  int _counter = 0;
  Uint8List _block = Uint8List(0);
  int _pos = 0;

  SeededStream(List<int> seed) : _seed = Uint8List.fromList(seed);

  void _refill() {
    final input = Uint8List(_seed.length + 4)..setRange(0, _seed.length, _seed);
    ByteData.sublistView(input).setUint32(_seed.length, _counter++);
    _block = Sha256.hash(input);
    _pos = 0;
  }

  int nextUint32() {
    if (_pos + 4 > _block.length) _refill();
    final v = ByteData.sublistView(_block).getUint32(_pos);
    _pos += 4;
    return v;
  }

  /// Entero uniforme en [0, max) sin sesgo de módulo (muestreo por rechazo).
  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw RangeError.range(max, 1, 0x100000000, 'max');
    }
    final limit = (0x100000000 ~/ max) * max;
    while (true) {
      final v = nextUint32();
      if (v < limit) return v % max;
    }
  }
}

/// Resultado de repartir una mano de 1 contra 1.
class DealtHand {
  /// 3 cartas del bando A y del bando B (en orden de reparto).
  final List<TrucoCard> cardsA;
  final List<TrucoCard> cardsB;
  final Sample sample;

  const DealtHand({
    required this.cardsA,
    required this.cardsB,
    required this.sample,
  });
}

/// Baraja española de 40 cartas con barajado auditable.
class Deck {
  Deck._();

  /// Mazo ordenado de 40 cartas (sin 8 ni 9).
  static List<TrucoCard> standard() => [
        for (final s in Suit.values)
          for (final n in const [1, 2, 3, 4, 5, 6, 7, 10, 11, 12])
            TrucoCard(n, s),
      ];

  /// Genera una semilla de 32 bytes con un generador criptográficamente seguro.
  /// Debe invocarse únicamente en el servidor (o en el cliente en modo offline).
  static Uint8List generateSeed([Random? secureRandom]) {
    final rng = secureRandom ?? Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
  }

  /// Compromiso público de la semilla: SHA-256 en hexadecimal. Se publica al
  /// iniciar la mano y la semilla se revela al terminarla.
  static String commitment(List<int> seed) => Sha256.hex(seed);

  /// Verifica que [seed] corresponda al [commitmentHex] publicado.
  static bool verifyCommitment(List<int> seed, String commitmentHex) =>
      commitment(seed) == commitmentHex.toLowerCase();

  /// Baraja el mazo completo de forma determinista (Fisher-Yates sin sesgo).
  static List<TrucoCard> shuffled(List<int> seed) {
    final cards = standard();
    final stream = SeededStream(seed);
    for (var i = cards.length - 1; i > 0; i--) {
      final j = stream.nextInt(i + 1);
      final tmp = cards[i];
      cards[i] = cards[j];
      cards[j] = tmp;
    }
    return cards;
  }

  /// Reparte una mano: del mazo barajado, el bando A recibe las posiciones
  /// 0, 2 y 4; el bando B las posiciones 1, 3 y 5; la Muestra es la posición 6.
  static DealtHand deal(List<int> seed) {
    final d = shuffled(seed);
    return DealtHand(
      cardsA: [d[0], d[2], d[4]],
      cardsB: [d[1], d[3], d[5]],
      sample: Sample(d[6]),
    );
  }
}
