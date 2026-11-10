/// Contra quién se juega.
enum OpponentKind {
  /// Contra la IA del dispositivo (sin conexión).
  bot,

  /// Contra otras personas, online.
  human,
}

/// Si un modo se puede jugar hoy.
enum ModeAvailability { available, comingSoon }

/// Una forma de jugar que se ofrece en el menú. Dart puro (sin Flutter): el
/// menú, las pruebas y, más adelante, el servidor comparten esta definición.
class GameMode {
  final String id;
  final String title;
  final String subtitle;

  /// Jugadores por equipo: 1 (1 vs 1), 2 (2 vs 2), 3 (3 vs 3).
  final int playersPerTeam;
  final OpponentKind opponent;

  /// `true` si es una partida clasificatoria (suma o resta Elo).
  final bool ranked;
  final ModeAvailability availability;

  const GameMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.playersPerTeam,
    required this.opponent,
    this.ranked = false,
    this.availability = ModeAvailability.comingSoon,
  });

  bool get isPlayable => availability == ModeAvailability.available;

  /// Cantidad total de jugadores en la mesa.
  int get seats => playersPerTeam * 2;

  /// Las clasificatorias exigen una cuenta registrada (RF-01).
  bool get requiresAccount => ranked;

  /// Sólo las partidas clasificatorias contra personas suman Elo: las partidas
  /// contra el Bot nunca cuentan (RF-02).
  bool get countsForElo => ranked && opponent == OpponentKind.human;

  @override
  String toString() => 'GameMode($id)';
}

/// Catálogo de modos de juego.
class GameModes {
  GameModes._();

  static const vsBot = GameMode(
    id: 'vs_bot',
    title: '1 vs 1 contra el Bot',
    subtitle: 'Practicá sin conexión',
    playersPerTeam: 1,
    opponent: OpponentKind.bot,
    availability: ModeAvailability.available,
  );

  static const vsPlayer = GameMode(
    id: 'vs_player',
    title: '1 vs 1 contra jugador',
    subtitle: 'Online, en tiempo real',
    playersPerTeam: 1,
    opponent: OpponentKind.human,
  );

  static const twoVsTwo = GameMode(
    id: 'two_vs_two',
    title: '2 vs 2',
    subtitle: 'Por parejas, con señas',
    playersPerTeam: 2,
    opponent: OpponentKind.human,
  );

  static const ranked1v1 = GameMode(
    id: 'ranked_1v1',
    title: 'Clasificatoria 1 vs 1',
    subtitle: 'Sumá o perdé puntos Elo',
    playersPerTeam: 1,
    opponent: OpponentKind.human,
    ranked: true,
  );

  static const ranked2v2 = GameMode(
    id: 'ranked_2v2',
    title: 'Clasificatoria 2 vs 2',
    subtitle: 'Elo por equipos',
    playersPerTeam: 2,
    opponent: OpponentKind.human,
    ranked: true,
  );

  /// Modos de la pantalla "Jugar".
  static const List<GameMode> casual = [vsBot, vsPlayer, twoVsTwo];

  /// Modos de la pantalla "Partidas Elo".
  static const List<GameMode> rankedModes = [ranked1v1, ranked2v2];

  static const List<GameMode> all = [...casual, ...rankedModes];

  static GameMode? byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
