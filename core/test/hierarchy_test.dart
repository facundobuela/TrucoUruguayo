import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

TrucoCard c(int n, Suit s) => TrucoCard(n, s);

/// Agrupa las cartas (excepto la muestra) por poder de ronda, de mayor a menor.
List<Set<String>> tiers(Sample sample) {
  final byPower = <int, Set<String>>{};
  for (final card in Deck.standard()) {
    if (card == sample.card) continue;
    byPower.putIfAbsent(sample.classify(card).trickPower, () => {}).add(card.id);
  }
  final keys = byPower.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final k in keys) byPower[k]!];
}

void main() {
  group('Jerarquía completa de las 40 cartas (RF-05)', () {
    test('muestra 3 de Copa: orden exacto, sin pieza sustituida', () {
      // Piezas > Macho > Hembra > 7E > 7O > Treses > Doses > Unos(C,O) >
      // Reyes > Caballos > Sotas > Sietes(C,B) > Seises > Cincos > Cuatros.
      final expected = <Set<String>>[
        {'copa_2'},
        {'copa_4'},
        {'copa_5'},
        {'copa_11'},
        {'copa_10'},
        {'espada_1'},
        {'basto_1'},
        {'espada_7'},
        {'oro_7'},
        {'espada_3', 'basto_3', 'oro_3'}, // copa_3 es la muestra
        {'espada_2', 'basto_2', 'oro_2'},
        {'copa_1', 'oro_1'},
        {'espada_12', 'basto_12', 'oro_12', 'copa_12'},
        {'espada_11', 'basto_11', 'oro_11'},
        {'espada_10', 'basto_10', 'oro_10'},
        {'copa_7', 'basto_7'},
        {'espada_6', 'basto_6', 'oro_6', 'copa_6'},
        {'espada_5', 'basto_5', 'oro_5'},
        {'espada_4', 'basto_4', 'oro_4'},
      ];
      expect(tiers(Sample(c(3, Suit.copa))), expected);
    });

    test('muestra 2 de Oro: el Rey de Oro ocupa el lugar de la pieza máxima', () {
      final t = tiers(Sample(c(2, Suit.oro)));
      expect(t[0], {'oro_12'}); // sustituto del 2
      expect(t[1], {'oro_4'});
      expect(t[2], {'oro_5'});
      expect(t[3], {'oro_11'});
      expect(t[4], {'oro_10'});
      expect(t[5], {'espada_1'});
      expect(t[6], {'basto_1'});
      expect(t[7], {'espada_7'});
      expect(t[8], {'oro_7'});
    });

    test('muestra 1 de Espada (una mata): las piezas siguen siendo del palo Espada', () {
      final t = tiers(Sample(c(1, Suit.espada)));
      expect(t.sublist(0, 5), [
        {'espada_2'}, {'espada_4'}, {'espada_5'}, {'espada_11'}, {'espada_10'},
      ]);
      expect(t[5], {'basto_1'}); // el macho es la muestra y no está en el mazo
      expect(t[6], {'espada_7'});
      expect(t[7], {'oro_7'});
    });

    test('las piezas siempre superan a las matas, y éstas al resto', () {
      for (final suit in Suit.values) {
        final s = Sample(c(6, suit));
        final power = (TrucoCard x) => s.classify(x).trickPower;
        final weakestPiece = [2, 4, 5, 10, 11].map((n) => power(c(n, suit))).reduce((a, b) => a < b ? a : b);
        expect(weakestPiece > power(c(1, Suit.espada)), true);
        expect(power(c(7, Suit.oro)) > power(c(3, Suit.espada)), true);
        expect(power(c(1, Suit.copa)) > power(c(12, Suit.copa == suit ? Suit.oro : Suit.copa)), true);
      }
    });

    test('para CUALQUIER muestra hay exactamente 5 piezas con 5 roles distintos', () {
      for (final sampleCard in Deck.standard()) {
        final s = Sample(sampleCard);
        final pieces = [
          for (final card in Deck.standard())
            if (card != sampleCard && s.classify(card).isPiece) card
        ];
        expect(pieces.length, 5, reason: 'muestra $sampleCard');
        expect(pieces.map((p) => s.classify(p)).toSet().length, 5,
            reason: 'roles repetidos con muestra $sampleCard');
        // Todas son del palo de la muestra.
        expect(pieces.every((p) => p.suit == sampleCard.suit), true);
      }
    });

    test('la sustitución sólo ocurre si la muestra es una pieza', () {
      for (final sampleCard in Deck.standard()) {
        final s = Sample(sampleCard);
        final king = c(12, sampleCard.suit);
        if (king == sampleCard) continue;
        expect(s.classify(king).isPiece, s.sampleIsPiece,
            reason: 'muestra $sampleCard');
      }
    });

    test('el valor de envido del sustituto es el de la pieza que reemplaza', () {
      const expected = {2: 30, 4: 29, 5: 28, 11: 27, 10: 27};
      expected.forEach((n, pts) {
        final s = Sample(c(n, Suit.basto));
        expect(s.classify(c(12, Suit.basto)).envidoScore, pts);
      });
    });

    test('cartas de igual jerarquía empatan (parda) aunque sean de distinto palo', () {
      final s = Sample(c(3, Suit.copa));
      expect(
          RoundResolver.compareCards(cardA: c(3, Suit.espada), cardB: c(3, Suit.oro), sample: s),
          RoundWinner.parda);
      expect(
          RoundResolver.compareCards(cardA: c(1, Suit.copa), cardB: c(1, Suit.oro), sample: s),
          RoundWinner.parda);
      expect(
          RoundResolver.compareCards(cardA: c(7, Suit.copa), cardB: c(7, Suit.basto), sample: s),
          RoundWinner.parda);
      // Pero 7 de Espada y 7 de Oro NO empatan entre sí ni con los otros sietes.
      expect(
          RoundResolver.compareCards(cardA: c(7, Suit.espada), cardB: c(7, Suit.oro), sample: s),
          RoundWinner.bandoA);
    });
  });
}
