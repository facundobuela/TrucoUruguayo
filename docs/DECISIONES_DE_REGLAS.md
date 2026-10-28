# Decisiones de reglas implementadas en `truco_core`

Reglas que el SRS (v0.2.0) o el MVP dejan ambiguas y que el motor ya resolvió de
una forma concreta. **Ninguna está validada con jugadores**: las marcadas
`[VERIFICAR]` deben confirmarse antes de congelar el motor. Cambiar cualquiera
es un cambio local en `core/lib/src/game/hand.dart` o `rules/`.

| # | Regla | Decisión implementada | Estado |
|---|-------|----------------------|--------|
| 1 | Malas / buenas | Un jugador está en malas mientras tiene **menos de 15**; con 15 ya está en buenas | [VERIFICAR] |
| 2 | Falta Envido | `puntero < 15 ? 15 - puntero : 30 - puntero` (puntero = el que va ganando) | [VERIFICAR] |
| 3 | Escalera de envido | Envido → (Envido una sola vez) → Real → Falta. Tras Real sólo Falta | [VERIFICAR] |
| 4 | Envido "no quiero" | 1 punto si es el canto inicial; si no, lo acumulado antes del último revire | SRS |
| 5 | Envido con Flor | Quien tiene flor no puede cantar envido y, si el rival lo canta, sólo puede responder Flor (que lo anula) | [VERIFICAR] |
| 6 | Quién muestra el tanto | El mano declara siempre; el pie sólo muestra si iguala o supera ("son buenas") | [VERIFICAR] |
| 7 | Ventana de envido/flor | Sólo 1ª ronda y antes de que ese jugador tire su carta. Excepción: al responder un Truco ("el envido está primero") puede cantar aunque ya haya tirado | [VERIFICAR] |
| 8 | Envido tras Truco | Con Truco **aceptado** ya no se canta envido; con Truco **pendiente** sí (envido está primero) | [VERIFICAR] |
| 9 | Flor sin flor rival | 3 puntos inmediatos | SRS |
| 10 | Ambos con flor, rival sólo la reconoce | Cada uno cobra 3 (el SRS no lo define) | [VERIFICAR] |
| 11 | Contraflor querida | Gana la flor más alta (empate: el mano) y cobra 6 | SRS |
| 12 | Con Flor me achico | 4 puntos para quien cantó la Contraflor | SRS |
| 13 | Contraflor al Resto | **No implementada** (el MVP no la incluye; el SRS sí) | pendiente |
| 14 | Derecho a subir el Truco | Sólo quien dijo "Quiero" puede subir al siguiente nivel | [VERIFICAR] |
| 15 | Irse al mazo | Sólo en el turno propio sin cantos pendientes; el rival cobra el nivel de truco aceptado (1 si no hay) | [VERIFICAR] |
| 16 | Abre tras parda | Quien tiró primero en la ronda empatada (SRS) | SRS |
| 17 | Envido con pieza y 2 cartas del mismo palo (flor desactivada en mesa) | Pieza + carta facial más alta | [VERIFICAR] |
| 18 | Marcador | Se limita al objetivo (30); una mano termina de inmediato si un envido/flor lleva a 30 | [VERIFICAR] |
| 19 | Timeout | Responder "No Quiero" / "Con Flor me achico"; reconocer la flor; si no, tirar la carta de menor jerarquía (RNF-DIS-03) | SRS |
| 20 | Reparto | Mazo barajado con SHA-256 en modo contador y Fisher-Yates sin sesgo. A recibe posiciones 0,2,4; B 1,3,5; muestra 6 | decisión técnica |

## Diferencias con `docs/ARQUITECTURA.md`

- No existe la respuesta `REVIRAR`: subir una apuesta es otro `CALL_BET` con el canto superior.
- Se agregó la respuesta `CON_FLOR_ME_ACHICO` y los cantos `CONTRAFLOR`, `REAL_ENVIDO`, `FALTA_ENVIDO`, `VALE_CUATRO`.
- Se usan `playerId` = `a` | `b`; el servidor deberá mapear usuarios a asiento.
- Mensajes nuevos de lobby y revelación de semilla: ver `Protocol` en `core/lib/src/protocol/messages.dart`.
