import 'dart:math';

/// Parámetros del sistema Elo de las partidas clasificatorias.
///
/// Los valores por defecto son una **propuesta pendiente de validar** (el SRS
/// pide Elo pero no fija números); ver docs/DECISIONES_DE_REGLAS.md.
class EloConfig {
  /// Puntaje con el que empieza todo jugador nuevo.
  final int initialRating;

  /// Cuánto se mueve el puntaje por partida (jugadores con historial).
  final double kFactor;

  /// K más alto mientras el jugador es nuevo, para que sea más rápido ubicarlo.
  final double provisionalKFactor;

  /// Partidas durante las que se usa [provisionalKFactor].
  final int provisionalGames;

  /// Piso del puntaje: nadie baja de acá.
  final int minRating;

  const EloConfig({
    this.initialRating = 1000,
    this.kFactor = 32,
    this.provisionalKFactor = 48,
    this.provisionalGames = 10,
    this.minRating = 100,
  });
}

/// Un participante de una partida clasificatoria: su puntaje y cuántas
/// partidas clasificatorias jugó (define su K).
class EloEntry {
  final int rating;
  final int gamesPlayed;
  const EloEntry(this.rating, this.gamesPlayed);
}

/// Resultado de aplicar Elo a un jugador: cuánto cambia y cómo queda.
class EloChange {
  final int delta;
  final int newRating;
  const EloChange(this.delta, this.newRating);

  @override
  String toString() =>
      'EloChange(${delta >= 0 ? '+' : ''}$delta -> $newRating)';
}

/// Cálculo de Elo, igual para cliente y servidor (vive en `core`).
///
/// El servidor es quien aplica los cambios; el cliente puede usar estas mismas
/// funciones para anticipar "ganás +X / perdés −Y". Sólo cuentan las partidas
/// contra otros jugadores: contra el Bot nunca se usa (RF-02).
class Elo {
  final EloConfig config;
  const Elo([this.config = const EloConfig()]);

  /// Probabilidad esperada de que gane quien tiene [rating] contra
  /// [opponentRating] (entre 0 y 1; 0.5 si están parejos).
  double expectedScore(int rating, int opponentRating) =>
      1 / (1 + pow(10, (opponentRating - rating) / 400));

  /// K a usar según las partidas jugadas.
  double kFor(int gamesPlayed) => gamesPlayed < config.provisionalGames
      ? config.provisionalKFactor
      : config.kFactor;

  /// Cambio de puntaje de [me] contra [opponentRating]. [score] es 1 si ganó,
  /// 0 si perdió (0.5 sería un empate, que el truco no tiene).
  ///
  /// [ratingForExpectation] permite medir la probabilidad con otro puntaje que
  /// el propio (en equipos se usa el promedio del equipo).
  EloChange change({
    required EloEntry me,
    required int opponentRating,
    required double score,
    int? ratingForExpectation,
  }) {
    final expected = expectedScore(
      ratingForExpectation ?? me.rating,
      opponentRating,
    );
    final raw = kFor(me.gamesPlayed) * (score - expected);
    var newRating = me.rating + raw.round();
    if (newRating < config.minRating) newRating = config.minRating;
    return EloChange(newRating - me.rating, newRating);
  }

  /// Partida 1 contra 1. Devuelve el cambio de [a] y el de [b].
  ({EloChange a, EloChange b}) duel({
    required EloEntry a,
    required EloEntry b,
    required bool aWon,
  }) => (
    a: change(me: a, opponentRating: b.rating, score: aWon ? 1 : 0),
    b: change(me: b, opponentRating: a.rating, score: aWon ? 0 : 1),
  );

  /// Puntaje de un equipo: el promedio de sus integrantes (redondeado).
  int teamRating(List<EloEntry> team) {
    if (team.isEmpty) throw ArgumentError('Un equipo necesita integrantes');
    final sum = team.fold<int>(0, (a, e) => a + e.rating);
    return (sum / team.length).round();
  }

  /// Partida por equipos (2 vs 2, 3 vs 3): la probabilidad se calcula con el
  /// puntaje promedio de cada equipo y cada integrante se mueve con su propio
  /// K (así un compañero fuerte no pierde más que uno débil).
  ({List<EloChange> a, List<EloChange> b}) teamDuel({
    required List<EloEntry> teamA,
    required List<EloEntry> teamB,
    required bool teamAWon,
  }) {
    final ratingA = teamRating(teamA);
    final ratingB = teamRating(teamB);
    return (
      a: [
        for (final m in teamA)
          change(
            me: m,
            opponentRating: ratingB,
            score: teamAWon ? 1 : 0,
            ratingForExpectation: ratingA,
          ),
      ],
      b: [
        for (final m in teamB)
          change(
            me: m,
            opponentRating: ratingA,
            score: teamAWon ? 0 : 1,
            ratingForExpectation: ratingB,
          ),
      ],
    );
  }
}
