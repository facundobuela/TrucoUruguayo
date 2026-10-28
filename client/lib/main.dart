import 'dart:async';
import 'package:flutter/material.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  runApp(const TrucoApp());
}

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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TrucoMatch _match;
  final HeuristicBot _bot = HeuristicBot();
  bool _isBotThinking = false;
  String _statusMessage = '¡Bienvenido al Truco Uruguayo!';

  @override
  void initState() {
    super.initState();
    _startNewMatch();
  }

  void _startNewMatch() {
    setState(() {
      _match = TrucoMatch();
      _match.startHand();
      _statusMessage = 'Mano 1 iniciada. ¡Buena suerte!';
    });
    _checkBotTurn();
  }

  void _startNextHand() {
    if (_match.isOver) return;
    setState(() {
      _match.startHand();
      _statusMessage = 'Mano ${_match.handNumber} iniciada.';
    });
    _checkBotTurn();
  }

  void _checkBotTurn() {
    final hand = _match.hand;
    if (hand == null || hand.isFinished || _match.isOver) return;

    if (hand.toAct == Seat.b && !_isBotThinking) {
      setState(() => _isBotThinking = true);
      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        final currentHand = _match.hand;
        if (currentHand != null && currentHand.toAct == Seat.b && !currentHand.isFinished) {
          final view = HandView.of(currentHand, Seat.b);
          final action = _bot.choose(view);
          final events = currentHand.apply(Seat.b, action);
          _handleEvents(events, isBot: true);
        }
        setState(() => _isBotThinking = false);
        _checkBotTurn();
      });
    }
  }

  void _handleEvents(List<GameEvent> events, {required bool isBot}) {
    for (final e in events) {
      if (e is BetCalledEvent) {
        _statusMessage = '${e.seat == Seat.a ? "Vos cantaste" : "El Bot cantó"}: ${e.bet.wire}';
      } else if (e is BetRespondedEvent) {
        _statusMessage = '${e.seat == Seat.a ? "Vos respondiste" : "El Bot respondió"}: ${e.response.wire}';
      } else if (e is PointsAwardedEvent) {
        _statusMessage = '+${e.points} pts para ${e.seat == Seat.a ? "Vos" : "el Bot"} (${e.reason.wire})';
      } else if (e is HandFinishedEvent) {
        final winnerStr = e.winner == null
            ? 'Parda'
            : (e.winner == Seat.a ? '¡Ganaste la mano!' : 'El Bot ganó la mano.');
        _statusMessage = 'Fin de la mano. $winnerStr';
      }
    }
    setState(() {});
  }

  void _executeAction(GameAction action) {
    final hand = _match.hand;
    if (hand == null || hand.toAct != Seat.a || hand.isFinished) return;

    try {
      final events = hand.apply(Seat.a, action);
      _handleEvents(events, isBot: false);
      _checkBotTurn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acción no permitida: $e'), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hand = _match.hand;
    final isPlayerTurn = hand != null && !hand.isFinished && hand.toAct == Seat.a && !_isBotThinking;
    final legalActions = hand != null && !hand.isFinished ? hand.legalActions(Seat.a) : <GameAction>[];

    return Scaffold(
      backgroundColor: const Color(0xFF1B3B2B), // Verde paño
      appBar: AppBar(
        title: const Text('Truco Uruguayo (1v1 vs Bot)'),
        backgroundColor: const Color(0xFF0F241A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar partida',
            onPressed: _startNewMatch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Marcador tradicional a 30
            _buildScoreBoard(),

            // Barra de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.black26,
              child: Text(
                _isBotThinking ? 'El Bot está pensando...' : _statusMessage,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                textAlign: TextAlign.center,
              ),
            ),

            // Tapete Central
            Expanded(
              child: Stack(
                children: [
                  // Muestra en la mesa
                  if (hand != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _buildSampleCard(hand.sample),
                    ),

                  // Cartas cubiertas del Bot
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildBotCards(hand?.cardsOf(Seat.b).length ?? 0),
                  ),

                  // Cartas jugadas en las rondas
                  Center(
                    child: _buildTablePlayedCards(hand),
                  ),

                  // Diálogo / Tarjeta de fin de mano o de partida
                  if (hand != null && hand.isFinished)
                    Center(
                      child: Card(
                        color: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _match.isOver
                                    ? (_match.winner == Seat.a ? '🎉 ¡GANASTE EL PARTIDO! 🎉' : 'PERDISTE EL PARTIDO')
                                    : 'Mano finalizada',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                                onPressed: _match.isOver ? _startNewMatch : _startNextHand,
                                child: Text(_match.isOver ? 'Nueva Partida' : 'Siguiente Mano'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Acciones y cantos inteligentes
            if (isPlayerTurn) _buildActionBar(legalActions),

            // Cartas del Jugador
            _buildPlayerHand(hand, legalActions),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(bottom: BorderSide(color: Colors.black45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreBadge('Vos (Mano)', _match.scoreA, Seat.a),
          Column(
            children: [
              Text(
                'Mano #${_match.handNumber}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Text('A 30 PUNTOS', style: TextStyle(fontSize: 10, letterSpacing: 1.2)),
            ],
          ),
          _buildScoreBadge('Bot (IA)', _match.scoreB, Seat.b),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String title, int score, Seat seat) {
    final isMano = _match.hand?.mano == seat;
    final isBuenas = score >= 15;
    final etapa = isBuenas ? 'Buenas (${score - 15})' : 'Malas ($score)';

    return Column(
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            if (isMano) const Text(' 👑', style: TextStyle(fontSize: 12)),
          ],
        ),
        Text('$score pts', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        Text(etapa, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSampleCard(Sample sample) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MUESTRA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white70)),
        const SizedBox(height: 4),
        _buildCardVisual(sample.card, width: 60, height: 90, isSample: true),
        if (sample.sampleIsPiece)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '12 sustituye al ${sample.card.number}',
              style: const TextStyle(fontSize: 9, color: Colors.amberAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildBotCards(int count) {
    return Row(
      children: List.generate(
        count,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 44,
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white30, width: 1),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/cards/reverso.png',
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF8B2500)),
          ),
        ),
      ),
    );
  }

  Widget _buildTablePlayedCards(TrucoHand? hand) {
    if (hand == null || hand.rounds.isEmpty) {
      return const Text(
        'Mesa limpia',
        style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic),
      );
    }

    final rounds = hand.rounds;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rounds.map((r) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ronda ${r.number}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (r.cardOf(Seat.b) != null) ...[
                    Column(
                      children: [
                        const Text('Bot', style: TextStyle(fontSize: 9, color: Colors.white54)),
                        _buildCardVisual(r.cardOf(Seat.b)!, width: 48, height: 72),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (r.cardOf(Seat.a) != null)
                    Column(
                      children: [
                        const Text('Vos', style: TextStyle(fontSize: 9, color: Colors.white54)),
                        _buildCardVisual(r.cardOf(Seat.a)!, width: 48, height: 72),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerHand(TrucoHand? hand, List<GameAction> legalActions) {
    final cards = hand?.cardsOf(Seat.a) ?? [];
    final sample = hand?.sample;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(top: BorderSide(color: Colors.black45)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cards.map((c) {
              final canPlay = legalActions.contains(PlayCardAction(c));
              final role = sample?.classify(c);

              return GestureDetector(
                onTap: canPlay ? () => _executeAction(PlayCardAction(c)) : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _buildCardVisual(c, width: 75, height: 115, isPlayable: canPlay),
                      if (role != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatRole(role),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: role.isPiece ? Colors.amberAccent : Colors.white70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatRole(CardRole role) {
    switch (role) {
      case CardRole.piezaDos:
        return '⭐ 2 (Pieza)';
      case CardRole.piezaCuatro:
        return '⭐ 4 (Pieza)';
      case CardRole.piezaCinco:
        return '⭐ 5 (Pieza)';
      case CardRole.piezaPerico:
        return '⭐ Perico (11)';
      case CardRole.piezaPerica:
        return '⭐ Perica (10)';
      case CardRole.macho:
        return '1 Espada (Macho)';
      case CardRole.hembra:
        return '1 Basto (Hembra)';
      case CardRole.sieteEspada:
        return '7 Espada';
      case CardRole.sieteOro:
        return '7 Oro';
      default:
        return '';
    }
  }

  Widget _buildActionBar(List<GameAction> legalActions) {
    final calls = legalActions.whereType<CallAction>().map((a) => a.bet).toList();
    final responds = legalActions.whereType<RespondAction>().map((a) => a.response).toList();
    final canFold = legalActions.contains(const FoldAction());

    if (calls.isEmpty && responds.isEmpty && !canFold) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xDD0F241A),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Respuestas prominentes (Quiero / No Quiero)
          if (responds.isNotEmpty) ...[
            Row(
              children: [
                for (final r in responds)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: r == BetResponse.quiero
                              ? const Color(0xFF2E7D32)
                              : (r == BetResponse.noQuiero ? const Color(0xFFC62828) : Colors.deepPurple),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _executeAction(RespondAction(r)),
                        child: Text(
                          r == BetResponse.quiero
                              ? 'QUIERO'
                              : (r == BetResponse.noQuiero ? 'NO QUIERO' : 'CON FLOR ME ACHICO'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (calls.isNotEmpty) const SizedBox(height: 6),
          ],

          // Cantos e Irse al mazo organizados en Wrap responsivo para pantalla mvil
          if (calls.isNotEmpty || canFold)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Cantos de Flor
                for (final c in calls.where((b) => b.isFlor))
                  _buildActionButton(
                    label: c.wire,
                    color: Colors.purple[800]!,
                    onPressed: () => _executeAction(CallAction(c)),
                  ),

                // Cantos de Envido (Envido, Real Envido, Falta Envido)
                for (final c in calls.where((b) => b.isEnvido))
                  _buildActionButton(
                    label: _formatBetName(c),
                    color: const Color(0xFF1565C0),
                    onPressed: () => _executeAction(CallAction(c)),
                  ),

                // Cantos de Truco (Truco, Retruco, Vale Cuatro)
                for (final c in calls.where((b) => b.isTruco))
                  _buildActionButton(
                    label: '⚡ ${_formatBetName(c)}',
                    color: const Color(0xFFE65100),
                    isBold: true,
                    onPressed: () => _executeAction(CallAction(c)),
                  ),

                // Irse al Mazo
                if (canFold)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined, size: 14, color: Colors.redAccent),
                    label: const Text(
                      'Al Mazo',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _executeAction(const FoldAction()),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isBold = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: isBold ? 3 : 1,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatBetName(BetCall bet) {
    switch (bet) {
      case BetCall.envido:
        return 'Envido';
      case BetCall.realEnvido:
        return 'Real Envido';
      case BetCall.faltaEnvido:
        return 'Falta Envido';
      case BetCall.flor:
        return 'Flor';
      case BetCall.contraflor:
        return 'Contraflor';
      case BetCall.truco:
        return 'TRUCO';
      case BetCall.retruco:
        return 'RETRUCO';
      case BetCall.valeCuatro:
        return 'VALE CUATRO';
    }
  }

  Widget _buildCardVisual(
    TrucoCard card, {
    double width = 50,
    double height = 75,
    bool isSample = false,
    bool isPlayable = false,
  }) {
    final assetPath = 'assets/cards/${card.number}_${card.suit.name}.png';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isPlayable
              ? Colors.amberAccent
              : (isSample ? Colors.amber : Colors.black26),
          width: isPlayable ? 2.8 : (isSample ? 2.0 : 1.0),
        ),
        boxShadow: [
          if (isPlayable)
            const BoxShadow(color: Colors.amberAccent, blurRadius: 8, spreadRadius: 1)
          else
            const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            '${card.number}\n${card.suit.displayName[0]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
