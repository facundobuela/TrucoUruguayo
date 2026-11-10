import '../game/audio/game_audio.dart';
import '../game/controller/game_controller.dart';
import '../game/controller/offline_game_controller.dart';
import 'game_mode.dart';

/// Se intentó empezar un modo que todavía no se puede jugar.
class ModeNotAvailableException implements Exception {
  final GameMode mode;
  const ModeNotAvailableException(this.mode);

  @override
  String toString() =>
      'ModeNotAvailableException: ${mode.title} no está disponible';
}

/// Arma el [GameController] que corresponde a cada modo. Es el único lugar
/// que sabe cómo se conecta cada modo con el motor: cuando exista el modo
/// online se agrega acá un `OnlineGameController`, sin tocar el menú ni la UI.
abstract class GameSessionFactory {
  GameController create(GameMode mode);
}

class DefaultGameSessionFactory implements GameSessionFactory {
  const DefaultGameSessionFactory({this.audio});

  /// Sonido de las partidas (sin audio la partida es muda).
  final GameAudio? audio;

  @override
  GameController create(GameMode mode) {
    if (!mode.isPlayable) throw ModeNotAvailableException(mode);

    if (mode.opponent == OpponentKind.bot && mode.playersPerTeam == 1) {
      return OfflineGameController(audio: audio);
    }
    // 1 vs 1 online, 2 vs 2 y clasificatorias: todavía sin implementar.
    throw ModeNotAvailableException(mode);
  }
}
