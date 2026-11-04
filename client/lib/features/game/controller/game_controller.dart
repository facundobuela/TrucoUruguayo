import 'package:flutter/foundation.dart';
import 'package:truco_core/truco_core.dart';

import 'speech_bubbles.dart';

/// Fase de la animación con la que se recogen al mazo las cartas de una ronda.
enum RoundCollectPhase {
  /// No hay cartas esperando ser recogidas.
  none,

  /// Ronda recién resuelta: se ven las dos cartas y quién ganó.
  showing,

  /// Las cartas viajan al mazo.
  collecting,
}

/// Contrato entre la pantalla de juego y quien la alimenta.
///
/// Hoy lo implementa `OfflineGameController` (motor local + bot). Para el modo
/// online habrá un `OnlineGameController` que hable por WebSocket con el
/// servidor autoritativo: la UI no cambia porque sólo conoce este contrato y
/// la [HandView] filtrada (nunca las cartas del rival).
abstract class GameController extends ChangeNotifier {
  /// Vista de la mano en curso para el jugador local, o `null` si no empezó.
  HandView? get view;

  /// Número de la mano dentro de la partida (1, 2, ...).
  int get handNumber;

  bool get isMatchOver;
  Seat? get matchWinner;

  /// `true` si el jugador local debe actuar ahora.
  bool get isPlayerTurn;

  /// `true` mientras el rival "piensa" su jugada.
  bool get isOpponentThinking;

  /// Último hecho relevante, para la barra de estado.
  String get statusMessage;

  /// Globo de texto que se está mostrando (null si no hay).
  BubbleMsg? get activeBubble;

  /// Fase de recogida de la última ronda resuelta. Mientras no sea
  /// [RoundCollectPhase.none] nadie puede jugar: la mesa se está despejando.
  RoundCollectPhase get roundPhase;

  /// Cantidad de rondas de la mano en curso que ya se recogieron al mazo y no
  /// deben dibujarse más sobre la mesa.
  int get collectedRounds;

  /// Duración de la animación con la que las cartas viajan al mazo.
  Duration get roundCollectDuration;

  /// Realiza una acción del jugador local. Devuelve `null` si se aplicó, o un
  /// mensaje de error legible si no era reglamentaria.
  String? perform(GameAction action);

  void startNewMatch();
  void startNextHand();
}
