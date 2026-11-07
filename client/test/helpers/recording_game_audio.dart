import 'package:truco_client/features/game/audio/game_audio.dart';

/// Audio de prueba: registra lo que se le pide reproducir (respeta el silencio
/// igual que la implementación real).
class RecordingGameAudio implements GameAudio {
  bool _muted = false;
  final List<GameSfx> sfx = [];
  final List<String> voices = [];
  final List<bool> voiceFromPlayer = [];

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) => _muted = value;

  @override
  void playSfx(GameSfx s) {
    if (!_muted) sfx.add(s);
  }

  @override
  void playVoice(String key, {required bool fromPlayer}) {
    if (_muted) return;
    voices.add(key);
    voiceFromPlayer.add(fromPlayer);
  }

  @override
  void dispose() {}
}
