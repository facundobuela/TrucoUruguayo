import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/text/game_texts.dart';

import 'playing_card.dart';

/// Tus cartas, abajo. Sólo se pueden tocar las que son jugables ahora.
class PlayerHand extends StatelessWidget {
  const PlayerHand({
    super.key,
    required this.view,
    required this.cardW,
    required this.cardH,
    required this.onPlay,
  });

  final HandView? view;
  final double cardW;
  final double cardH;
  final void Function(TrucoCard card) onPlay;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final cards = v?.myCards ?? const <TrucoCard>[];
    final legalActions = v?.legalActions ?? const <GameAction>[];
    final sample = v?.sample;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(top: BorderSide(color: Colors.black45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards.map((c) {
          final canPlay = legalActions.contains(PlayCardAction(c));
          final role = sample?.classify(c);

          return GestureDetector(
            onTap: canPlay ? () => onPlay(c) : null,
            child: Container(
              width: cardW,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayingCardFace(c, width: cardW, height: cardH, isPlayable: canPlay),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: cardW,
                    height: 18,
                    child: Text(
                      role != null ? GameTexts.cardRole(role) : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: role != null && role.isPiece ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
