/// Parámetros de mesa que modifican las reglas (RF-11 y RF-16 del SRS).
///
/// En el MVP sólo se usa la configuración por defecto: 30 puntos, con Flor.
class RulesConfig {
  /// Puntos para ganar la partida (30 en el MVP; 40 queda para Fase 2).
  final int targetPoints;

  /// Si es `false`, la Flor no existe y las manos con flor se juegan por Envido.
  final bool withFlor;

  const RulesConfig({this.targetPoints = 30, this.withFlor = true})
      : assert(targetPoints == 30 || targetPoints == 40);

  /// Puntos que dura "las malas" (la mitad de la partida).
  int get malasPoints => targetPoints ~/ 2;

  Map<String, dynamic> toJson() =>
      {'targetPoints': targetPoints, 'withFlor': withFlor};

  factory RulesConfig.fromJson(Map<String, dynamic> j) => RulesConfig(
        targetPoints: j['targetPoints'] as int,
        withFlor: j['withFlor'] as bool,
      );
}
