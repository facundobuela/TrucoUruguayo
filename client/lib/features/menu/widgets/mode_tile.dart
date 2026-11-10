import 'package:flutter/material.dart';

import '../../modes/game_mode.dart';

/// Ícono que representa a un modo de juego.
IconData modeIcon(GameMode mode) {
  if (mode.ranked) return Icons.emoji_events;
  if (mode.opponent == OpponentKind.bot) return Icons.smart_toy;
  return mode.playersPerTeam == 1 ? Icons.person : Icons.groups;
}

/// Aviso de que un modo todavía no se puede jugar.
void showComingSoon(BuildContext context, GameMode mode, {String? message}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message ?? '${mode.title}: próximamente'),
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Fila del menú de modos. Los modos que todavía no están disponibles se ven
/// atenuados y con la etiqueta "Próximamente", pero se pueden tocar (avisan).
class ModeTile extends StatelessWidget {
  const ModeTile({super.key, required this.mode, required this.onTap});

  final GameMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = mode.isPlayable;
    return Semantics(
      button: true,
      enabled: enabled,
      label:
          '${mode.title}. ${mode.subtitle}${enabled ? '' : '. Próximamente'}',
      child: ExcludeSemantics(
        child: Material(
          color: const Color(0xFF142E21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: enabled ? Colors.amber : Colors.white24,
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Opacity(
              opacity: enabled ? 1 : 0.6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: Icon(
                        modeIcon(mode),
                        color: enabled ? Colors.amber : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                mode.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!enabled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Próximamente',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (enabled)
                      const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
