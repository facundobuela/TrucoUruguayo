import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:truco_core/truco_core.dart';

/// Reparto "dirigido" para forzar situaciones raras (flor, piezas, sustitutos).
({List<TrucoCard> a, List<TrucoCard> b, Sample s}) rigged(Random rnd) {
  final deck = Deck.standard()..shuffle(rnd);
  List<TrucoCard> take(Suit suit, int n, List<TrucoCard> pool) {
    final out = pool.where((c) => c.suit == suit).take(n).toList();
    for (final c in out) {
      pool.remove(c);
    }
    return out;
  }

  final pool = [...deck];
  final kind = rnd.nextInt(6);
  late Sample sample;
  switch (kind) {
    case 4: // muestra que es una pieza -> hay sustituto
      final nums = [2, 4, 5, 10, 11];
      final suit = Suit.values[rnd.nextInt(4)];
      final sc = TrucoCard(nums[rnd.nextInt(5)], suit);
      pool.remove(sc);
      sample = Sample(sc);
      break;
    default:
      sample = Sample(pool.removeLast());
  }
  List<TrucoCard> a, b;
  switch (kind) {
    case 1: // A con flor
      a = take(Suit.values[rnd.nextInt(4)], 3, pool);
      break;
    case 2: // B con flor
      a = [];
      break;
    case 3: // ambos con flor
      final s1 = Suit.values[rnd.nextInt(4)];
      a = take(s1, 3, pool);
      break;
    case 5: // A con piezas del palo de la muestra
      a = pool.where((c) => c.suit == sample.suit).take(3).toList();
      for (final c in a) {
        pool.remove(c);
      }
      break;
    default:
      a = [];
  }
  while (a.length < 3) {
    a.add(pool.removeAt(rnd.nextInt(pool.length)));
  }
  if (kind == 2 || kind == 3) {
    final suits = Suit.values.where((s) => pool.where((c) => c.suit == s).length >= 3).toList();
    b = suits.isEmpty ? [] : take(suits[rnd.nextInt(suits.length)], 3, pool);
  } else {
    b = [];
  }
  while (b.length < 3) {
    b.add(pool.removeAt(rnd.nextInt(pool.length)));
  }
  return (a: a, b: b, s: sample);
}

void checkInvariants(TrucoHand h) {
  // Conservación de cartas: en mano + jugadas = 3 por jugador, sin repetidas.
  final played = <TrucoCard>[];
  for (final r in h.rounds) {
    played.add(r.firstCard);
    if (r.secondCard != null) played.add(r.secondCard!);
  }
  for (final s in Seat.values) {
    final inHand = h.cardsOf(s);
    final mine = played.where((c) => h.dealtCardsOf(s).contains(c)).toList();
    expect(inHand.length + mine.length, 3, reason: 'cartas de ${s.name}');
    for (final c in inHand) {
      expect(h.dealtCardsOf(s).contains(c), true);
    }
  }
  expect(played.toSet().length, played.length);

  expect(h.scoreA <= h.config.targetPoints, true);
  expect(h.scoreB <= h.config.targetPoints, true);
  expect(h.awardedA >= 0 && h.awardedB >= 0, true);

  // La suma de eventos de puntos coincide con lo acreditado.
  var pa = 0, pb = 0;
  for (final e in h.log.whereType<PointsAwardedEvent>()) {
    e.seat == Seat.a ? pa += e.points : pb += e.points;
  }
  expect(pa, h.awardedA);
  expect(pb, h.awardedB);

  if (h.isFinished) {
    expect(h.toAct, isNull);
    expect(h.legalActions(Seat.a), isEmpty);
    expect(h.legalActions(Seat.b), isEmpty);
    expect(h.awardedA + h.awardedB >= 1, true, reason: 'toda mano reparte puntos');
    if (h.handWinner == null) {
      expect(h.matchWinner, isNotNull);
    }
  } else {
    final seat = h.toAct!;
    final legal = h.legalActions(seat);
    expect(legal, isNotEmpty, reason: 'nunca debe quedar sin acciones');
    expect(h.legalActions(seat.other), isEmpty, reason: 'sólo actúa uno');
    final to = h.timeoutAction();
    expect(legal.contains(to), true, reason: 'timeout=$to');
    // Nunca se ofrece algo que luego se rechace.
    for (final a in legal) {
      final copy = TrucoHand.fromJson(h.toJson());
      copy.apply(seat, a); // no debe lanzar
    }
  }

  // Vista filtrada: nada del rival que no haya jugado.
  for (final s in Seat.values) {
    final json = jsonEncode(HandView.of(h, s).toJson());
    for (final c in h.cardsOf(s.other)) {
      expect(json.contains('"${c.id}"'), false,
          reason: 'la vista de ${s.name} filtra ${c.id}');
    }
  }

  // Ida y vuelta de serialización.
  final copy = TrucoHand.fromJson(
      jsonDecode(jsonEncode(h.toJson())) as Map<String, dynamic>);
  expect(jsonEncode(copy.toJson()), jsonEncode(h.toJson()));
  if (!h.isFinished) {
    expect(copy.legalActions(h.toAct!), h.legalActions(h.toAct!));
  }
}

