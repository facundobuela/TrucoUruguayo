import 'package:flutter/material.dart';

import 'features/game/audio/game_audio.dart';
import 'features/game/presentation/game_screen.dart';

/// Aplicación raíz: tema oscuro verde paño y pantalla de juego.
///
/// [audio] es el sonido de la partida; si no se indica, la partida es muda
/// (así funcionan los tests, que no tienen plugins de audio).
class TrucoApp extends StatelessWidget {
  const TrucoApp({super.key, this.audio});

  final GameAudio? audio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truco Uruguayo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        fontFamily: 'sans-serif',
      ),
      home: GameScreen(audio: audio),
    );
  }
}
