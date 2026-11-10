import 'package:flutter/material.dart';

import 'features/game/audio/game_audio.dart';
import 'features/menu/main_menu_screen.dart';
import 'features/modes/game_session_factory.dart';
import 'features/ranked/ranked_service.dart';

/// Aplicación raíz: tema oscuro verde paño y menú principal.
///
/// - [audio]: sonido de las partidas; sin él las partidas son mudas (así
///   funcionan los tests, que no tienen plugins de audio).
/// - [sessionFactory]: cómo se arma la partida de cada modo.
/// - [rankedService]: partidas clasificatorias (hoy no disponible).
class TrucoApp extends StatelessWidget {
  const TrucoApp({
    super.key,
    this.audio,
    this.sessionFactory,
    this.rankedService,
  });

  final GameAudio? audio;
  final GameSessionFactory? sessionFactory;
  final RankedService? rankedService;

  /// Tema de toda la app (también lo usan los tests de la pantalla de juego).
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.green,
    fontFamily: 'sans-serif',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truco Uruguayo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: MainMenuScreen(
        sessionFactory:
            sessionFactory ?? DefaultGameSessionFactory(audio: audio),
        rankedService: rankedService ?? const UnavailableRankedService(),
      ),
    );
  }
}
