/// Biblioteca principal del motor de reglas del Truco Uruguayo.
///
/// Dart puro: sin Flutter, sin `dart:io`, sin `dart:ui`. Se ejecuta igual en el
/// cliente (modo offline) y en el servidor autoritativo.
library truco_core;

export 'src/crypto/sha256.dart';
export 'src/deck/deck.dart';
export 'src/game/actions.dart';
export 'src/game/events.dart';
export 'src/game/hand.dart';
export 'src/game/match.dart';
export 'src/game/view.dart';
export 'src/bot/heuristic_bot.dart';
export 'src/protocol/messages.dart';
export 'src/models/suit.dart';
export 'src/models/card.dart';
export 'src/models/sample.dart';
export 'src/models/seat.dart';
export 'src/rules/envido_calculator.dart';
export 'src/rules/envido_chain.dart';
export 'src/rules/flor_calculator.dart';
export 'src/rules/round_resolver.dart';
export 'src/rules/rules_config.dart';
