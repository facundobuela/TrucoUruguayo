import 'dart:convert';

import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

TrucoCard c(int n, Suit s) => TrucoCard(n, s);

// Muestra 3 de Copa: piezas = 2, 4, 5, 10, 11 de Copa. Ninguna carta de los
// escenarios de abajo es pieza salvo que se indique.
final sample = Sample(c(3, Suit.copa));

// Mano "fuerte" sin flor: 1E, 1B y 7E (envido 28 por 1E+7E).
final strongA = [c(1, Suit.espada), c(1, Suit.basto), c(7, Suit.espada)];
// Mano "débil" sin flor ni pares: envido = 6.
final weakB = [c(4, Suit.oro), c(5, Suit.basto), c(6, Suit.copa)];

TrucoHand start({
  Seat mano = Seat.a,
  List<TrucoCard>? a,
  List<TrucoCard>? b,
  Sample? s,
  int scoreA = 0,
  int scoreB = 0,
  RulesConfig cfg = const RulesConfig(),
}) =>
    TrucoHand.start(
      mano: mano,
      cardsA: a ?? strongA,
      cardsB: b ?? weakB,
      sample: s ?? sample,
      scoreA: scoreA,
      scoreB: scoreB,
      config: cfg,
    );

void play(TrucoHand h, Seat s, TrucoCard card) => h.apply(s, PlayCardAction(card));
void call(TrucoHand h, Seat s, BetCall b) => h.apply(s, CallAction(b));
void respond(TrucoHand h, Seat s, BetResponse r) => h.apply(s, RespondAction(r));

bool canCall(TrucoHand h, Seat s, BetCall b) =>
    h.legalActions(s).contains(CallAction(b));

