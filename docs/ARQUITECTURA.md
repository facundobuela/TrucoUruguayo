# Arquitectura del Sistema - Truco Uruguayo

## 1. Visión General de la Arquitectura

El sistema implementa una arquitectura desacoplada basada en el principio **Clean Architecture** y **Servidor Autoritativo Zero-Trust**. 

```
+--------------------------------------------------------------------------+
|                              CLIENTE FLUTTER                             |
|  +-------------------+  +---------------------+  +--------------------+  |
|  |  Capa de UI       |  |  Gestión de Estado  |  |  Servicios Red/    |  |
|  |  (Widgets/Canvas) |  |  (Bloc / Cubit)     |  |  Almacenamiento    |  |
|  +---------+---------+  +----------+----------+  +---------+----------+  |
|            |                       |                       |             |
|            +-----------------------+                       |             |
|                                    v                       v             |
|                     +-----------------------------+  (WSS / REST)        |
|                     |     Motor Local (Offline)   |        |             |
|                     |     package:truco_core      |        |             |
|                     +-----------------------------+        |             |
+------------------------------------------------------------+-------------+
                                                             |
                                      +----------------------+
                                      v
+--------------------------------------------------------------------------+
|                       SERVIDOR AUTORITATIVO (BACKEND)                    |
|  +--------------------------------------------------------------------+  |
|  | Gateway WebSocket (WSS) / API REST (HTTPS con TLS 1.2 / 1.3)        |  |
|  +---------------------------------+----------------------------------+  |
|                                    |                                     |
|  +---------------------------------v----------------------------------+  |
|  | Orquestador de Partidas y Salas (Game Rooms Manager)               |  |
|  | -> Valida turnos, cantos y estado mediante:                       |  |
|  |    package:truco_core (Mismo motor de reglas que el cliente)       |  |
|  +-------------------+--------------------------------+---------------+  |
|                      |                                |                  |
|  +-------------------v---------------+  +-------------v---------------+  |
|  | Caché en Memoria (Redis)          |  | Persistencia Relacional     |  |
|  | - Mesas activas, colas matchmaking|  | - PostgreSQL (Usuarios,     |  |
|  | - Snapshots de reconexión rápida  |  |   Estadísticas, ELO, Logs)  |  |
|  +-----------------------------------+  +-----------------------------+  |
+--------------------------------------------------------------------------+
```

---

## 2. El Paquete Compartido: `core` (Single Source of Truth)

Para evitar desincronizaciones de reglas entre el juego offline y online:
1. `core` es una biblioteca pura de Dart (sin dependencias de `dart:ui`, `flutter`, ni `dart:io`).
2. Implementa de forma determinista:
   - **Modelos**: `Card`, `Suit`, `Sample`, `Player`, `Team`, `Hand`, `Round`.
   - **Jerarquía y Sustitución**: Ordenamiento de matas y piezas considerando la muestra y el Rey (12) sustituto.
   - **Evaluadores de Cantos**: Algoritmos exactos para Flor, Contraflor, Envido, Real Envido, Falta Envido y Truco.
   - **Árbitro de Mano**: Resolución de rondas y pardas (empates) según P1 a P6 del SRS.

---

## 3. Protocolo de Comunicación en Tiempo Real (WebSockets)

Toda la comunicación de partida utiliza mensajes en formato JSON estandarizado:

### 3.1 Eventos Cliente -> Servidor (Acciones de Jugador)
- `PLAY_CARD`: Tirar una carta a la mesa (`{ cardId: "espada_2" }`).
- `CALL_BET`: Realizar un canto (`{ betType: "ENVIDO" | "FLOR" | "TRUCO" | "RETRUCO" | ... }`).
- `RESPOND_BET`: Responder a un canto (`{ response: "QUIERO" | "NO_QUIERO" | "REVIRAR" }`).
- `SEND_SIGNAL`: Enviar seña facial al compañero (`{ signalType: "CEJAS" | "GUINO" | "BOCA" | ... }`).
- `FOLD_HAND`: Irse al mazo.
- `HEARTBEAT`: Ping periódico cada 5 segundos para verificar conexión activa.

### 3.2 Eventos Servidor -> Cliente (Actualizaciones de Estado)
- `HAND_DEALT`: Cartas repartidas al cliente (sólo sus 3 cartas) y la Muestra (`{ myCards: [...], sampleCard: {...} }`).
- `CARD_PLAYED`: Una carta fue jugada en la mesa por un jugador (`{ playerId: "p1", card: {...} }`).
- `BET_CALLED`: Un jugador realizó un canto (`{ playerId: "p2", betType: "TRUCO" }`).
- `ROUND_RESOLVED`: Fin de una ronda (`{ winnerPlayerId: "p1", isTied: false }`).
- `HAND_SCORED`: Puntuación final de la mano tras cantos y rondas (`{ scoreA: 15, scoreB: 12 }`).
- `SIGNAL_RECEIVED`: Seña emitida por el compañero (sólo enviada al socket del compañero).
- `RECONNECT_SNAPSHOT`: Snapshot completo del estado de la mesa al reconectarse tras un fallo de red.

---

## 4. Estrategia de Escalado y Tolerancia a Fallos

1. **Persistencia Efímera en Redis**:
   - Cada mesa activa (`room:<roomId>`) persiste su estado actual en Redis serializado en JSON/MsgPack.
   - Permite que si el proceso de servidor se reinicia, el estado de la mesa se rehidrate instantáneamente en $< 20\text{ ms}$.
2. **Ventana de Reconexión de 45 segundos**:
   - Si se interrumpe el socket de un jugador, el servidor congela el temporizador de turno y entra en estado `DISCONNECTED_WAITING`.
   - Si no reconecta en 45 segundos, entra el bot de IA a reemplazarlo temporalmente o se adjudica abandono.
