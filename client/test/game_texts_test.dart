import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/text/game_texts.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  group('GameTexts', () {
    test('nombre legible de una carta', () {
      expect(GameTexts.cardName(TrucoCard(4, Suit.basto)), '4 de Basto');
      expect(GameTexts.cardName(TrucoCard(12, Suit.copa)), '12 de Copa');
    });

    test('nombres de cantos y respuestas', () {
      expect(GameTexts.betName(BetCall.valeCuatro), 'Vale Cuatro');
      expect(GameTexts.betName(BetCall.realEnvido), 'Real Envido');
      expect(GameTexts.betResponseName(BetResponse.noQuiero), 'No quiero');
      expect(GameTexts.pointsReason(PointsReason.irseAlMazo), 'Irse al mazo');
    });

    test('todos los cantos, respuestas y motivos tienen texto', () {
      final rng = Random(1);
      for (final b in BetCall.values) {
        expect(GameTexts.betName(b), isNotEmpty);
        expect(GameTexts.callPhrase(b), isNotEmpty);
      }
      for (final r in BetResponse.values) {
        expect(GameTexts.betResponseName(r), isNotEmpty);
        expect(GameTexts.responsePhrase(r, rng), isNotEmpty);
      }
      for (final p in PointsReason.values) {
        expect(GameTexts.pointsReason(p), isNotEmpty);
      }
      expect(GameTexts.foldPhrase(rng), isNotEmpty);
    });

    test('el segundo envido se dice "Envido, envido"', () {
      expect(GameTexts.callPhrase(BetCall.envido), '¡Envido!');
      expect(GameTexts.callPhrase(BetCall.envido, envidoCount: 2), '¡Envido, envido!');
    });

    test('el retruco y el vale cuatro se "quieren"', () {
      expect(GameTexts.callPhrase(BetCall.retruco), '¡Quiero retruco!');
      expect(GameTexts.callPhrase(BetCall.valeCuatro), '¡Quiero vale cuatro!');
    });

    test('etiquetas de jerarquía: piezas y matas con nombre, comunes vacías', () {
      expect(GameTexts.cardRole(CardRole.macho), '1 Espada (Macho)');
      expect(GameTexts.cardRole(CardRole.piezaPerico), 'Perico (11)');
      final sample = Sample(TrucoCard(3, Suit.copa));
      expect(GameTexts.cardRole(sample.classify(TrucoCard(4, Suit.basto))), '');
    });
  });
}