void main() {
  group('Rondas, turnos y pardas (RF-06)', () {
    test('el mano abre y se alterna; gana quien gana 2 rondas', () {
      final h = start();
      expect(h.toAct, Seat.a);
      play(h, Seat.a, c(1, Suit.espada)); // macho
      expect(h.toAct, Seat.b);
      play(h, Seat.b, c(4, Suit.oro));
      expect(h.roundResults, [RoundWinner.bandoA]);
      expect(h.toAct, Seat.a); // abre quien ganó la ronda
      play(h, Seat.a, c(1, Suit.basto));
      play(h, Seat.b, c(5, Suit.basto));
      expect(h.isFinished, true);
      expect(h.handWinner, Seat.a);
      expect(h.awardedA, 1); // sin truco la mano vale 1
      expect(h.awardedB, 0);
    });

    test('el ganador de una ronda abre la siguiente aunque no sea mano', () {
      // B gana la 1ª con su 7 de Oro; B debe abrir la 2ª.
      final h = start(
        a: [c(4, Suit.espada), c(6, Suit.basto), c(5, Suit.oro)],
        b: [c(7, Suit.oro), c(6, Suit.copa), c(5, Suit.basto)],
      );
      play(h, Seat.a, c(4, Suit.espada));
      play(h, Seat.b, c(7, Suit.oro));
      expect(h.toAct, Seat.b);
      expect(h.currentRound, 2);
    });

    test('P2/P3/P4: tres pardas consecutivas -> gana el MANO (mano=A)', () {
      final h = start(
        cfg: const RulesConfig(withFlor: false),
        a: [c(3, Suit.espada), c(6, Suit.basto), c(4, Suit.oro)],
        b: [c(3, Suit.oro), c(6, Suit.copa), c(4, Suit.basto)],
      );
      play(h, Seat.a, c(3, Suit.espada));
      play(h, Seat.b, c(3, Suit.oro));
      expect(h.roundResults, [RoundWinner.parda]);
      expect(h.toAct, Seat.a, reason: 'tras parda abre quien tiró primero');
      play(h, Seat.a, c(6, Suit.basto));
      play(h, Seat.b, c(6, Suit.copa));
      expect(h.isFinished, false);
      expect(h.toAct, Seat.a);
      play(h, Seat.a, c(4, Suit.oro));
      play(h, Seat.b, c(4, Suit.basto));
      expect(h.isFinished, true);
      expect(h.handWinner, Seat.a);
    });

    test('tres pardas con mano=B -> gana B y B abre cada ronda', () {
      final h = start(
        mano: Seat.b,
        cfg: const RulesConfig(withFlor: false),
        a: [c(3, Suit.espada), c(6, Suit.basto), c(4, Suit.oro)],
        b: [c(3, Suit.oro), c(6, Suit.copa), c(4, Suit.basto)],
      );
      expect(h.toAct, Seat.b);
      play(h, Seat.b, c(3, Suit.oro));
      play(h, Seat.a, c(3, Suit.espada));
      expect(h.toAct, Seat.b);
      play(h, Seat.b, c(6, Suit.copa));
      play(h, Seat.a, c(6, Suit.basto));
      expect(h.toAct, Seat.b);
      play(h, Seat.b, c(4, Suit.basto));
      play(h, Seat.a, c(4, Suit.oro));
      expect(h.handWinner, Seat.b);
    });

    test('P2: parda en 1ª y gana la 2ª -> define la 2ª', () {
      final h = start(
        cfg: const RulesConfig(withFlor: false),
        a: [c(3, Suit.espada), c(6, Suit.basto), c(4, Suit.oro)],
        b: [c(3, Suit.oro), c(7, Suit.oro), c(4, Suit.basto)],
      );
      play(h, Seat.a, c(3, Suit.espada));
      play(h, Seat.b, c(3, Suit.oro));
      play(h, Seat.a, c(6, Suit.basto));
      play(h, Seat.b, c(7, Suit.oro)); // mata 7 de oro gana
      expect(h.handWinner, Seat.b);
    });

    test('P5: gana la 1ª y la 2ª es parda -> gana quien ganó la 1ª', () {
      final h = start(
        cfg: const RulesConfig(withFlor: false),
        a: [c(7, Suit.espada), c(6, Suit.basto), c(4, Suit.oro)],
        b: [c(3, Suit.oro), c(6, Suit.copa), c(4, Suit.basto)],
      );
      play(h, Seat.a, c(7, Suit.espada));
      play(h, Seat.b, c(3, Suit.oro));
      play(h, Seat.a, c(6, Suit.basto));
      play(h, Seat.b, c(6, Suit.copa));
      expect(h.handWinner, Seat.a);
      expect(h.roundResults.length, 2);
    });

    test('P6: B gana 1ª, A gana 2ª, 3ª parda -> gana B (ganó la 1ª)', () {
      // Muestra 1 de Oro (palo Oro): 4E, 3B, 5C, 7O, 2C y 5B no son piezas.
      final h = start(
        s: Sample(c(1, Suit.oro)),
        cfg: const RulesConfig(withFlor: false),
        a: [c(4, Suit.espada), c(3, Suit.basto), c(5, Suit.copa)],
        b: [c(7, Suit.oro), c(2, Suit.copa), c(5, Suit.basto)],
      );
      play(h, Seat.a, c(4, Suit.espada));
      play(h, Seat.b, c(7, Suit.oro)); // gana B (7 de oro es mata)
      expect(h.toAct, Seat.b);
      play(h, Seat.b, c(2, Suit.copa)); // dosComun
      play(h, Seat.a, c(3, Suit.basto)); // tresComun: gana A
      expect(h.roundResults, [RoundWinner.bandoB, RoundWinner.bandoA]);
      expect(h.toAct, Seat.a);
      play(h, Seat.a, c(5, Suit.copa));
      play(h, Seat.b, c(5, Suit.basto)); // cincoComun vs cincoComun: parda
      expect(h.roundResults.last, RoundWinner.parda);
      expect(h.handWinner, Seat.b);
    });

    test('no se puede tirar una carta que no se tiene ni jugar fuera de turno', () {
      final h = start();
      expect(() => play(h, Seat.b, c(4, Suit.oro)),
          throwsA(isA<IllegalActionException>()));
      expect(() => play(h, Seat.a, c(2, Suit.copa)),
          throwsA(isA<IllegalActionException>()));
      expect(h.log.length, 1, reason: 'sólo HAND_STARTED');
    });

    test('la mano terminada rechaza cualquier acción', () {
      final h = start();
      h.apply(Seat.a, const FoldAction());
      expect(h.isFinished, true);
      expect(h.legalActions(Seat.a), isEmpty);
      expect(() => play(h, Seat.a, c(1, Suit.espada)),
          throwsA(isA<IllegalActionException>()));
    });
  });

  group('Cadena de Truco (T1-T5) y derecho a subir', () {
    TrucoHand finishWithAWinning(TrucoHand h) {
      play(h, Seat.a, c(1, Suit.espada));
      play(h, Seat.b, c(4, Suit.oro));
      play(h, Seat.a, c(1, Suit.basto));
      play(h, Seat.b, c(5, Suit.basto));
      return h;
    }

    test('T1: Truco + Quiero, gana A -> 2 puntos', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      expect(h.toAct, Seat.b);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.trucoLevel, 2);
      expect(h.toAct, Seat.a, reason: 'el que cantó sigue su turno');
      finishWithAWinning(h);
      expect(h.awardedA, 2);
    });

    test('T2: Truco + No Quiero -> 1 punto para el retador y termina', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      respond(h, Seat.b, BetResponse.noQuiero);
      expect(h.isFinished, true);
      expect(h.awardedA, 1);
      expect(h.awardedB, 0);
      expect(h.handWinner, Seat.a);
    });

    test('T3: Truco -> Retruco -> No Quiero -> 2 puntos para el retador (B)', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      call(h, Seat.b, BetCall.retruco);
      expect(h.toAct, Seat.a);
      respond(h, Seat.a, BetResponse.noQuiero);
      expect(h.awardedB, 2);
      expect(h.awardedA, 0);
    });

    test('T4: Truco -> Retruco -> Vale 4 -> No Quiero -> 3 para el retador (A)', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      call(h, Seat.b, BetCall.retruco);
      call(h, Seat.a, BetCall.valeCuatro);
      respond(h, Seat.b, BetResponse.noQuiero);
      expect(h.awardedA, 3);
    });

    test('T5: Truco -> Retruco -> Vale 4 -> Quiero, gana A -> 4 puntos', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      call(h, Seat.b, BetCall.retruco);
      call(h, Seat.a, BetCall.valeCuatro);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.trucoLevel, 4);
      expect(h.legalActions(Seat.a).whereType<CallAction>().where((x) => x.bet.isTruco), isEmpty);
      finishWithAWinning(h);
      expect(h.awardedA, 4);
    });

    test('Retruco aceptado: gana B -> 3 puntos para B', () {
      final h = start(a: weakB, b: strongA); // B tiene las cartas fuertes
      call(h, Seat.a, BetCall.truco);
      call(h, Seat.b, BetCall.retruco);
      respond(h, Seat.a, BetResponse.quiero);
      play(h, Seat.a, c(4, Suit.oro));
      play(h, Seat.b, c(1, Suit.espada));
      play(h, Seat.b, c(1, Suit.basto));
      play(h, Seat.a, c(5, Suit.basto));
      expect(h.handWinner, Seat.b);
      expect(h.awardedB, 3);
    });

    test('quien quiere tiene el derecho de subir; el que cantó no puede resubir', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      respond(h, Seat.b, BetResponse.quiero);
      // A (que cantó) no puede cantar retruco; B sí cuando le toque.
      expect(canCall(h, Seat.a, BetCall.retruco), false);
      play(h, Seat.a, c(1, Suit.espada));
      expect(h.toAct, Seat.b);
      expect(canCall(h, Seat.b, BetCall.retruco), true);
      expect(canCall(h, Seat.b, BetCall.truco), false);
      call(h, Seat.b, BetCall.retruco);
      respond(h, Seat.a, BetResponse.quiero);
      // Ahora el derecho es de A: B no puede subir a vale cuatro.
      expect(canCall(h, Seat.b, BetCall.valeCuatro), false);
    });

    test('durante un truco pendiente no se puede jugar carta ni irse al mazo', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      final legal = h.legalActions(Seat.b);
      expect(legal.whereType<PlayCardAction>(), isEmpty);
      expect(legal.contains(const FoldAction()), false);
      expect(h.legalActions(Seat.a), isEmpty);
    });
  });

  group('Irse al mazo (RF-10)', () {
    test('sin cantos: el rival se lleva 1 punto', () {
      final h = start();
      h.apply(Seat.a, const FoldAction());
      expect(h.awardedB, 1);
      expect(h.handWinner, Seat.b);
    });

    test('con truco aceptado: el rival se lleva los puntos en juego (2)', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      respond(h, Seat.b, BetResponse.quiero);
      play(h, Seat.a, c(1, Suit.espada));
      h.apply(Seat.b, const FoldAction());
      expect(h.awardedA, 2);
    });
  });

  group('Envido (E6-E9 y cadenas)', () {
    test('E6: Envido + No Quiero -> 1 punto para quien cantó', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.noQuiero);
      expect(h.awardedA, 1);
      expect(h.envidoClosed, true);
      expect(h.isFinished, false);
      expect(h.toAct, Seat.a, reason: 'sigue jugando quien le tocaba');
    });

    test('E7: Envido -> Real -> No Quiero -> 2 puntos para B', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      call(h, Seat.b, BetCall.realEnvido);
      respond(h, Seat.a, BetResponse.noQuiero);
      expect(h.awardedB, 2);
      expect(h.awardedA, 0);
    });

    test('Envido querido: 2 puntos al que tiene más tanto (A 28 vs B 6)', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedA, 2);
      final ev = h.log.whereType<EnvidoResolvedEvent>().single;
      expect(ev.winner, Seat.a);
      expect(ev.manoPoints, 28);
      expect(ev.piePoints, isNull, reason: 'el pie dice "son buenas" y no muestra');
    });

    test('Envido-Envido querido: 4 puntos', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      call(h, Seat.b, BetCall.envido);
      expect(h.legalActions(Seat.a).whereType<CallAction>().map((x) => x.bet),
          isNot(contains(BetCall.envido)),
          reason: 'sólo se permite un envido-envido');
      respond(h, Seat.a, BetResponse.quiero);
      expect(h.awardedA, 4);
    });

    test('Envido + Real querido: 5; Envido-Envido-Real: 7', () {
      final h1 = start();
      call(h1, Seat.a, BetCall.envido);
      call(h1, Seat.b, BetCall.realEnvido);
      respond(h1, Seat.a, BetResponse.quiero);
      expect(h1.awardedA, 5);

      final h2 = start();
      call(h2, Seat.a, BetCall.envido);
      call(h2, Seat.b, BetCall.envido);
      call(h2, Seat.a, BetCall.realEnvido);
      respond(h2, Seat.b, BetResponse.quiero);
      expect(h2.awardedA, 7);
    });

    test('Real Envido directo: 3 puntos; no se puede subir con envido después', () {
      final h = start();
      call(h, Seat.a, BetCall.realEnvido);
      final next = h.legalActions(Seat.b).whereType<CallAction>().map((x) => x.bet).toSet();
      expect(next, {BetCall.faltaEnvido});
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedA, 3);
    });

    test('No Quiero a Envido-Envido paga lo acumulado antes del revire (2)', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      call(h, Seat.b, BetCall.envido);
      respond(h, Seat.a, BetResponse.noQuiero);
      expect(h.awardedB, 2);
    });

    test('empate de envido: gana el MANO (28 vs 28)', () {
      final tieB = [c(1, Suit.copa), c(7, Suit.copa), c(6, Suit.oro)];
      final h = start(b: tieB);
      expect(h.envidoPointsOf(Seat.a), 28);
      expect(h.envidoPointsOf(Seat.b), 28);
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedA, 2);
      final ev = h.log.whereType<EnvidoResolvedEvent>().single;
      expect(ev.winner, Seat.a);
      expect(ev.piePoints, 28, reason: 'el pie muestra cuando iguala');

      // Con mano=B gana B.
      final h2 = start(mano: Seat.b, b: tieB);
      call(h2, Seat.b, BetCall.envido);
      respond(h2, Seat.a, BetResponse.quiero);
      expect(h2.awardedB, 2);
    });

    test('gana el pie cuando su envido es mayor', () {
      final h = start(a: weakB, b: strongA);
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedB, 2);
      final ev = h.log.whereType<EnvidoResolvedEvent>().single;
      expect(ev.winner, Seat.b);
      expect(ev.piePoints, 28);
      expect(ev.manoPoints, 6);
    });

    test('E8: Falta Envido en las malas (10-12) -> 3 puntos (para 15)', () {
      final h = start(scoreA: 10, scoreB: 12);
      call(h, Seat.a, BetCall.faltaEnvido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedA, 3);
      expect(h.scoreA, 13);
    });

    test('E9: Falta Envido en las buenas (18-22) -> 8 puntos (para 30)', () {
      final h = start(scoreA: 18, scoreB: 22);
      call(h, Seat.a, BetCall.faltaEnvido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedA, 8);
      expect(h.scoreA, 26);
    });

    test('Falta Envido: si uno está en buenas y el otro en malas usa 30', () {
      expect(
          EnvidoChain.faltaEnvidoPoints(scoreA: 16, scoreB: 3, targetPoints: 30), 14);
      expect(
          EnvidoChain.faltaEnvidoPoints(scoreA: 14, scoreB: 14, targetPoints: 30), 1);
      expect(
          EnvidoChain.faltaEnvidoPoints(scoreA: 0, scoreB: 0, targetPoints: 30), 15);
      expect(
          EnvidoChain.faltaEnvidoPoints(scoreA: 15, scoreB: 0, targetPoints: 30),
          15,
          reason: 'con 15 ya terminó las malas');
    });

    test('Falta Envido rechazada: 1 punto; tras Envido: 2 (lo consolidado)', () {
      final h = start();
      call(h, Seat.a, BetCall.faltaEnvido);
      respond(h, Seat.b, BetResponse.noQuiero);
      expect(h.awardedA, 1);

      final h2 = start();
      call(h2, Seat.a, BetCall.envido);
      call(h2, Seat.b, BetCall.faltaEnvido);
      respond(h2, Seat.a, BetResponse.noQuiero);
      expect(h2.awardedB, 2);
    });

    test('el pie puede cantar envido tras la carta del mano; en la 2ª ronda ya nadie', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      // El pie todavía no jugó: puede cantar.
      expect(canCall(h, Seat.b, BetCall.envido), true);
      play(h, Seat.b, c(4, Suit.oro));
      // Ronda 2: ya no hay envido para nadie.
      expect(canCall(h, Seat.a, BetCall.envido), false);
    });

    test('el mano que ya tiró no puede cantar envido, pero puede responder al pie', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      call(h, Seat.b, BetCall.envido);
      expect(h.legalActions(Seat.a), contains(const RespondAction(BetResponse.quiero)));
      respond(h, Seat.a, BetResponse.quiero);
      // A: 28 contra B: 6 -> gana A (mano) 2 puntos.
      expect(h.awardedA, 2);
    });

    test('sólo en la 1ª ronda: en la 2ª no se canta envido', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      play(h, Seat.b, c(4, Suit.oro));
      for (final b in [BetCall.envido, BetCall.realEnvido, BetCall.faltaEnvido]) {
        expect(canCall(h, Seat.a, b), false);
      }
    });

    test('con truco aceptado ya no se puede cantar envido', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      respond(h, Seat.b, BetResponse.quiero);
      expect(canCall(h, Seat.a, BetCall.envido), false);
    });

    test('"El envido está primero": responder un truco con envido y luego volver', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      expect(canCall(h, Seat.b, BetCall.envido), true);
      call(h, Seat.b, BetCall.envido);
      expect(h.toAct, Seat.a);
      respond(h, Seat.a, BetResponse.quiero); // A gana 28 vs 6 -> 2 puntos
      expect(h.awardedA, 2);
      expect(h.pendingTruco, BetCall.truco, reason: 'el truco sigue pendiente');
      expect(h.toAct, Seat.b, reason: 'B debe responder ahora el truco');
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.trucoLevel, 2);
      expect(h.toAct, Seat.a);
    });

    test('"El envido está primero": también si ya jugó su carta (mano canta truco al pie)', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      call(h, Seat.b, BetCall.truco); // B (pie) canta truco antes de jugar
      // A ya jugó pero puede cantar el envido primero.
      expect(canCall(h, Seat.a, BetCall.envido), true);
    });

    test('el envido no está primero en la 2ª ronda', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      play(h, Seat.b, c(4, Suit.oro));
      call(h, Seat.a, BetCall.truco);
      expect(canCall(h, Seat.b, BetCall.envido), false);
    });

    test('envido con pieza liga con cualquier carta (sustituto incluido)', () {
      final s = Sample(c(2, Suit.basto)); // 12 de Basto sustituye al 2 (30)
      final h = start(
        s: s,
        a: [c(12, Suit.basto), c(7, Suit.oro), c(3, Suit.copa)],
        b: weakB,
      );
      expect(h.envidoPointsOf(Seat.a), 37);
    });
  });

  group('Flor (RF-07)', () {
    final florA = [c(5, Suit.oro), c(6, Suit.oro), c(7, Suit.oro)]; // 38
    final florB28 = [c(1, Suit.copa), c(7, Suit.copa), c(12, Suit.copa)]; // 28
    final florB38 = [c(5, Suit.basto), c(6, Suit.basto), c(7, Suit.basto)]; // 38

    test('quien tiene flor no puede cantar envido', () {
      final h = start(a: florA, b: weakB);
      expect(h.hasFlor(Seat.a), true);
      expect(canCall(h, Seat.a, BetCall.envido), false);
      expect(canCall(h, Seat.a, BetCall.flor), true);
    });

    test('Flor sin flor rival: 3 puntos inmediatos y no hay envido después', () {
      final h = start(a: florA, b: weakB);
      call(h, Seat.a, BetCall.flor);
      expect(h.awardedA, 3);
      expect(h.toAct, Seat.a);
      expect(canCall(h, Seat.b, BetCall.envido), false);
      expect(canCall(h, Seat.a, BetCall.flor), false, reason: 'no se canta dos veces');
    });

    test('F6: la Flor anula un Envido previo (y el envido queda sin puntos)', () {
      final h = start(a: weakB, b: florA); // B tiene flor; A canta envido
      call(h, Seat.a, BetCall.envido);
      expect(h.legalActions(Seat.b), [const CallAction(BetCall.flor)],
          reason: 'quien tiene flor sólo puede responder con flor');
      call(h, Seat.b, BetCall.flor);
      expect(h.log.whereType<EnvidoAnnulledEvent>().length, 1);
      expect(h.awardedB, 3);
      expect(h.awardedA, 0);
      expect(h.envidoPending, false);
      expect(h.toAct, Seat.a);
    });

    test('el mano que ya jugó sin cantar flor puede responder con flor al envido', () {
      final h = start(a: florA, b: weakB);
      play(h, Seat.a, c(5, Suit.oro));
      expect(canCall(h, Seat.a, BetCall.flor), false, reason: 'preclusión de iniciativa');
      call(h, Seat.b, BetCall.envido);
      expect(h.legalActions(Seat.a), [const CallAction(BetCall.flor)]);
      call(h, Seat.a, BetCall.flor);
      expect(h.awardedA, 3);
    });

    test('ambos con flor, el rival sólo la reconoce: 3 puntos para cada uno', () {
      final h = start(a: florA, b: florB28);
      call(h, Seat.a, BetCall.flor);
      expect(h.toAct, Seat.b);
      expect(h.legalActions(Seat.b),
          [const CallAction(BetCall.flor), const CallAction(BetCall.contraflor)]);
      call(h, Seat.b, BetCall.flor);
      expect(h.awardedA, 3);
      expect(h.awardedB, 3);
      expect(h.toAct, Seat.a);
    });

    test('Contraflor querida: gana quien tiene más flor y cobra 6', () {
      final h = start(a: florA, b: florB28);
      call(h, Seat.a, BetCall.flor);
      call(h, Seat.b, BetCall.contraflor);
      expect(h.toAct, Seat.a);
      expect(h.legalActions(Seat.a), [
        const RespondAction(BetResponse.quiero),
        const RespondAction(BetResponse.conFlorMeAchico),
      ]);
      respond(h, Seat.a, BetResponse.quiero);
      expect(h.awardedA, 6); // 38 vs 28
      expect(h.awardedB, 0);
      final ev = h.log.whereType<FlorComparedEvent>().single;
      expect(ev.winner, Seat.a);
      expect(ev.scoreA, 38);
      expect(ev.scoreB, 28);
    });

    test('Contraflor querida con empate de puntos: gana el MANO', () {
      final h = start(a: florA, b: florB38, mano: Seat.b);
      call(h, Seat.b, BetCall.flor);
      call(h, Seat.a, BetCall.contraflor);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.awardedB, 6, reason: 'B es mano y empatan 38-38');
    });

    test('Con Flor me achico: 4 puntos para quien cantó la Contraflor', () {
      final h = start(a: florA, b: florB28);
      call(h, Seat.a, BetCall.flor);
      call(h, Seat.b, BetCall.contraflor);
      respond(h, Seat.a, BetResponse.conFlorMeAchico);
      expect(h.awardedB, 4);
      expect(h.awardedA, 0);
    });

    test('flor desactivada en la mesa: no hay cantos de flor y se juega envido', () {
      final h = start(a: florA, b: weakB, cfg: const RulesConfig(withFlor: false));
      expect(h.hasFlor(Seat.a), false);
      expect(canCall(h, Seat.a, BetCall.flor), false);
      expect(canCall(h, Seat.a, BetCall.envido), true);
      expect(h.envidoPointsOf(Seat.a), 33); // 6+7+20 (mejores dos + 20)
    });
  });

  group('Fin de partida y puntos (RF-11)', () {
    test('un envido que lleva a 30 termina la mano y la partida de inmediato', () {
      final h = start(scoreA: 28, scoreB: 5);
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.isFinished, true);
      expect(h.matchWinner, Seat.a);
      expect(h.scoreA, 30);
      expect(h.log.last, isA<MatchFinishedEvent>());
      expect(h.legalActions(Seat.a), isEmpty);
    });

    test('el marcador no supera el objetivo aunque se otorguen más puntos', () {
      final h = start(scoreA: 29, scoreB: 0);
      call(h, Seat.a, BetCall.faltaEnvido);
      respond(h, Seat.b, BetResponse.quiero);
      expect(h.scoreA, 30);
      expect(h.awardedA, 1);
    });

    test('truco no querido que completa los 30 gana la partida', () {
      final h = start(scoreA: 29, scoreB: 29);
      call(h, Seat.a, BetCall.truco);
      respond(h, Seat.b, BetResponse.noQuiero);
      expect(h.matchWinner, Seat.a);
    });
  });

  group('Timeouts (RNF-DIS-03)', () {
    test('turno de tirar: la carta de menor valor de la mano', () {
      final h = start(); // A: macho, hembra, 7 espada
      final a = h.timeoutAction()!;
      expect(a, PlayCardAction(c(7, Suit.espada)));
    });

    test('responder un canto: No Quiero automático', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      expect(h.timeoutAction(), const RespondAction(BetResponse.noQuiero));
      final h2 = start();
      call(h2, Seat.a, BetCall.envido);
      expect(h2.timeoutAction(), const RespondAction(BetResponse.noQuiero));
    });

    test('contraflor pendiente: se achica; flor pendiente: la reconoce', () {
      final a = [c(5, Suit.oro), c(6, Suit.oro), c(7, Suit.oro)];
      final b = [c(1, Suit.copa), c(7, Suit.copa), c(12, Suit.copa)];
      final h = start(a: a, b: b);
      call(h, Seat.a, BetCall.flor);
      expect(h.timeoutAction(), const CallAction(BetCall.flor));
      call(h, Seat.b, BetCall.contraflor);
      expect(h.timeoutAction(), const RespondAction(BetResponse.conFlorMeAchico));
    });

    test('envido pendiente con flor en mano: se limita a cantar flor', () {
      final h = start(a: weakB, b: [c(5, Suit.oro), c(6, Suit.oro), c(7, Suit.oro)]);
      call(h, Seat.a, BetCall.envido);
      expect(h.timeoutAction(), const CallAction(BetCall.flor));
    });

    test('la acción de timeout siempre es legal', () {
      final h = start();
      expect(h.legalActions(h.toAct!).contains(h.timeoutAction()), true);
    });
  });

  group('Serialización y vista filtrada (RNF-SEG-01)', () {
    test('toJson/fromJson conserva el estado en mitad de la mano', () {
      final h = start();
      call(h, Seat.a, BetCall.truco);
      call(h, Seat.b, BetCall.envido); // el envido está primero
      final copy = TrucoHand.fromJson(
          jsonDecode(jsonEncode(h.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(copy.toJson()), jsonEncode(h.toJson()));
      expect(copy.legalActions(Seat.a), h.legalActions(Seat.a));
      // El estado restaurado evoluciona igual.
      respond(h, Seat.a, BetResponse.quiero);
      respond(copy, Seat.a, BetResponse.quiero);
      expect(jsonEncode(copy.toJson()), jsonEncode(h.toJson()));
    });

    test('la vista de un jugador no revela cartas no jugadas del rival', () {
      final h = start();
      play(h, Seat.a, c(1, Suit.espada));
      final viewB = jsonEncode(HandView.of(h, Seat.b).toJson());
      // A todavía tiene 1 de Basto y 7 de Espada en mano.
      expect(viewB.contains('"basto_1"'), false);
      expect(viewB.contains('"espada_7"'), false);
      // Pero sí ve la carta ya jugada, la muestra y las propias.
      expect(viewB.contains('"espada_1"'), true);
      expect(viewB.contains('"copa_3"'), true);
      expect(viewB.contains('"oro_4"'), true);
      expect(HandView.of(h, Seat.b).opponentCardsLeft, 2);
    });

    test('la vista sólo ofrece acciones al jugador que tiene que actuar', () {
      final h = start();
      expect(HandView.of(h, Seat.a).legalActions, isNotEmpty);
      expect(HandView.of(h, Seat.b).legalActions, isEmpty);
    });

    test('los eventos públicos nunca incluyen cartas no jugadas', () {
      final h = start();
      call(h, Seat.a, BetCall.envido);
      respond(h, Seat.b, BetResponse.quiero);
      play(h, Seat.a, c(1, Suit.espada));
      final all = jsonEncode([for (final e in h.log) e.toJson()]);
      expect(all.contains('basto_1'), false);
      expect(all.contains('espada_7'), false);
      expect(all.contains('basto_5'), false);
    });

    test('acciones: JSON ida y vuelta para todo el protocolo', () {
      final actions = <GameAction>[
        PlayCardAction(c(2, Suit.espada)),
        for (final b in BetCall.values) CallAction(b),
        for (final r in BetResponse.values) RespondAction(r),
        const FoldAction(),
      ];
      for (final a in actions) {
        final j = jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>;
        expect(GameAction.fromJson(j), a);
      }
      expect(() => GameAction.fromJson({'type': 'X'}), throwsA(isA<FormatException>()));
      expect(
          () => GameAction.fromJson({'type': 'PLAY_CARD', 'cardId': 'zzz'}),
          throwsA(isA<FormatException>()));
    });
  });
}
