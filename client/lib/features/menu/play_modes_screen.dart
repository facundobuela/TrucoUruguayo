import 'package:flutter/material.dart';

import '../game/presentation/game_screen.dart';
import '../modes/game_mode.dart';
import '../modes/game_session_factory.dart';
import 'widgets/mode_tile.dart';

/// "Jugar": elegir el modo. Sólo los modos disponibles abren una partida.
class PlayModesScreen extends StatelessWidget {
  const PlayModesScreen({super.key, required this.sessionFactory});

  final GameSessionFactory sessionFactory;

  void _open(BuildContext context, GameMode mode) {
    if (!mode.isPlayable) {
      showComingSoon(context, mode);
      return;
    }
    try {
      final controller = sessionFactory.create(mode);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            title: mode.title,
            controller: controller,
            disposeController: true,
          ),
        ),
      );
    } on ModeNotAvailableException {
      showComingSoon(context, mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B2B),
      appBar: AppBar(
        title: const Text(
          'Jugar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F241A),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Elegí cómo querés jugar',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ),
                for (final mode in GameModes.casual) ...[
                  ModeTile(mode: mode, onTap: () => _open(context, mode)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
