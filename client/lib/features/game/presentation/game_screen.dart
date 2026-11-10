import 'dart:math';

import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
import 'package:truco_client/features/game/audio/game_audio.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';

import 'widgets/action_bar.dart';
import 'widgets/play_mat.dart';
import 'widgets/player_hand.dart';
import 'widgets/score_board.dart';
import 'widgets/status_bar.dart';

/// Pantalla de juego: arma los widgets a partir del [GameController].
///
/// Si no se le pasa un [controller] crea (y libera) un
/// `OfflineGameController`: partida local contra el bot.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.controller,
    this.audio,
    this.title = 'Truco Uruguayo',
    this.disposeController = false,
  });

  final GameController? controller;

  /// Título de la barra superior (p. ej. el nombre del modo de juego).
  final String title;

  /// Si es `true`, la pantalla libera el [controller] recibido al cerrarse
  /// (lo usa el menú, que crea el controlador pero no lo conserva).
  final bool disposeController;

  /// Audio para el controlador que se crea por defecto (se ignora si se pasa
  /// un [controller]). Sin audio la partida es muda.
  final GameAudio? audio;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final bool _ownsController;

  /// Desplazamiento horizontal (respecto del centro de la mano) de la última
  /// carta tocada: de ahí sale volando la carta hacia la mesa.
  double _playerThrowDx = 0;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null || widget.disposeController;
    _controller =
        widget.controller ?? OfflineGameController(audio: widget.audio);
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Vuelve al menú (si esta pantalla se abrió desde él).
  void _exitToMenu() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  /// Pide confirmación antes de abandonar una partida en curso.
  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Abandonar la partida?'),
        content: const Text('Se perderá el progreso de esta partida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir jugando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _exitToMenu();
  }

  void _perform(GameAction action) {
    final error = _controller.perform(action);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final view = _controller.view;
        final isPlayerTurn = _controller.isPlayerTurn;
        final legalActions = view != null && !view.finished
            ? view.legalActions
            : const <GameAction>[];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _confirmExit();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF1B3B2B), // Verde paño
            appBar: AppBar(
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xFF0F241A),
              elevation: 2,
              actions: [
                IconButton(
                  icon: Icon(
                    _controller.soundEnabled
                        ? Icons.volume_up
                        : Icons.volume_off,
                  ),
                  tooltip: _controller.soundEnabled
                      ? 'Silenciar sonido'
                      : 'Activar sonido',
                  onPressed: _controller.toggleSound,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reiniciar partida',
                  onPressed: _controller.startNewMatch,
                ),
              ],
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;
                  final screenH = constraints.maxHeight;
                  final isCompactH = screenH < 700;

                  // Medidas responsivas para las cartas del jugador
                  final effectiveW = min(screenW, 480.0);
                  final playerCardW = isCompactH
                      ? (effectiveW * 0.22).clamp(72.0, 92.0)
                      : (effectiveW * 0.25).clamp(86.0, 112.0);
                  final playerCardH = playerCardW * 1.48;

                  return Column(
                    children: [
                      // 1. Marcador superior
                      ScoreBoard(
                        view: view,
                        handNumber: _controller.handNumber,
                        isCompact: isCompactH,
                      ),

                      // 2. Barra de estado legible
                      StatusBar(
                        message: _controller.statusMessage,
                        isThinking: _controller.isOpponentThinking,
                      ),

                      // 3. Tapete central (mazo, rival, rondas, globos)
                      Expanded(
                        child: PlayMat(
                          view: view,
                          effectiveW: effectiveW,
                          bubble: _controller.activeBubble,
                          isMatchOver: _controller.isMatchOver,
                          matchWinner: _controller.matchWinner,
                          onNextHand: _controller.startNextHand,
                          onNewMatch: _controller.startNewMatch,
                          collectedRounds: _controller.collectedRounds,
                          roundPhase: _controller.roundPhase,
                          collectDuration: _controller.roundCollectDuration,
                          playerThrowDx: _playerThrowDx,
                          onExitToMenu: Navigator.of(context).canPop()
                              ? _exitToMenu
                              : null,
                        ),
                      ),

                      // 4. Botonera de acciones (Quiero, Envido, Truco, Mazo)
                      if (isPlayerTurn)
                        ActionBar(
                          legalActions: legalActions,
                          onAction: _perform,
                          isCompact: isCompactH,
                        ),

                      // 5. Cartas de mi mano (abajo)
                      PlayerHand(
                        view: view,
                        cardW: playerCardW,
                        cardH: playerCardH,
                        onPlay: (card) {
                          final cards = view?.myCards ?? const <TrucoCard>[];
                          final i = cards.indexOf(card);
                          if (i >= 0) {
                            // Cada carta mide su ancho + 8 px de margen.
                            _playerThrowDx =
                                (i - (cards.length - 1) / 2) *
                                (playerCardW + 8);
                          }
                          _perform(PlayCardAction(card));
                        },
                        enabled: isPlayerTurn,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
