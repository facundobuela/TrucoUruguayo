import 'package:flutter/material.dart';
import 'package:truco_client/app.dart';
import 'package:truco_client/features/game/audio/game_audio.dart';
import 'package:truco_client/features/game/presentation/game_screen.dart';

/// App mínima para probar la pantalla de juego directamente (sin pasar por el
/// menú), con el mismo tema que la app real.
class GameTestApp extends StatelessWidget {
  const GameTestApp({super.key, this.audio});

  final GameAudio? audio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: TrucoApp.theme,
      home: GameScreen(audio: audio),
    );
  }
}
