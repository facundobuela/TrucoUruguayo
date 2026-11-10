import '../game/controller/game_controller.dart';
import '../modes/game_mode.dart';
import '../modes/game_session_factory.dart';

/// Estado del jugador en las partidas clasificatorias.
class RankedProfile {
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int losses;

  const RankedProfile({
    required this.rating,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
  });

  /// Porcentaje de victorias (0 a 1); 0 si todavía no jugó.
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;
}

/// Qué tan listo está el servicio para jugar clasificatorias.
enum RankedAvailability {
  /// Todavía no existe (no hay servidor).
  unavailable,

  /// Existe, pero el jugador no tiene sesión de una cuenta registrada.
  needsAccount,

  /// Se puede buscar partida.
  ready,
}

/// Contrato de las partidas clasificatorias: perfil Elo y emparejamiento.
///
/// Hoy sólo existe [UnavailableRankedService]. Cuando esté el servidor se agrega
/// una implementación que consulte el perfil y busque mesa por WebSocket; la
/// pantalla de Elo no cambia. El Elo en sí (`Elo` en `truco_core`) lo aplica
/// siempre el servidor.
abstract class RankedService {
  RankedAvailability get availability;

  /// Perfil del jugador, o `null` si no hay cuenta o todavía no jugó.
  Future<RankedProfile?> loadProfile();

  /// Busca rival y devuelve el controlador de la mesa cuando se arma.
  Future<GameController> findMatch(GameMode mode);
}

class UnavailableRankedService implements RankedService {
  const UnavailableRankedService();

  @override
  RankedAvailability get availability => RankedAvailability.unavailable;

  @override
  Future<RankedProfile?> loadProfile() async => null;

  @override
  Future<GameController> findMatch(GameMode mode) =>
      Future.error(ModeNotAvailableException(mode));
}
