import 'dart:math';

import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';
import 'package:truco_client/features/game/controller/speech_bubbles.dart';

import 'deck_with_sample.dart';
import 'opponent_hand.dart';
import 'round_results_strip.dart';
import 'speech_bubble.dart';
import 'table_rounds.dart';

/// Tapete: el mazo con la muestra cambia de lado según quién reparte; la mano
/// del rival va arriba al centro y, debajo, la ronda en juego. Al resolverse una
/// ronda, sus cartas viajan al mazo.
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
    this.collectedRounds = 0,
    this.roundPhase = RoundCollectPhase.none,
    this.collectDuration = const Duration(milliseconds: 400),
    this.playerThrowDx = 0,
  });

  final HandView? view;

  /// Ancho útil de la pantalla (acotado) usado para dimensionar las cartas.
  final double effectiveW;
  final BubbleMsg? bubble;
  final bool isMatchOver;
  final Seat? matchWinner;
  final VoidCallback onNextHand;
  final VoidCallback onNewMatch;

  /// Rondas ya recogidas al mazo (no se dibujan sobre la mesa).
  final int collectedRounds;

  /// Fase de la recogida de la última ronda resuelta.
  final RoundCollectPhase roundPhase;
  final Duration collectDuration;

  /// Desplazamiento horizontal, respecto del centro, de la carta que acabás de
  /// tocar en tu mano: desde ahí sale volando hacia la mesa.
  final double playerThrowDx;

  @override
  Widget build(BuildContext context) {
    final me = view?.me ?? Seat.a;
    return LayoutBuilder(
      builder: (context, matConstraints) {
        final matH = matConstraints.maxHeight;
        final matW = matConstraints.maxWidth;

        // En pantallas muy bajas se achican el mazo y la mano del rival.
        final fit = (matH / 340).clamp(0.6, 1.0);

        // --- Mazo y muestra: a la izquierda del jugador cuando reparte el bot.
        final botCardW = (effectiveW * 0.15).clamp(50.0, 66.0) * fit;
        final botCardH = botCardW * 1.48;
        final botHandH = botCardH + 20; // + margen por la rotación del abanico

        final deckCardW = (effectiveW * 0.17).clamp(54.0, 72.0) * fit;
        final deckCardH = deckCardW * 1.48;
        final deckH = deckCardH + 12; // + grosor del mazo
        final deckWidgetH =
            deckH + (view?.sample.sampleIsPiece == true ? 18 : 0);
        final botDeals = view != null && view!.mano == me;
        final deckTop = min(
          matH * (botDeals ? 0.61 : 0.35),
          max(0.0, matH - deckWidgetH),
        );

        const bandPadTop = 8.0;
        final bandH = max(botHandH, deckH) + bandPadTop + 8;

        // --- Zona de la ronda en juego: una sola columna (rival arriba, vos
        // abajo). Como las cartas se recogen al mazo, puede ser bien grande.
        const cardGap = 8.0;
        const labelH = 22.0; // texto de resultado + separación
        final availH = max(0.0, matH - bandH - 12);
        final tableCardH = ((availH - cardGap - labelH) / 2).clamp(40.0, 165.0);
        final tableCardW = tableCardH / 1.48;

        // Hacia dónde viajan las cartas al recogerse: el dorso superior del mazo
        // (DeckWithSample mide 1.68 veces el ancho de una carta).
        const deckInset = 10.0;
        final deckWidgetW = deckCardW * 1.68;
        final deckPileCenter = Offset(
          botDeals
              ? matW - deckInset - deckWidgetW + deckCardW / 2
              : deckInset + deckCardW / 2,
          deckTop + deckCardH / 2,
        );
        final tableCenter = Offset(matW / 2, bandH + (matH - bandH) / 2);
        final collectOffset = deckPileCenter - tableCenter;

        // Desde dónde llegan las cartas tiradas: la mano del rival (arriba) y
        // tu mano (debajo del tapete, detrás de la botonera).
        final cardHalfStep = (tableCardH + cardGap) / 2;
        final topCardCenterY = tableCenter.dy - cardHalfStep;
        final bottomCardCenterY = tableCenter.dy + cardHalfStep;
        final botHandCenterY = bandPadTop + botCardH / 2 + 10;
        final playerHandCenterY = matH + 110;
        final botThrowFrom = Offset(0, botHandCenterY - topCardCenterY);
        final playerThrowFrom = Offset(
          playerThrowDx,
          playerHandCenterY - bottomCardCenterY,
        );

        return Stack(
          // Sin recorte: la carta que tirás sale desde debajo del tapete.
          clipBehavior: Clip.none,
          children: [
            // El repartidor queda del lado opuesto al mano; mover juntos mazo y
            // muestra mantiene visible la carta en el lado desde donde reparte.
            if (view != null)
              Positioned(
                top: deckTop,
                left: botDeals ? null : 10,
                right: botDeals ? 10 : null,
                child: DeckWithSample(
                  sample: view!.sample,
                  cardW: deckCardW,
                  cardH: deckCardH,
                ),
              ),

            // Arriba al centro: cartas tapadas del BOT (su lado de la mesa).
            Positioned(
              top: bandPadTop,
              left: 0,
              right: 0,
              child: Center(
                child: OpponentHand(
                  count: view?.opponentCardsLeft ?? 0,
                  width: botCardW,
                  height: botCardH,
                ),
              ),
            ),

            // Arriba a la derecha: resultado de cada ronda (las cartas se recogen).
            if (view != null)
              Positioned(
                top: bandPadTop,
                right: 10,
                child: RoundResultsStrip(view: view!),
              ),

            // Centro del tapete: ronda en juego (bot arriba, vos abajo).
            Positioned(
              top: bandH,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: TableRounds(
                  view: view,
                  cardW: tableCardW,
                  cardH: tableCardH,
                  collectedRounds: collectedRounds,
                  phase: roundPhase,
                  collectOffset: collectOffset,
                  collectDuration: collectDuration,
                  botThrowFrom: botThrowFrom,
                  playerThrowFrom: playerThrowFrom,
                ),
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
                        child: SpeechBubble(
                          msg: bubble!,
                          isMine: false,
                          tailUp: true,
                          maxWidth: matW * 0.7,
                        ),
                      ),
                    )
                  : Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SpeechBubble(
                          msg: bubble!,
                          isMine: true,
                          tailUp: false,
                          maxWidth: matW * 0.7,
                        ),
                      ),
                    ),

            // Cartel de fin de mano o de partida (una vez despejada la mesa)
            if (view != null &&
                view!.finished &&
                roundPhase == RoundCollectPhase.none)
              Center(
                child: Card(
                  color: const Color(0xEE0A1811),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isMatchOver
                              ? (matchWinner == me
                                    ? '¡GANASTE EL PARTIDO!'
                                    : 'PERDISTE EL PARTIDO')
                              : 'Mano Finalizada',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            minimumSize: const Size(140, 44),
                          ),
                          onPressed: isMatchOver ? onNewMatch : onNextHand,
                          child: Text(
                            isMatchOver ? 'Nueva Partida' : 'Siguiente Mano',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
