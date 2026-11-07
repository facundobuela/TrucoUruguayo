import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_audio.dart';

/// Audio real con el paquete `audioplayers` (Android, iOS, web y escritorio).
///
/// Nunca lanza excepciones hacia el juego: si un audio falta o el sistema no
/// puede reproducirlo, simplemente no suena.
class AudioPlayersGameAudio implements GameAudio {
  AudioPlayersGameAudio({Random? rng, int sfxPlayers = 4})
    : _rng = rng ?? Random() {
    for (var i = 0; i < sfxPlayers; i++) {
      final player = AudioPlayer();
      // Efectos cortos: baja latencia. Varios reproductores rotativos permiten
      // que dos efectos suenen a la vez.
      unawaited(player.setPlayerMode(PlayerMode.lowLatency).catchError((_) {}));
      _sfxPlayers.add(player);
    }
  }

  final Random _rng;
  final List<AudioPlayer> _sfxPlayers = [];
  final AudioPlayer _voicePlayer = AudioPlayer();
  int _nextSfx = 0;
  bool _muted = false;

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) {
    _muted = value;
    if (value) unawaited(_voicePlayer.stop().catchError((_) {}));
  }

  @override
  void playSfx(GameSfx sfx) {
    if (_muted) return;
    final path = switch (sfx) {
      GameSfx.cardPlace => 'audio/sfx/card_place_${1 + _rng.nextInt(3)}.wav',
      GameSfx.cardsToDeck => 'audio/sfx/cards_to_deck.wav',
    };
    final player = _sfxPlayers[_nextSfx++ % _sfxPlayers.length];
    _play(player, path, 0.9);
  }

  @override
  void playVoice(String key, {required bool fromPlayer}) {
    if (_muted) return;
    final who = fromPlayer ? 'player' : 'rival';
    _play(_voicePlayer, 'audio/voice/$who/$key.mp3', 1.0);
  }

  void _play(AudioPlayer player, String assetPath, double volume) {
    unawaited(() async {
      try {
        await player.stop();
        await player.play(AssetSource(assetPath), volume: volume);
      } catch (e) {
        debugPrint('Audio no disponible ($assetPath): $e');
      }
    }());
  }

  @override
  void dispose() {
    for (final p in _sfxPlayers) {
      unawaited(p.dispose().catchError((_) {}));
    }
    unawaited(_voicePlayer.dispose().catchError((_) {}));
  }
}
