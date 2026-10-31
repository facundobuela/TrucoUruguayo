import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/text/game_texts.dart';

/// Botonera de cantos y respuestas, armada con las acciones legales.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.legalActions,
    required this.onAction,
    required this.isCompact,
  });

  final List<GameAction> legalActions;
  final void Function(GameAction action) onAction;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final calls = legalActions
        .whereType<CallAction>()
        .map((a) => a.bet)
        .toList();
    final responds = legalActions
        .whereType<RespondAction>()
        .map((a) => a.response)
        .toList();
    final canFold = legalActions.contains(const FoldAction());

    if (calls.isEmpty && responds.isEmpty && !canFold) {
      return const SizedBox.shrink();
    }

    final actionButtons = <Widget>[
      for (final c in calls.where((b) => b.isFlor))
        _ActionButton(
          label: GameTexts.betName(c),
          color: Colors.purple[800]!,
          onPressed: () => onAction(CallAction(c)),
        ),
      for (final c in calls.where((b) => b.isEnvido))
        _ActionButton(
          label: GameTexts.betName(c),
          color: const Color(0xFF1565C0),
          onPressed: () => onAction(CallAction(c)),
        ),
      for (final c in calls.where((b) => b.isTruco))
        _ActionButton(
          label: GameTexts.betName(c),
          color: const Color(0xFFE65100),
          isBold: true,
          onPressed: () => onAction(CallAction(c)),
        ),
      if (canFold)
        OutlinedButton.icon(
          icon: const Icon(
            Icons.flag_outlined,
            size: 16,
            color: Colors.redAccent,
          ),
          label: const Text(
            'Al Mazo',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => onAction(const FoldAction()),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xEE0D2117),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Respuestas prominentes (Quiero / No Quiero / Con Flor me achico)
          if (responds.isNotEmpty) ...[
            Row(
              children: [
                for (final r in responds)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: r == BetResponse.quiero
                              ? const Color(0xFF2E7D32)
                              : (r == BetResponse.noQuiero
                                    ? const Color(0xFFC62828)
                                    : Colors.deepPurple),
                          minimumSize: const Size(
                            0,
                            46,
                          ), // Zona táctil mínima >= 44 px
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => onAction(RespondAction(r)),
                        child: Text(
                          GameTexts.betResponseName(r).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (calls.isNotEmpty) const SizedBox(height: 6),
          ],

          // 2. Cantos e Irse al mazo organizados con Wrap responsivo
          if (calls.isNotEmpty || canFold)
            isCompact
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < actionButtons.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          actionButtons[i],
                        ],
                      ],
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actionButtons,
                  ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isBold = false,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 44), // Zona táctil mínima >= 44 px
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isBold ? 3 : 1,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
