import '../game/actions.dart';
import '../game/events.dart';
import '../game/view.dart';

/// Códecs de mensajes del protocolo cliente↔servidor (docs/ARQUITECTURA.md §3).
///
/// Todos los mensajes viajan como JSON con un campo `type`. Los de
/// servidor→cliente pueden llevar además `seq` (número de secuencia del evento
/// dentro de la mesa) para detectar pérdidas tras reconectar.
class Protocol {
  Protocol._();

  // ---- Cliente -> Servidor ----------------------------------------------------
  static const heartbeat = 'HEARTBEAT';
  static const createRoom = 'CREATE_ROOM';
  static const joinRoom = 'JOIN_ROOM';
  static const quickMatch = 'QUICK_MATCH';
  static const cancelQueue = 'CANCEL_QUEUE';
  static const fillWithBot = 'FILL_WITH_BOT';
  static const leaveRoom = 'LEAVE_ROOM';
  static const reconnect = 'RECONNECT';

  // ---- Servidor -> Cliente ----------------------------------------------------
  static const welcome = 'WELCOME';
  static const roomCreated = 'ROOM_CREATED';
  static const roomJoined = 'ROOM_JOINED';
  static const queueWaiting = 'QUEUE_WAITING';
  static const queueTimeout = 'QUEUE_TIMEOUT';
  static const matchStarted = 'MATCH_STARTED';
  static const handDealt = 'HAND_DEALT';
  static const events = 'EVENTS';
  static const yourTurn = 'YOUR_TURN';
  static const reconnectSnapshot = 'RECONNECT_SNAPSHOT';
  static const opponentDisconnected = 'OPPONENT_DISCONNECTED';
  static const opponentReconnected = 'OPPONENT_RECONNECTED';
  static const deckReveal = 'DECK_REVEAL';
  static const error = 'ERROR';

  /// `HAND_DEALT`: sólo las 3 cartas del destinatario y la Muestra.
  static Map<String, dynamic> handDealtMessage(HandView v, {String? commitment}) => {
        'type': handDealt,
        'myCards': [for (final c in v.myDealtCards) c.id],
        'sampleCard': v.sample.toJson(),
        'mano': v.mano.name,
        'scoreA': v.scoreA,
        'scoreB': v.scoreB,
        if (commitment != null) 'deckCommitment': commitment,
      };

  static Map<String, dynamic> eventsMessage(List<GameEvent> ev, {int? seq}) => {
        'type': events,
        if (seq != null) 'seq': seq,
        'events': [for (final e in ev) e.toJson()],
      };

  static Map<String, dynamic> snapshotMessage(HandView v,
          {required int matchScoreA, required int matchScoreB, int? seq}) =>
      {
        'type': reconnectSnapshot,
        if (seq != null) 'seq': seq,
        'matchScoreA': matchScoreA,
        'matchScoreB': matchScoreB,
        'hand': v.toJson(),
      };

  static Map<String, dynamic> errorMessage(String code, String message) =>
      {'type': error, 'code': code, 'message': message};

  /// Interpreta un mensaje de acción del cliente. Devuelve null si [json] no
  /// es una acción de juego (p. ej. un HEARTBEAT o un mensaje de lobby).
  static GameAction? parseAction(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'PLAY_CARD':
      case 'CALL_BET':
      case 'RESPOND_BET':
      case 'FOLD_HAND':
        return GameAction.fromJson(json);
      default:
        return null;
    }
  }
}
