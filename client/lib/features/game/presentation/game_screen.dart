import 'dart:math';

import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';
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
  const GameScreen({super.key, this.controller});

  final GameController? controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? OfflineGameController();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
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

        return Scaffold(
          backgroundColor: const Color(0xFF1B3B2B), // Verde paño
          appBar: AppBar(
            title: const Text(
              'Truco Uruguayo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF0F241A),
            elevation: 2,
            actions: [
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
                      onPlay: (card) => _perform(PlayCardAction(card)),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
