import 'package:flutter/material.dart';
import 'package:truco_client/features/game/controller/speech_bubbles.dart';

/// Globo de texto con cola. El del rival es blanco; el tuyo, crema.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.msg,
    required this.isMine,
    required this.tailUp,
    required this.maxWidth,
  });

  final BubbleMsg msg;
  final bool isMine;
  final bool tailUp;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isMe = isMine;
    final bg = isMe ? const Color(0xFFFFF1B8) : Colors.white;
    final tail = CustomPaint(
      size: const Size(18, 10),
      painter: _BubbleTailPainter(color: bg, up: tailUp),
    );
    return Semantics(
      liveRegion: true,
      label: '${isMe ? 'Vos' : 'El Bot'}: ${msg.text}',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(msg.id),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.7 + 0.3 * t,
              alignment: tailUp ? Alignment.topCenter : Alignment.bottomCenter,
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tailUp) tail,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14231B),
                    ),
                  ),
                ),
                if (!tailUp) tail,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cola triangular del globo de texto (apunta hacia arriba o hacia abajo).
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool up;
  const _BubbleTailPainter({required this.color, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) =>
      old.color != color || old.up != up;
}
