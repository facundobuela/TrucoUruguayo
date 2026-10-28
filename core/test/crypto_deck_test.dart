import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  group('SHA-256 (vectores NIST)', () {
    test('cadena vacía', () {
      expect(Sha256.hex([]),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    });
    test('"abc"', () {
      expect(Sha256.hex('abc'.codeUnits),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });
    test('un millón de "a"', () {
      expect(Sha256.hex(List.filled(1000000, 0x61)),
          'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
    });
    test('límites de padding (55, 56, 63, 64 bytes)', () {
      // Valores calculados con hashlib de Python.
      const expected = {
        55: '9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318',
        56: 'b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a',
        63: '7d3e74a05d7db15bce4ad9ec0658ea98e3f06eeecf16b4c6fff2da457ddc2f34',
        64: 'ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb',
      };
      expected.forEach((len, hex) {
        expect(Sha256.hex(List.filled(len, 0x61)), hex, reason: 'len=$len');
      });
    });
    test('fromHex/toHex son inversos', () {
      final bytes = Uint8List.fromList([0, 1, 15, 16, 255]);
      expect(Sha256.fromHex(Sha256.toHex(bytes)), bytes);
    });
  });

  group('Mazo y barajado auditable', () {
    test('el mazo estándar tiene 40 cartas únicas sin 8 ni 9', () {
      final d = Deck.standard();
      expect(d.length, 40);
      expect(d.toSet().length, 40);
      expect(d.any((c) => c.number == 8 || c.number == 9), false);
      for (final s in Suit.values) {
        expect(d.where((c) => c.suit == s).length, 10);
      }
    });

    test('mismo seed => mismo mazo (determinista)', () {
      final seed = List<int>.generate(32, (i) => i);
      expect(Deck.shuffled(seed), Deck.shuffled(seed));
    });

    test('seeds distintos => mazos distintos', () {
      final a = Deck.shuffled(List.filled(32, 1));
      final b = Deck.shuffled(List.filled(32, 2));
      expect(a == b, false);
    });

    test('el barajado siempre es una permutación de las 40 cartas', () {
      for (var i = 0; i < 50; i++) {
        final d = Deck.shuffled(Deck.generateSeed());
        expect(d.toSet(), Deck.standard().toSet());
      }
    });

    test('reparto: 3+3 cartas distintas y la muestra no está en las manos', () {
      for (var i = 0; i < 200; i++) {
        final deal = Deck.deal(Deck.generateSeed());
        final all = [...deal.cardsA, ...deal.cardsB, deal.sample.card];
        expect(all.length, 7);
        expect(all.toSet().length, 7);
      }
    });

    test('compromiso: la semilla revelada verifica y otra no', () {
      final seed = Deck.generateSeed();
      final c = Deck.commitment(seed);
      expect(c.length, 64);
      expect(Deck.verifyCommitment(seed, c), true);
      expect(Deck.verifyCommitment(seed, c.toUpperCase()), true);
      final other = Deck.generateSeed();
      expect(Deck.verifyCommitment(other, c), false);
    });

    test('auditoría: desde la semilla se reproduce exactamente el reparto', () {
      final seed = Deck.generateSeed();
      final a = Deck.deal(seed);
      final b = Deck.deal(Uint8List.fromList(seed));
      expect(a.cardsA, b.cardsA);
      expect(a.cardsB, b.cardsB);
      expect(a.sample.card, b.sample.card);
    });

    test('nextInt está en rango y no tiene sesgo grosero (chi-cuadrado laxo)', () {
      final stream = SeededStream(List.filled(32, 7));
      const n = 7, draws = 14000;
      final counts = List.filled(n, 0);
      for (var i = 0; i < draws; i++) {
        final v = stream.nextInt(n);
        expect(v >= 0 && v < n, true);
        counts[v]++;
      }
      final expected = draws / n;
      final chi = counts.fold<double>(
          0, (a, c) => a + (c - expected) * (c - expected) / expected);
      // 6 grados de libertad: p=0.001 ~ 22.5. Umbral holgado para no ser frágil.
      expect(chi < 30, true, reason: 'chi=$chi counts=$counts');
    });

    test('cada carta puede salir en cada posición (sin posición fija)', () {
      // La carta en la posición 0 debe variar entre muchas semillas.
      final firsts = <TrucoCard>{};
      for (var i = 0; i < 400; i++) {
        firsts.add(Deck.shuffled(Deck.generateSeed()).first);
      }
      expect(firsts.length > 30, true, reason: 'distintas=${firsts.length}');
    });
  });

  group('TrucoCard ids', () {
    test('id <-> fromId para las 40 cartas', () {
      for (final c in Deck.standard()) {
        expect(TrucoCard.fromId(c.id), c);
      }
      expect(TrucoCard(2, Suit.espada).id, 'espada_2');
    });
    test('ids inválidos lanzan FormatException', () {
      for (final bad in ['', 'espada', 'espada_8', 'espada_9', 'foo_2', 'oro_13', 'oro_0', 'a_b_c']) {
        expect(() => TrucoCard.fromId(bad), throwsA(isA<FormatException>()),
            reason: bad);
      }
    });
  });
}
