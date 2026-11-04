import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

/// Resultado de cada una de las 3 rondas de la mano: como las cartas se
/// recogen al mazo, este indicador conserva quién ganó cada ronda.
class RoundResultsStrip extends StatelessWidget {
  const RoundResultsStrip({super.key, required this.view});

  final HandView view;

  @override
  Widget build(BuildContext context) {
    final results = [for (final r in view.table) r.result];
    final texts = <String>[];
    for (var i = 0; i < 3; i++) {
      final r = i < results.length ? results[i] : null;
      if (r == null) continue;
      texts.add(
        'ronda ${i + 1}: ${r == RoundWinner.parda ? 'parda' : r == view.me.asRoundWinner ? 'ganaste' : 'perdiste'}',
      );
    }

    return Semantics(
      label: texts.isEmpty
          ? 'Rondas: ninguna resuelta todavía'
          : 'Rondas: ${texts.join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Rondas',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _dot(i < results.length ? results[i] : null),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(RoundWinner? r) {
    final Color color;
    final Widget? icon;
    if (r == null) {
      color = Colors.white24;
      icon = null;
    } else if (r == RoundWinner.parda) {
      color = Colors.amber;
      icon = const Text(
        '=',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
    } else if (r == view.me.asRoundWinner) {
      color = Colors.lightGreen;
      icon = const Icon(Icons.check, size: 15, color: Colors.black87);
    } else {
      color = Colors.redAccent;
      icon = const Icon(Icons.close, size: 15, color: Colors.black87);
    }
    final pending = r == null;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pending ? Colors.transparent : color,
        border: Border.all(color: pending ? Colors.white24 : color, width: 1.5),
      ),
      child: icon,
    );
  }
}
