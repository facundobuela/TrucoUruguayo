import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/audio/game_voices.dart';
import 'package:truco_client/features/game/text/game_texts.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  group('GameVoices: cada frase del juego tiene su voz', () {
    test('todos los cantos tienen clave de voz', () {
      for (final b in BetCall.values) {
        expect(GameVoices.keyFor(GameTexts.callPhrase(b)), isNotNull, reason: '$b');
      }
      expect(
        GameVoices.keyFor(GameTexts.callPhrase(BetCall.envido, envidoCount: 2)),
        'envido_envido',
      );
    });

    test('todas las variantes de respuesta y de mazo tienen clave de voz', () {
      for (final t in [
        ...GameTexts.quieroPhrases,
        ...GameTexts.noQuieroPhrases,
        ...GameTexts.foldPhrases,
        GameTexts.responsePhrase(BetResponse.conFlorMeAchico, Random(1)),
        'Son buenas',
      ]) {
        expect(GameVoices.keyFor(t), isNotNull, reason: t);
      }
    });

    test('los tantos de envido (0 a 59) y de flor (20 a 87) tienen voz', () {
      for (var n = 0; n <= 59; n++) {
        expect(GameVoices.keyFor('Tengo $n'), 'tengo_$n');
      }
      for (var n = 20; n <= 87; n++) {
        expect(GameVoices.keyFor('Flor de $n'), 'flor_de_$n');
      }
      expect(GameVoices.keyFor('Tengo 60'), isNull);
      expect(GameVoices.keyFor('Flor de 19'), isNull);
      expect(GameVoices.keyFor('Flor de 88'), isNull);
      expect(GameVoices.keyFor('texto cualquiera'), isNull);
    });

    test('el valor máximo de envido y de flor del motor está cubierto', () {
      // Dos piezas: 30 + 29; tres piezas: 30 + 29 + 28.
      expect(GameVoices.envidoMax, greaterThanOrEqualTo(30 + 29));
      expect(GameVoices.florMax, greaterThanOrEqualTo(30 + 29 + 28));
    });
  });

  group('Archivos de audio', () {
    test('existe el audio de cada clave, para tu voz y la del rival', () {
      for (final key in GameVoices.allKeys) {
        for (final who in ['player', 'rival']) {
          expect(
            File('assets/audio/voice/$who/$key.mp3').existsSync(),
            isTrue,
            reason: 'falta assets/audio/voice/$who/$key.mp3',
          );
        }
        expect(GameVoices.durationMs(key), greaterThan(0), reason: key);
      }
    });

    test('existen los efectos de sonido', () {
      for (final f in [
        'card_place_1.wav',
        'card_place_2.wav',
        'card_place_3.wav',
        'cards_to_deck.wav',
      ]) {
        expect(File('assets/audio/sfx/$f').existsSync(), isTrue, reason: f);
      }
    });

    test('el pubspec declara las carpetas de audio como assets', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final dir in [
        'assets/audio/sfx/',
        'assets/audio/voice/player/',
        'assets/audio/voice/rival/',
      ]) {
        expect(pubspec.contains(dir), isTrue, reason: 'falta $dir en pubspec.yaml');
      }
      expect(pubspec.contains('audioplayers'), isTrue);
    });
  });
}
