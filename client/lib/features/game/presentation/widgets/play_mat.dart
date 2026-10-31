import 'dart:math';

import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/controller/speech_bubbles.dart';

import 'deck_with_sample.dart';
import 'opponent_hand.dart';
import 'speech_bubble.dart';
import 'table_rounds.dart';

/// Tapete: arriba el mazo con la muestra (izquierda) y la mano del rival
/// (centro); debajo, las rondas jugadas; encima, globos y cartel de fin de mano.
class PlayMat extends StatelessWidget {
  const PlayMat({
    super.key,
    required this.view,
    required this.effectiveW,
    required this.bubble,
    required this.isMatchOver,
    required this.matchWinner,
    required this.onNextHand,
    required this.onNewMatch,
  });

  final HandView? view;

  /// Ancho útil de la pantalla (acotado) usado para dimensionar las cartas.
  final double effectiveW;
  final BubbleMsg? bubble;
  final bool isMatchOver;
  final Seat? matchWinner;
  final VoidCallback onNextHand;
  final VoidCallback onNewMatch;

  @override
  Widget build(BuildContext context) {
    final me = view?.me ?? Seat.a;
    return LayoutBuilder(
      builder: (context, matConstraints) {
        final matH = matConstraints.maxHeight;
        final matW = matConstraints.maxWidth;

        // --- Banda superior: [mazo + muestra] a la izquierda, mano del bot al centro.
        final botCardW = (effectiveW * 0.15).clamp(50.0, 66.0);
        final botCardH = botCardW * 1.48;
        final botHandH = botCardH + 20; // + margen por la rotación del abanico

        final deckCardW = (effectiveW * 0.17).clamp(54.0, 72.0);
        final deckCardH = deckCardW * 1.48;
        final deckH = deckCardH + 12; // + grosor del mazo

        const bandPadTop = 8.0;
        final bandH = max(botHandH, deckH) + bandPadTop + 8;

        // --- Zona de cartas jugadas: todo el ancho y el alto restante.
        const roundGap = 16.0;
        const cardGap = 8.0;
        const labelH = 22.0; // texto de resultado + separación
        final availH = (matH - bandH - 12).clamp(80.0, 600.0);
        var tableCardH = ((availH - cardGap - labelH) / 2).clamp(52.0, 150.0);
        var tableCardW = tableCardH / 1.48;
        // Que entren las 3 rondas a lo ancho sin scroll.
        final maxCardWByWidth = (matW - 24 - 2 * roundGap) / 3;
        if (tableCardW > maxCardWByWidth) {
          tableCardW = maxCardWByWidth.clamp(30.0, 110.0);
          tableCardH = tableCardW * 1.48;
        }

        return Stack(
          children: [
            // Arriba a la izquierda: MAZO con la MUESTRA asomando por debajo.
            if (view != null)
              Positioned(
                top: bandPadTop,
                left: 10,
                child: DeckWithSample(sample: view!.sample, cardW: deckCardW, cardH: deckCardH),
              ),

            // Arriba al centro: cartas tapadas del BOT (su lado de la mesa).
            Positioned(
              top: bandPadTop,
              left: 0,
              right: 0,
              child: Center(
                child: OpponentHand(count: view?.opponentCardsLeft ?? 0, width: botCardW, height: botCardH),
              ),
            ),

            // Centro del tapete: rondas jugadas (bot arriba, vos abajo).
            Positioned(
              top: bandH,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: TableRounds(view: view, cardW: tableCardW, cardH: tableCardH),
              ),
            ),

            // Globo de texto de quien está hablando (rival arriba, vos abajo).
            if (bubble != null)
              bubble!.seat == me.other
                  ? Positioned(
                      top: bandH - 6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SpeechBubble(msg: bubble!, isMine: false, tailUp: true, maxWidth: matW * 0.7),
                      ),
                    )
                  : Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SpeechBubble(msg: bubble!, isMine: true, tailUp: false, maxWidth: matW * 0.7),
                      ),
                    ),

            // Cartel de fin de mano o de partida
            if (view != null && view!.finished)
              Center(
                child: Card(
                  color: const Color(0xEE0A1811),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMatchOver
                              ? (matchWinner == me ? '¡GANASTE EL PARTIDO!' : 'PERDISTE EL PARTIDO')
                              : 'Mano Finalizada',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(140, 44),
                          ),
                          onPressed: isMatchOver ? onNewMatch : onNextHand,
                          child: Text(
                            isMatchOver ? 'Nueva Partida' : 'Siguiente Mano',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
