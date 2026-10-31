import 'package:flutter/material.dart';

/// Barra con el último hecho relevante de la partida.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.message, required this.isThinking});

  final String message;

  /// Si es `true` muestra "El Bot está pensando..." en lugar del mensaje.
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: Colors.black26,
      child: Text(
        isThinking ? 'El Bot está pensando...' : message,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
