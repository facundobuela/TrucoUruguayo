import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';

/// Mesa: muestra SOLO la ronda en juego (carta del rival arriba y la tuya
/// abajo). Cuando la ronda se resuelve, las cartas se ven un momento y luego
/// viajan al mazo, de modo que nunca se acumulan sobre el tapete.
class TableRounds extends StatelessWidget {
  const TableRounds({
    super.key,
    required this.view,
    required this.cardW,
    required this.cardH,
    this.collectedRounds = 0,
    this.phase = RoundCollectPhase.none,
    this.collectOffset = Offset.zero,
    this.collectDuration = const Duration(milliseconds: 400),
  });

  final HandView? view;
  final double cardW;
  final double cardH;

  /// Rondas ya recogidas al mazo: no se dibujan.
  final int collectedRounds;

  /// Fase de la recogida de la última ronda resuelta.
  final RoundCollectPhase phase;

  /// Desplazamiento (desde el centro de la mesa hasta el mazo) que recorren las
  /// cartas al ser recogidas.
  final Offset collectOffset;
  final Duration collectDuration;

  @override
  Widget build(BuildContext context) {
    final v = view;
    if (v == null) return const SizedBox.shrink();

    // Terminada la mano (y ya recogidas las cartas) la mesa queda vacía.
    if (v.finished && phase == RoundCollectPhase.none) {
      return const SizedBox.shrink();
    }

    final visible = v.table.skip(collectedRounds).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    // FittedBox garantiza que la ronda siempre entre en el espacio disponible
    // (en pantallas muy bajas las cartas se achican en lugar de desbordar).
    Widget content = FittedBox(
      fit: BoxFit.scaleDown,
      child: _RoundColumn(
        r: visible.last,
        me: v.me,
        cardW: cardW,
        cardH: cardH,
        cardGap: 8,
      ),
    );

    if (phase == RoundCollectPhase.collecting) {
      content = TweenAnimationBuilder<double>(
        key: ValueKey('collect-$collectedRounds'),
        tween: Tween<double>(begin: 0, end: 1),
        duration: collectDuration,
        curve: Curves.easeInCubic,
        builder: (context, t, child) => Transform.translate(
          offset: collectOffset * t,
          child: Transform.scale(
            scale: 1 - 0.65 * t,
            child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: child),
          ),
        ),
        child: content,
      );
    }
    return content;
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
