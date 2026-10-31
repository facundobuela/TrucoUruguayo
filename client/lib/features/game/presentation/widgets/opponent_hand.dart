import 'package:flutter/material.dart';

/// Cartas tapadas del rival, en abanico.
class OpponentHand extends StatelessWidget {
  const OpponentHand({
    super.key,
    required this.count,
    required this.width,
    required this.height,
  });

  final int count;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    // Cartas del bot en abanico: la primera rotada a la izquierda,
    // la del medio recta, la tercera a la derecha (como en la imagen de ref.)
    // Ángulos en radianes para count = 1,2,3
    final List<double> angles = switch (count) {
      1 => [0.0],
      2 => [-0.14, 0.14],
      _ => [-0.22, 0.0, 0.22],
    };

    // Spread horizontal: cada carta se separa un poco
    final double spread = width * 0.55;
    final totalW = width + (count - 1) * spread;
    final totalH = height + 20; // extra para la rotación

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(count, (index) {
          final angle = angles[index];
          final left = index * spread;
          return Positioned(
            bottom: 0,
            left: left,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white30, width: 1),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(1, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/cards/reverso.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF8B2500)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
