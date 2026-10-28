# `truco_core`

Núcleo determinista y puro de reglas del **Truco Uruguayo** (1 vs 1). Dart puro:
sin Flutter, sin `dart:io`, sin dependencias de runtime. Se usa idéntico en el
cliente (modo offline) y en el servidor autoritativo.

## Contenido

| Módulo | Archivo | Responsabilidad |
|--------|---------|-----------------|
| Modelos | `models/` | `TrucoCard`, `Suit`, `Seat`, `Sample` (muestra, piezas y Rey sustituto) |
| Mazo auditable | `deck/deck.dart`, `crypto/sha256.dart` | Semilla CSPRNG → barajado determinista (Fisher-Yates sin sesgo); compromiso SHA-256 publicado y semilla revelada al terminar la mano |
| Cálculos | `rules/` | Envido, Flor, cadena de envido (Falta), árbitro de rondas y pardas |
| Mano | `game/hand.dart` | Máquina de estados: turnos, truco/retruco/vale cuatro, envido, flor/contraflor, mazo, timeouts, serialización |
| Partida | `game/match.dart` | 30 puntos, rotación del mano, semillas y auditoría |
| Vista | `game/view.dart` | `HandView`: lo único que un jugador puede saber (Zero-Trust) y sus acciones legales |
| Bot | `bot/heuristic_bot.dart` | IA heurística que sólo ve su `HandView` |
| Protocolo | `protocol/messages.dart` | Códecs JSON de `docs/ARQUITECTURA.md` |

## Uso

```dart
final match = TrucoMatch();           // semilla CSPRNG por mano
final hand = match.startHand();
final view = HandView.of(hand, Seat.a);   // acciones legales en view.legalActions
match.apply(Seat.a, view.legalActions.first);
```

## Pruebas

```
dart pub get && dart test
```

121 pruebas: matriz del SRS (J, P, F, E, T), jerarquía de las 40 cartas para
todas las muestras, SHA-256 contra vectores NIST, fuzzing con acciones legales
e ilegales sobre 4000 manos, 300 partidas bot vs bot y determinismo por semilla.

Reglas ambiguas resueltas y pendientes de validar: `docs/DECISIONES_DE_REGLAS.md`.
