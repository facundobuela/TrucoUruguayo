import 'package:flutter/material.dart';

import 'features/game/presentation/game_screen.dart';

/// Aplicación raíz: tema oscuro verde paño y pantalla de juego.
class TrucoApp extends StatelessWidget {
  const TrucoApp({super.key});

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
      home: const GameScreen(),
    );
  }
}
