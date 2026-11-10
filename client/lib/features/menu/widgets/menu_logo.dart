import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

import '../../game/presentation/widgets/playing_card.dart';

/// Logo del menú: las cuatro matas (1 de Espada, 1 de Basto, 7 de Espada y
/// 7 de Oro) abiertas en abanico.
class MenuLogo extends StatelessWidget {
  const MenuLogo({super.key});

  static final List<TrucoCard> _matas = [
    TrucoCard(1, Suit.espada),
    TrucoCard(1, Suit.basto),
    TrucoCard(7, Suit.espada),
    TrucoCard(7, Suit.oro),
  ];

  static const _angles = [-0.30, -0.10, 0.10, 0.30];
  static const _tops = [20.0, 6.0, 6.0, 20.0];

  @override
  Widget build(BuildContext context) {
    const cardW = 80.0;
    const cardH = cardW * 1.48;
    return ExcludeSemantics(
      child: SizedBox(
        width: 280,
        height: cardH + 36,
        child: Stack(
          children: [
            for (var i = 0; i < _matas.length; i++)
              Positioned(
                left: 27.0 + i * 52,
                top: _tops[i],
                child: Transform.rotate(
                  angle: _angles[i],
                  child: PlayingCardFace(
                    _matas[i],
                    width: cardW,
                    height: cardH,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
