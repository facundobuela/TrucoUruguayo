/// Efectos de sonido de la mesa.
enum GameSfx {
  /// Una carta cae sobre la mesa.
  cardPlace,

  /// Las cartas se recogen y vuelven al mazo (fin de ronda o irse al mazo).
  cardsToDeck,
}

/// Contrato de audio del juego. Dart puro: así el controlador se prueba sin
/// plugins de audio. La implementación real es `AudioPlayersGameAudio`; en los
/// tests y por defecto se usa [SilentGameAudio].
abstract class GameAudio {
  /// `true` si el sonido está silenciado.
  bool get muted;
  set muted(bool value);

  /// Reproduce un efecto de sonido.
  void playSfx(GameSfx sfx);

  /// Reproduce una frase hablada. [key] es la clave de `GameVoices`;
  /// [fromPlayer] elige la voz (la tuya o la del rival).
  void playVoice(String key, {required bool fromPlayer});

  void dispose();
}

/// Audio que no reproduce nada (tests y valor por defecto).
class SilentGameAudio implements GameAudio {
  bool _muted = false;

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) => _muted = value;

  @override
  void playSfx(GameSfx sfx) {}

  @override
  void playVoice(String key, {required bool fromPlayer}) {}

  @override
  void dispose() {}
}
