import 'package:flutter/material.dart';

import '../modes/game_session_factory.dart';
import '../ranked/ranked_screen.dart';
import '../ranked/ranked_service.dart';
import 'play_modes_screen.dart';
import 'widgets/menu_button.dart';
import 'widgets/menu_logo.dart';

/// Pantalla de inicio: Jugar y Partidas Elo.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.sessionFactory,
    required this.rankedService,
  });

  final GameSessionFactory sessionFactory;
  final RankedService rankedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B2B),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const MenuLogo(),
                        const SizedBox(height: 12),
                        const Text(
                          'TRUCO URUGUAYO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Jugá al truco de siempre',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 32),
                        MenuButton(
                          label: 'Jugar',
                          icon: Icons.play_arrow_rounded,
                          primary: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlayModesScreen(
                                sessionFactory: sessionFactory,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        MenuButton(
                          label: 'Partidas Elo',
                          icon: Icons.emoji_events,
                          badge: 'Próximamente',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  RankedScreen(rankedService: rankedService),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
