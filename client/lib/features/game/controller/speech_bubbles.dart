import 'dart:async';
import 'dart:math';

import 'package:truco_core/truco_core.dart';

/// Mensaje dicho por un jugador, mostrado como globo de texto.
class BubbleMsg {
  final int id;
  final Seat seat;
  final String text;
  final int durationMs;
  const BubbleMsg(this.id, this.seat, this.text, this.durationMs);
}

/// Cola de globos de texto: se muestran de a uno, en orden, cada uno durante un
/// tiempo proporcional a su largo. Lógica pura (sin Flutter) para poder
/// probarla aislada. [onChanged] se invoca cada vez que cambia el globo activo.
class SpeechBubbleQueue {
  SpeechBubbleQueue({required this.onChanged});

  final void Function() onChanged;
  final List<BubbleMsg> _queue = [];
  BubbleMsg? _active;
  int _seq = 0;
  Timer? _timer;
  bool _disposed = false;

  /// Globo que se está mostrando ahora (null si no hay ninguno).
  BubbleMsg? get active => _active;

  /// `true` si hay un globo en pantalla o en espera.
  bool get busy => _active != null || _queue.isNotEmpty;

  /// Encola un globo dicho por [seat].
  void say(Seat seat, String text) {
    final ms = max(1300, 800 + text.length * 45);
    _queue.add(BubbleMsg(++_seq, seat, text, ms));
    _pump();
  }

  void _pump() {
    if (_disposed || _active != null || _queue.isEmpty) return;
    final next = _queue.removeAt(0);
    _active = next;
    // Si había una pausa entre globos pendiente, se reemplaza (evita dejar
    // un temporizador huérfano que `clear`/`dispose` no podrían cancelar).
    _timer?.cancel();
    onChanged();
    _timer = Timer(Duration(milliseconds: next.durationMs), () {
      if (_disposed) return;
      _active = null;
      onChanged();
      _timer = Timer(const Duration(milliseconds: 150), _pump);
    });
  }

  /// Descarta todo lo pendiente. No notifica: quien llama decide cuándo.
  void clear() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _active = null;
  }

  void dispose() {
    _disposed = true;
    clear();
  }
}
