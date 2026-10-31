import 'package:flutter/foundation.dart';
import 'package:truco_core/truco_core.dart';

import 'speech_bubbles.dart';

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

  /// Realiza una acción del jugador local. Devuelve `null` si se aplicó, o un
  /// mensaje de error legible si no era reglamentaria.
  String? perform(GameAction action);

  void startNewMatch();
  void startNextHand();
}