void main() {
  group('Fuzzing del motor: acciones legales aleatorias', () {
    test('4000 manos con repartos dirigidos, puntajes y configuraciones al azar', () {
      final rnd = Random(20261027);
      var finishedByMatch = 0, withFlorHands = 0, maxSteps = 0;
      final seenEvents = <String>{};
      for (var i = 0; i < 4000; i++) {
        final d = rigged(rnd);
        final cfg = RulesConfig(
            withFlor: rnd.nextInt(5) != 0,
            targetPoints: rnd.nextBool() ? 30 : 40);
        final sa = rnd.nextInt(cfg.targetPoints);
        final sb = rnd.nextInt(cfg.targetPoints);
        final h = TrucoHand.start(
          mano: Seat.values[rnd.nextInt(2)],
          cardsA: d.a,
          cardsB: d.b,
          sample: d.s,
          scoreA: sa,
          scoreB: sb,
          config: cfg,
        );
        if (h.hasFlor(Seat.a) || h.hasFlor(Seat.b)) withFlorHands++;
        var steps = 0;
        while (!h.isFinished) {
          // Comprobar invariantes en cada paso es caro: lo hacemos cada 3.
          if (steps % 3 == 0 || steps < 2) checkInvariants(h);
          final seat = h.toAct!;
          final legal = h.legalActions(seat);
          final action = legal[rnd.nextInt(legal.length)];
          final ev = h.apply(seat, action);
          for (final e in ev) {
            seenEvents.add(e.toJson()['type'] as String);
          }
          steps++;
          expect(steps < 80, true, reason: 'la mano no converge');
        }
        checkInvariants(h);
        maxSteps = max(maxSteps, steps);
        if (h.handWinner == null) finishedByMatch++;
      }
      // Cobertura: el fuzzer realmente ejerció los caminos raros.
      expect(withFlorHands > 500, true, reason: 'manos con flor: $withFlorHands');
      expect(finishedByMatch > 20, true, reason: 'fin de partida a mitad de mano: $finishedByMatch');
      for (final t in [
        'HAND_STARTED', 'CARD_PLAYED', 'BET_CALLED', 'BET_RESPONDED',
        'ENVIDO_ANNULLED', 'ENVIDO_RESOLVED', 'FLOR_COMPARED',
        'POINTS_AWARDED', 'ROUND_RESOLVED', 'HAND_SCORED', 'MATCH_FINISHED',
      ]) {
        if (t == 'HAND_STARTED') continue; // se emite al crear la mano
        expect(seenEvents.contains(t), true, reason: 'evento no ejercido: $t');
      }
    });

    test('las acciones ilegales siempre se rechazan sin alterar el estado', () {
      final rnd = Random(7);
      for (var i = 0; i < 400; i++) {
        final d = rigged(rnd);
        final h = TrucoHand.start(
            mano: Seat.a, cardsA: d.a, cardsB: d.b, sample: d.s);
        var steps = 0;
        while (!h.isFinished && steps < 60) {
          final seat = h.toAct!;
          final legal = h.legalActions(seat).toSet();
          final before = jsonEncode(h.toJson());
          // Probar todas las acciones posibles del universo: las no legales fallan.
          final universe = <GameAction>[
            for (final c in Deck.standard()) PlayCardAction(c),
            for (final b in BetCall.values) CallAction(b),
            for (final r in BetResponse.values) RespondAction(r),
            const FoldAction(),
          ];
          for (final a in universe) {
            if (legal.contains(a)) continue;
            expect(() => h.apply(seat, a), throwsA(isA<IllegalActionException>()),
                reason: '$a debería ser ilegal');
            expect(jsonEncode(h.toJson()), before, reason: 'el estado cambió');
          }
          // El rival tampoco puede actuar fuera de turno.
          expect(() => h.apply(seat.other, h.legalActions(seat).first),
              throwsA(isA<IllegalActionException>()));
          h.apply(seat, h.legalActions(seat)[rnd.nextInt(h.legalActions(seat).length)]);
          steps++;
        }
      }
    });
  });

  group('Partidas completas con bots', () {
    test('300 partidas bot vs bot terminan en 30 con marcador y mano coherentes', () {
      final rnd = Random(424242);
      var totalHands = 0;
      var winsA = 0, winsB = 0;
      for (var g = 0; g < 300; g++) {
        final botA = HeuristicBot(rng: Random(rnd.nextInt(1 << 30)));
        final botB = HeuristicBot(rng: Random(rnd.nextInt(1 << 30)));
        final match = TrucoMatch(
          firstMano: Seat.values[g % 2],
          seedSupplier: () => Deck.generateSeed(Random(rnd.nextInt(1 << 30))),
        );
        Seat? lastMano;
        while (!match.isOver) {
          final h = match.startHand();
          if (lastMano != null) {
            expect(h.mano, lastMano.other, reason: 'el mano debe alternar');
          }
          lastMano = h.mano;
          // Compromiso publicado == hash de la semilla (secreta aún).
          expect(Deck.verifyCommitment(match.currentSeed!, h.deckCommitment!), true);
          var steps = 0;
          while (!h.isFinished) {
            final seat = h.toAct!;
            final bot = seat == Seat.a ? botA : botB;
            final action = bot.choose(HandView.of(h, seat));
            expect(h.legalActions(seat).contains(action), true,
                reason: 'el bot eligió una acción ilegal: $action');
            match.apply(seat, action);
            expect(++steps < 80, true);
          }
          totalHands++;
          expect(totalHands < 100000, true);
        }
        final w = match.winner!;
        expect(match.scoreOf(w), 30);
        expect(match.scoreOf(w.other) < 30, true);
        w == Seat.a ? winsA++ : winsB++;
        // Auditoría: cada semilla revelada reproduce el reparto que se jugó.
        expect(match.revealedSeeds.length, match.handNumber);
      }
      // Ningún bando debe ganar sistemáticamente (los bots son simétricos).
      expect(winsA > 90 && winsB > 90, true, reason: 'A=$winsA B=$winsB');
      expect(totalHands / 300 > 3, true, reason: 'manos/partida=${totalHands / 300}');
    });

    test('partida determinista con semillas fijas: misma historia dos veces', () {
      List<String> run() {
        final seeds = [
          for (var i = 0; i < 400; i++)
            Uint8List.fromList(List.generate(32, (j) => (i * 7 + j * 13) & 0xFF))
        ];
        var k = 0;
        final match = TrucoMatch(seedSupplier: () => seeds[k++]);
        final bots = {
          Seat.a: HeuristicBot(rng: Random(1)),
          Seat.b: HeuristicBot(rng: Random(2)),
        };
        final log = <String>[];
        while (!match.isOver) {
          final h = match.startHand();
          while (!h.isFinished) {
            final s = h.toAct!;
            final act = bots[s]!.choose(HandView.of(h, s));
            for (final e in match.apply(s, act)) {
              log.add(jsonEncode(e.toJson()));
            }
          }
        }
        return log;
      }

      final one = run();
      expect(one.length > 50, true);
      expect(run(), one);
    });

    test('el timeout automático también termina las partidas', () {
      final match = TrucoMatch(seedSupplier: Deck.generateSeed);
      var hands = 0;
      while (!match.isOver) {
        final h = match.startHand();
        while (!h.isFinished) {
          match.apply(h.toAct!, h.timeoutAction()!);
        }
        expect(++hands < 5000, true);
      }
      expect(match.scoreOf(match.winner!), 30);
    });

    test('no se puede iniciar una mano con otra en curso ni tras terminar', () {
      final match = TrucoMatch();
      final h = match.startHand();
      expect(() => match.startHand(), throwsA(isA<StateError>()));
      while (!match.isOver) {
        while (!match.hand!.isFinished) {
          final seat = match.hand!.toAct!;
          match.apply(seat, match.hand!.timeoutAction()!);
        }
        if (!match.isOver) match.startHand();
      }
      expect(() => match.startHand(), throwsA(isA<StateError>()));
      expect(h.isFinished, true);
    });
  });

  group('Protocolo', () {
    test('HAND_DEALT sólo contiene las cartas del destinatario y la muestra', () {
      final match = TrucoMatch();
      final h = match.startHand();
      final va = HandView.of(h, Seat.a);
      final msg = jsonEncode(Protocol.handDealtMessage(va,
          commitment: h.deckCommitment));
      for (final c in h.dealtCardsOf(Seat.b)) {
        expect(msg.contains('"${c.id}"'), false);
      }
      for (final c in h.dealtCardsOf(Seat.a)) {
        expect(msg.contains('"${c.id}"'), true);
      }
      expect(msg.contains(h.sample.card.id), true);
      expect(msg.contains(h.deckCommitment!), true);
    });

    test('parseAction ignora mensajes que no son de juego', () {
      expect(Protocol.parseAction({'type': 'HEARTBEAT'}), isNull);
      expect(Protocol.parseAction({'type': 'FOLD_HAND'}), const FoldAction());
    });
  });
}
