import 'package:flutter/material.dart';

import '../game/presentation/game_screen.dart';
import '../menu/widgets/mode_tile.dart';
import '../modes/game_mode.dart';
import '../modes/game_session_factory.dart';
import 'ranked_service.dart';

/// "Partidas Elo": perfil del jugador y modos clasificatorios.
///
/// Es la estructura lista para cuando exista el servidor: hoy el
/// [RankedService] por defecto está "no disponible" y la pantalla lo explica.
class RankedScreen extends StatefulWidget {
  const RankedScreen({super.key, required this.rankedService});

  final RankedService rankedService;

  @override
  State<RankedScreen> createState() => _RankedScreenState();
}

class _RankedScreenState extends State<RankedScreen> {
  late final Future<RankedProfile?> _profile = widget.rankedService
      .loadProfile();

  Future<void> _open(GameMode mode) async {
    switch (widget.rankedService.availability) {
      case RankedAvailability.unavailable:
        showComingSoon(context, mode);
        return;
      case RankedAvailability.needsAccount:
        showComingSoon(
          context,
          mode,
          message:
              'Necesitás una cuenta registrada para jugar clasificatorias.',
        );
        return;
      case RankedAvailability.ready:
        break;
    }
    try {
      final controller = await widget.rankedService.findMatch(mode);
      if (!mounted) {
        controller.dispose();
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            title: mode.title,
            controller: controller,
            disposeController: true,
          ),
        ),
      );
    } on ModeNotAvailableException {
      if (mounted) showComingSoon(context, mode);
    }
  }

  String _statusText() {
    switch (widget.rankedService.availability) {
      case RankedAvailability.unavailable:
        return 'Las partidas clasificatorias estarán disponibles pronto.';
      case RankedAvailability.needsAccount:
        return 'Iniciá sesión con una cuenta para jugar clasificatorias.';
      case RankedAvailability.ready:
        return 'Jugá tu primera partida clasificatoria.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B2B),
      appBar: AppBar(
        title: const Text(
          'Partidas Elo',
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
                _ProfileCard(
                  profileFuture: _profile,
                  statusText: _statusText(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Modos clasificatorios',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                for (final mode in GameModes.rankedModes) ...[
                  ModeTile(mode: mode, onTap: () => _open(mode)),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                const _RankedRules(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profileFuture, required this.statusText});

  final Future<RankedProfile?> profileFuture;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF142E21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: FutureBuilder<RankedProfile?>(
        future: profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final loading = snapshot.connectionState != ConnectionState.done;
          return Column(
            children: [
              const Text(
                'Tu Elo',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                profile == null ? '—' : '${profile.rating}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loading
                    ? 'Cargando...'
                    : profile == null
                    ? statusText
                    : '${profile.gamesPlayed} partidas · ${profile.wins} ganadas · '
                          '${profile.losses} perdidas · '
                          '${(profile.winRate * 100).round()} % de victorias',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RankedRules extends StatelessWidget {
  const _RankedRules();

  @override
  Widget build(BuildContext context) {
    const lines = [
      'Se juegan online contra otras personas.',
      'Requieren una cuenta registrada.',
      'Las partidas contra el Bot no suman Elo.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cómo funcionan',
          style: TextStyle(fontSize: 15, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: Colors.white54)),
                Expanded(
                  child: Text(
                    l,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
