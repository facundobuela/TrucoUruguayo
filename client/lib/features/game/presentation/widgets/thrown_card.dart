import 'dart:math';

import 'package:flutter/material.dart';

/// Hace que [child] se "tire" sobre la mesa: viaja desde [from] (desplazamiento
/// respecto de su posición final) girando apenas y con un pequeño salto al
/// aterrizar. Si se indica [back], la carta llega dada vuelta: arranca de
/// dorso y se da vuelta en el aire (así llegan las cartas del rival).
///
/// La animación corre una sola vez, cuando el widget entra al árbol.
class ThrownCard extends StatefulWidget {
  const ThrownCard({
    super.key,
    required this.child,
    required this.from,
    this.fromAngle = 0,
    this.back,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;

  /// Dónde arranca la carta, relativo a su posición final.
  final Offset from;

  /// Inclinación inicial (radianes) que se va corrigiendo hasta quedar derecha.
  final double fromAngle;

  /// Dorso de la carta; si no es null, la carta se da vuelta mientras viaja.
  final Widget? back;
  final Duration duration;

  @override
  State<ThrownCard> createState() => _ThrownCardState();
}

class _ThrownCardState extends State<ThrownCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final move = Curves.easeOutCubic.transform(t);
        final lift = sin(pi * t); // 0 -> 1 -> 0: la carta "salta" y aterriza

        Widget card = child!;
        if (widget.back != null) {
          // La vuelta ocupa el primer 70 % del recorrido.
          final flip = (t / 0.7).clamp(0.0, 1.0);
          final angleY = pi * (1 - Curves.easeInOut.transform(flip));
          final showBack = angleY > pi / 2;
          card = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angleY),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: widget.back,
                  )
                : child,
          );
        }

        return Transform.translate(
          offset: widget.from * (1 - move),
          child: Transform.rotate(
            angle: widget.fromAngle * (1 - move),
            child: Transform.scale(scale: 1 + 0.10 * lift, child: card),
          ),
        );
      },
    );
  }
}
