import 'dart:async';
import 'dart:math';
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
          final events = _match.apply(Seat.b, action);
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
        final actor = e.seat == Seat.a ? 'Vos cantaste' : 'El Bot cantó';
        _statusMessage = '$actor: ${_formatBetName(e.bet)}';
      } else if (e is BetRespondedEvent) {
        final actor = e.seat == Seat.a ? 'Vos respondiste' : 'El Bot respondió';
        _statusMessage = '$actor: ${_formatBetResponse(e.response)}';
      } else if (e is PointsAwardedEvent) {
        final receiver = e.seat == Seat.a ? 'Vos' : 'el Bot';
        _statusMessage = '+${e.points} pts para $receiver (${_formatPointsReason(e.reason)})';
      } else if (e is HandFinishedEvent) {
        final winnerStr = e.winner == null
            ? (_match.isOver ? (_match.winner == Seat.a ? '¡Llegaste a 30!' : 'El Bot llegó a 30') : 'Parda')
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
      final events = _match.apply(Seat.a, action);
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
        title: const Text('Truco Uruguayo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F241A),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar partida',
            onPressed: _startNewMatch,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;
            final isCompactH = screenH < 700;

            // Medidas responsivas para cartas del jugador
            final effectiveW = min(screenW, 480.0);
            final playerCardW = isCompactH
                ? (effectiveW * 0.22).clamp(72.0, 92.0)
                : (effectiveW * 0.25).clamp(86.0, 112.0);
            final playerCardH = playerCardW * 1.48;

            return Column(
              children: [
                // 1. Marcador superior
                _buildScoreBoard(isCompactH),

                // 2. Barra de estado legible
                _buildStatusBar(),

                // 3. Tapete central de juego (Muestra, Bot y Rondas enfrentadas)
                Expanded(
                  child: _buildPlayMat(hand, effectiveW, screenH),
                ),

                // 4. Botonera de acciones (Quiero, Envido, Truco, Mazo)
                if (isPlayerTurn) _buildActionBar(legalActions),

                // 5. Cartas de mi mano (abajo)
                _buildPlayerHand(hand, legalActions, playerCardW, playerCardH),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreBoard(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 16, vertical: isCompact ? 4 : 8),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(bottom: BorderSide(color: Colors.black45)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildScoreBadge('Vos', _match.scoreA, Seat.a, isCompact)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mano #${_match.handNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text('A 30 PUNTOS', style: TextStyle(fontSize: 11, letterSpacing: 1.1, color: Colors.white70)),
              ],
            ),
          ),
          Expanded(child: _buildScoreBadge('Bot (IA)', _match.scoreB, Seat.b, isCompact)),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String title, int score, Seat seat, bool isCompact) {
    final isMano = _match.hand?.mano == seat;
    final isBuenas = score >= 15;
    final etapa = isBuenas ? 'Buenas (${score - 15})' : 'Malas ($score)';

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            // Indicador de mano sin emoji: asterisco tipográfico
            if (isMano) const Text(' *', style: TextStyle(fontSize: 13, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(
          '$score',
          style: TextStyle(
            fontSize: isCompact ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
          ),
        ),
        Text(etapa, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: Colors.black26,
      child: Text(
        _isBotThinking ? 'El Bot está pensando...' : _statusMessage,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPlayMat(TrucoHand? hand, double effectiveW, double totalH) {
    return LayoutBuilder(
      builder: (context, matConstraints) {
        final matH = matConstraints.maxHeight;
        final matW = matConstraints.maxWidth;

        // Muestra (centro-arriba, pequeña)
        final sampleW = (effectiveW * 0.17).clamp(58.0, 80.0);
        final sampleH = sampleW * 1.48;

        // Cartas del bot (izquierda, apiladas en abanico)
        final botCardW = (effectiveW * 0.14).clamp(48.0, 62.0);
        final botCardH = botCardW * 1.48;

        // Espacio disponible para las dos cartas de mesa + gap + label
        // Area usable: matH - sampleH(+20 top) - 10(bottom) - 30(label+gap)
        final usableForCards = (matH - sampleH - 60).clamp(80.0, 400.0);
        // Dos cartas apiladas (bot + jugador) con 8px gap
        final tableCardH = ((usableForCards - 8) / 2).clamp(52.0, 140.0);
        final tableCardW = (tableCardH / 1.48).clamp(36.0, 95.0);

        return Stack(
          children: [
            // Centro-Arriba: MUESTRA (sin etiqueta grande)
            if (hand != null)
              Positioned(
                top: 10,
                left: (matW - sampleW) / 2,
                child: _buildSampleCard(hand.sample, sampleW, sampleH),
              ),

            // Izquierda: Cartas tapadas del Bot en abanico
            Positioned(
              top: matH * 0.20,
              left: 12,
              child: _buildBotCards(hand?.cardsOf(Seat.b).length ?? 0, botCardW, botCardH),
            ),

            // Centro del tapete: Rondas jugadas (cartas lado a lado)
            Positioned(
              top: sampleH + 16,
              left: 0,
              right: 0,
              bottom: 0,
              child: OverflowBox(
                alignment: Alignment.center,
                maxHeight: double.infinity,
                child: Center(
                  child: _buildTablePlayedCards(hand, tableCardW, tableCardH),
                ),
              ),
            ),

            // Cartel de fin de mano o de partida
            if (hand != null && hand.isFinished)
              Center(
                child: Card(
                  color: const Color(0xEE0A1811),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.amber, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _match.isOver
                              ? (_match.winner == Seat.a ? '¡GANASTE EL PARTIDO!' : 'PERDISTE EL PARTIDO')
                              : 'Mano Finalizada',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(140, 44),
                          ),
                          onPressed: _match.isOver ? _startNewMatch : _startNextHand,
                          child: Text(
                            _match.isOver ? 'Nueva Partida' : 'Siguiente Mano',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSampleCard(Sample sample, double width, double height) {
    // Muestra compacta: solo la carta, con borde dorado.
    // Si es pieza (el 12 sustituye a otra carta), se muestra un chip pequeño debajo.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCardVisual(sample.card, width: width, height: height, isSample: true),
        if (sample.sampleIsPiece)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '12 = ${sample.card.number}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
          ),
      ],
    );
  }

  Widget _buildBotCards(int count, double width, double height) {
    if (count == 0) return const SizedBox.shrink();

    // Cartas del bot en abanico: la primera rotada a la izquierda,
    // la del medio recta, la tercera a la derecha (como en la imagen de ref.)
    // Ángulos en radianes para count = 1,2,3
    final List<double> angles = switch (count) {
      1 => [0.0],
      2 => [-0.14, 0.14],
      _ => [-0.22, 0.0, 0.22],
    };

    // Spread horizontal: cada carta se separa un poco
    final double spread = width * 0.55;
    final totalW = width + (count - 1) * spread;
    final totalH = height + 20; // extra para la rotación

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(count, (index) {
          final angle = angles[index];
          final left = index * spread;
          return Positioned(
            bottom: 0,
            left: left,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white30, width: 1),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(1, 2))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/cards/reverso.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: const Color(0xFF8B2500)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTablePlayedCards(TrucoHand? hand, double cardW, double cardH) {
    if (hand == null || hand.rounds.isEmpty) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 40, color: Colors.white24),
          SizedBox(height: 8),
          Text(
            'Tirá una carta para comenzar',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    final rounds = hand.rounds;
    // Cada ronda: columna con carta del bot (arriba) y carta del jugador (abajo),
    // separadas por un pequeño gap. Las rondas están una al lado de la otra.
    const double roundGap = 20; // gap entre rondas
    const double cardGap = 8;   // gap entre carta bot y carta jugador dentro de la ronda

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int i = 0; i < rounds.length; i++) ...[
            if (i > 0) const SizedBox(width: roundGap),
            _buildRoundColumn(rounds[i], cardW, cardH, cardGap),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundColumn(dynamic r, double cardW, double cardH, double cardGap) {
    final isParda = r.result == RoundWinner.parda;
    final botWon = r.result == RoundWinner.bandoB;
    final playerWon = r.result == RoundWinner.bandoA;

    // Etiqueta de resultado debajo de las cartas (sutil)
    String? resultLabel;
    Color resultColor = Colors.white54;
    if (r.result == RoundWinner.bandoA) {
      resultLabel = 'Ganaste';
      resultColor = Colors.lightGreenAccent;
    } else if (r.result == RoundWinner.bandoB) {
      resultLabel = 'Bot';
      resultColor = Colors.orangeAccent;
    } else if (r.result == RoundWinner.parda) {
      resultLabel = 'Parda';
      resultColor = Colors.amberAccent;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Carta del Bot (arriba, descubierta)
        if (r.cardOf(Seat.b) != null)
          _buildTableCardWithWinner(
            card: r.cardOf(Seat.b)!,
            width: cardW,
            height: cardH,
            isWinner: botWon,
            isParda: isParda,
          )
        else
          SizedBox(width: cardW, height: cardH),

        SizedBox(height: cardGap),

        // Carta del Jugador (abajo)
        if (r.cardOf(Seat.a) != null)
          _buildTableCardWithWinner(
            card: r.cardOf(Seat.a)!,
            width: cardW,
            height: cardH,
            isWinner: playerWon,
            isParda: isParda,
          )
        else
          SizedBox(width: cardW, height: cardH),

        // Resultado de la ronda (texto pequeño)
        if (resultLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            resultLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTableCardWithWinner({
    required TrucoCard card,
    required double width,
    required double height,
    required bool isWinner,
    required bool isParda,
  }) {
    Color borderColor = Colors.black38;
    double borderWidth = 1.0;
    List<BoxShadow> shadows = [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))];

    if (isWinner) {
      borderColor = Colors.amberAccent;
      borderWidth = 2.8;
      shadows = [
        const BoxShadow(color: Colors.amberAccent, blurRadius: 8, spreadRadius: 1),
      ];
    } else if (isParda) {
      borderColor = Colors.white70;
      borderWidth = 2.0;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/cards/${card.number}_${card.suit.name}.png',
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            '${card.number}\n${card.suit.displayName[0]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerHand(
    TrucoHand? hand,
    List<GameAction> legalActions,
    double cardW,
    double cardH,
  ) {
    final cards = hand?.cardsOf(Seat.a) ?? [];
    final sample = hand?.sample;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF142E21),
        border: Border(top: BorderSide(color: Colors.black45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: cards.map((c) {
          final canPlay = legalActions.contains(PlayCardAction(c));
          final role = sample?.classify(c);

          return GestureDetector(
            onTap: canPlay ? () => _executeAction(PlayCardAction(c)) : null,
            child: Container(
              width: cardW,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCardVisual(c, width: cardW, height: cardH, isPlayable: canPlay),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: cardW,
                    height: 18,
                    child: Text(
                      role != null ? _formatRole(role) : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: role != null && role.isPiece ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatRole(CardRole role) {
    switch (role) {
      case CardRole.piezaDos:
        return '2 (Pieza)';
      case CardRole.piezaCuatro:
        return '4 (Pieza)';
      case CardRole.piezaCinco:
        return '5 (Pieza)';
      case CardRole.piezaPerico:
        return 'Perico (11)';
      case CardRole.piezaPerica:
        return 'Perica (10)';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xEE0D2117),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Respuestas prominentes (Quiero / No Quiero / Con Flor me achico)
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
                          minimumSize: const Size(0, 46), // Zona táctil mínima >= 44 px
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _executeAction(RespondAction(r)),
                        child: Text(
                          _formatBetResponse(r).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (calls.isNotEmpty) const SizedBox(height: 6),
          ],

          // 2. Cantos e Irse al mazo organizados con Wrap responsivo
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
                    label: _formatBetName(c),
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
                    label: _formatBetName(c),
                    color: const Color(0xFFE65100),
                    isBold: true,
                    onPressed: () => _executeAction(CallAction(c)),
                  ),

                // Irse al Mazo
                if (canFold)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.flag_outlined, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Al Mazo',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 44), // Zona táctil mínima >= 44 px
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 44), // Zona táctil mínima >= 44 px
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

  Widget _buildCardVisual(
    TrucoCard card, {
    required double width,
    required double height,
    bool isSample = false,
    bool isPlayable = false,
  }) {
    final assetPath = 'assets/cards/${card.number}_${card.suit.name}.png';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPlayable
              ? Colors.amberAccent
              : (isSample ? Colors.amber : Colors.black26),
          width: isPlayable ? 3.0 : (isSample ? 2.2 : 1.0),
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
            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- Funciones para nombres legibles en español (Traducción formal) ---

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
        return 'Truco';
      case BetCall.retruco:
        return 'Retruco';
      case BetCall.valeCuatro:
        return 'Vale Cuatro';
    }
  }

  String _formatBetResponse(BetResponse response) {
    switch (response) {
      case BetResponse.quiero:
        return 'Quiero';
      case BetResponse.noQuiero:
        return 'No quiero';
      case BetResponse.conFlorMeAchico:
        return 'Con Flor me achico';
    }
  }

  String _formatPointsReason(PointsReason reason) {
    switch (reason) {
      case PointsReason.envidoQuerido:
        return 'Envido querido';
      case PointsReason.envidoNoQuerido:
        return 'Envido no querido';
      case PointsReason.flor:
        return 'Flor';
      case PointsReason.florAmbas:
        return 'Ambos con Flor';
      case PointsReason.contraflorQuerida:
        return 'Contraflor querida';
      case PointsReason.conFlorMeAchico:
        return 'Con Flor me achico';
      case PointsReason.trucoNoQuerido:
        return 'Truco no querido';
      case PointsReason.manoGanada:
        return 'Mano ganada';
      case PointsReason.irseAlMazo:
        return 'Irse al mazo';
    }
  }
}
