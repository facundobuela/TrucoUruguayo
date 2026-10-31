import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

/// Carta de la baraja española boca arriba (usa `assets/cards/<n>_<palo>.png`).
class PlayingCardFace extends StatelessWidget {
  const PlayingCardFace(
    this.card, {
    super.key,
    required this.width,
    required this.height,
    this.isSample = false,
    this.isPlayable = false,
  });

  final TrucoCard card;
  final double width;
  final double height;
  final bool isSample;
  final bool isPlayable;

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/cards/${card.number}_${card.suit.name}.png';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPlayable
              ? Colors.amberAccent
              : (isSample ? Colors.amber : Colors.black26),
          width: isPlayable ? 3.0 : (isSample ? 2.2 : 1.0),
        ),
        boxShadow: [
          if (isPlayable)
            const BoxShadow(color: Colors.amberAccent, blurRadius: 8, spreadRadius: 1)
          else
            const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
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

/// Dorso de carta (`assets/cards/reverso.png`) con borde y sombra opcional.
class CardBack extends StatelessWidget {
  const CardBack({
    super.key,
    required this.width,
    required this.height,
    this.shadow = true,
  });

  final double width;
  final double height;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white54, width: 1),
        boxShadow: shadow
            ? const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(1, 2))]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/cards/reverso.png',
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: const Color(0xFF8B2500)),
      ),
    );
  }
}
