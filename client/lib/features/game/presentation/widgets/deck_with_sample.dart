import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/text/game_texts.dart';

import 'playing_card.dart';

/// Mazo de cartas tapadas con la MUESTRA boca arriba asomando por debajo,
/// inclinada, como en una mesa real. Tocar el mazo amplía la muestra.
class DeckWithSample extends StatelessWidget {
  const DeckWithSample({
    super.key,
    required this.sample,
    required this.cardW,
    required this.cardH,
  });

  final Sample sample;
  final double cardW;
  final double cardH;

  @override
  Widget build(BuildContext context) {
    const layers = 3; // bordes visibles que simulan el grosor del mazo
    const layerStep = 2.0;
    final totalW = cardW * 1.68;
    final totalH = cardH + layers * layerStep;

    return Semantics(
      button: true,
      label: 'Muestra: ${GameTexts.cardName(sample.card)}. Tocá para ampliar.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showSampleDialog(context, sample),
        child: SizedBox(
          width: totalW,
          height: totalH + (sample.sampleIsPiece ? 18 : 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Muestra: boca arriba, inclinada, asomando por la derecha/arriba.
              Positioned(
                left: cardW * 0.55,
                top: 0,
                child: Transform.rotate(
                  angle: 0.26,
                  child: PlayingCardFace(
                    sample.card,
                    width: cardW,
                    height: cardH,
                    isSample: true,
                  ),
                ),
              ),

              // Grosor del mazo: bordes blancos desplazados hacia abajo.
              for (var k = layers; k >= 1; k--)
                Positioned(
                  left: 0,
                  top: k * layerStep,
                  child: Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8DC),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.black26, width: 1),
                    ),
                  ),
                ),

              // Dorso superior del mazo.
              Positioned(left: 0, top: 0, child: CardBack(width: cardW, height: cardH)),

              // Si la muestra es una pieza, el 12 del palo toma su lugar.
              if (sample.sampleIsPiece)
                Positioned(
                  left: 0,
                  top: totalH + 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '12 = ${sample.card.number}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo con la muestra en grande y la explicación de las piezas.
  static void showSampleDialog(BuildContext context, Sample sample) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xEE0A1811),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'MUESTRA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              PlayingCardFace(sample.card, width: 150, height: 222, isSample: true),
              const SizedBox(height: 10),
              Text(
                GameTexts.cardName(sample.card),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                sample.sampleIsPiece
                    ? 'Es una pieza: el 12 de ${sample.suit.displayName} toma su lugar.'
                    : 'Las piezas son el 2, 4, 5, 11 y 10 de ${sample.suit.displayName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
