import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

/// Rondas jugadas, una al lado de la otra: carta del rival arriba y la tuya
/// abajo, con la ganadora resaltada.
class TableRounds extends StatelessWidget {
  const TableRounds({
    super.key,
    required this.view,
    required this.cardW,
    required this.cardH,
  });

  final HandView? view;
  final double cardW;
  final double cardH;

  @override
  Widget build(BuildContext context) {
    final v = view;
    if (v == null || v.table.isEmpty) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 40, color: Colors.white24),
          SizedBox(height: 8),
          Text(
            'Tirá una carta para comenzar',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    final rounds = v.table;
    // Cada ronda: columna con carta del bot (arriba) y carta del jugador (abajo),
    // separadas por un pequeño gap. Las rondas están una al lado de la otra.
    const double roundGap = 16; // gap entre rondas (igual que en PlayMat)
    const double cardGap = 8;   // gap entre carta bot y carta jugador dentro de la ronda

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < rounds.length; i++) ...[
            if (i > 0) const SizedBox(width: roundGap),
            _RoundColumn(r: rounds[i], me: v.me, cardW: cardW, cardH: cardH, cardGap: cardGap),
          ],
        ],
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({
    required this.r,
    required this.me,
    required this.cardW,
    required this.cardH,
    required this.cardGap,
  });

  final PlayedRound r;
  final Seat me;
  final double cardW;
  final double cardH;
  final double cardGap;

  @override
  Widget build(BuildContext context) {
    final isParda = r.result == RoundWinner.parda;
    final botWon = r.result == me.other.asRoundWinner;
    final playerWon = r.result == me.asRoundWinner;

    // Etiqueta de resultado debajo de las cartas (sutil)
    String? resultLabel;
    Color resultColor = Colors.white54;
    if (r.result == me.asRoundWinner) {
      resultLabel = 'Ganaste';
      resultColor = Colors.lightGreenAccent;
    } else if (r.result == me.other.asRoundWinner) {
      resultLabel = 'Bot';
      resultColor = Colors.orangeAccent;
    } else if (r.result == RoundWinner.parda) {
      resultLabel = 'Parda';
      resultColor = Colors.amberAccent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carta del Bot (arriba, descubierta)
        if (r.cardOf(me.other) != null)
          _TableCard(
            card: r.cardOf(me.other)!,
            width: cardW,
            height: cardH,
            isWinner: botWon,
            isParda: isParda,
          )
        else
          SizedBox(width: cardW, height: cardH),

        SizedBox(height: cardGap),

        // Carta del Jugador (abajo)
        if (r.cardOf(me) != null)
          _TableCard(
            card: r.cardOf(me)!,
            width: cardW,
            height: cardH,
            isWinner: playerWon,
            isParda: isParda,
          )
        else
          SizedBox(width: cardW, height: cardH),

        // Resultado de la ronda (texto pequeño)
        if (resultLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            resultLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.card,
    required this.width,
    required this.height,
    required this.isWinner,
    required this.isParda,
  });

  final TrucoCard card;
  final double width;
  final double height;
  final bool isWinner;
  final bool isParda;

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.black38;
    double borderWidth = 1.0;
    List<BoxShadow> shadows = [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))];

    if (isWinner) {
      borderColor = Colors.amberAccent;
      borderWidth = 2.8;
      shadows = [
        const BoxShadow(color: Colors.amberAccent, blurRadius: 8, spreadRadius: 1),
      ];
    } else if (isParda) {
      borderColor = Colors.white70;
      borderWidth = 2.0;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/cards/${card.number}_${card.suit.name}.png',
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            '${card.number}\n${card.suit.displayName[0]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
