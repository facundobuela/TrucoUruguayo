import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

/// Marcador superior: puntaje de cada jugador, mano en curso y objetivo.
/// Muestra el puntaje en vivo (incluye flor y envido ya acreditados).
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.view,
    required this.handNumber,
    required this.isCompact,
    this.myName = 'Vos',
    this.opponentName = 'Bot (IA)',
  });

  final HandView? view;
  final int handNumber;
  final bool isCompact;
  final String myName;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final me = v?.me ?? Seat.a;
    final target = v?.targetPoints ?? 30;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: isCompact ? 4 : 8),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(bottom: BorderSide(color: Colors.black45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScoreBadge(
              title: myName,
              score: v?.scoreOf(me) ?? 0,
              isMano: v?.mano == me,
              malasPoints: target ~/ 2,
              isCompact: isCompact,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mano #$handNumber',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'A $target PUNTOS',
                  style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ScoreBadge(
              title: opponentName,
              score: v?.scoreOf(me.other) ?? 0,
              isMano: v?.mano == me.other,
              malasPoints: target ~/ 2,
              isCompact: isCompact,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.title,
    required this.score,
    required this.isMano,
    required this.malasPoints,
    required this.isCompact,
  });

  final String title;
  final int score;
  final bool isMano;
  final int malasPoints;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isBuenas = score >= malasPoints;
    final etapa = isBuenas ? 'Buenas (${score - malasPoints})' : 'Malas ($score)';

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            // Indicador de mano sin emoji: asterisco tipográfico
            if (isMano) const Text(' *', style: TextStyle(fontSize: 13, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: isCompact ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
          ),
        ),
        Text(etapa, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
