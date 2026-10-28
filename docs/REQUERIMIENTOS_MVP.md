# Requerimientos para el MVP (Producto Mínimo Viable)
## Proyecto: Truco Uruguayo Móvil
**Versión:** 1.0.0 (MVP Scope)  
**Fecha:** 26 de Octubre de 2026  
**Objetivo:** Publicar una versión jugable, auténtica, estable y conforme a las tiendas, minimizando la complejidad inicial sin sacrificar las reglas folclóricas del Truco Uruguayo.

---

## 🎯 Enfoque Estratégico del MVP
El MVP se enfoca exclusivamente en la modalidad **1 vs 1 (Mano a Mano)** con dos opciones de juego:
1. **Modo Solitario (Offline vs IA)**: Para jugar inmediatamente sin conexión ni latencia.
2. **Modo Multijugador 1v1 Online**: Mediante salas privadas por código y partida rápida casual.

*Las modalidades por equipos (2v2 y 3v3), las señas faciales, los torneos masivos y el sistema de clanes se reservan para la Fase 2.*

---

## 📋 Lista de Requerimientos Funcionales del MVP (RF-MVP)

### 1. Motor de Reglas (Truco Uruguayo Auténtico)
- **RF-MVP-01: Mazo y Muestra Oficial**
  - Mazo español de 40 cartas barajado con generador criptográfico (CSPRNG).
  - Descubrimiento de 1 carta como Muestra al inicio de cada mano.
  - Asignación de las 5 Piezas: 2, 4, 5, 11 (Perico) y 10 (Perica) del palo de la muestra.
  - Regla de **Carta Sustituta**: Si la muestra es una pieza (2, 4, 5, 11 o 10), el Rey (12) del mismo palo asume su valor, jerarquía y puntaje.
- **RF-MVP-02: Jerarquía de Matas y Cartas Restantes**
  - Orden estricto: Piezas > 1 Espada (Macho) > 1 Basto (Hembra) > 7 Espada > 7 Oro > Treses > Doses comunes > Unos comunes (Copa/Oro) > Reyes > Caballos > Sotas > Sietes comunes > Seises > Cincos > Cuatros.
- **RF-MVP-03: Sistema de Flor y Precedencia**
  - Detección de las 4 combinaciones válidas de Flor.
  - Puntuación con piezas ($2=30$, $4=29$, $5=28$, $11/10=27$, comunes $1\text{-}7$, figuras $0$, base $+20$ en flores sin piezas).
  - Precedencia absoluta: El canto de Flor anula cualquier Envido previo.
  - Cantos: *Flor* (3 pts), *Contraflor* (6 pts o 4 pts si el rival se achica).
- **RF-MVP-04: Sistema de Envido y Desempate**
  - Canto habilitado solo en 1ª ronda antes de tirar la carta del jugador.
  - La pieza liga con cualquier carta ajena (pieza + carta más alta).
  - Cantos: *Envido* (2 pts), *Real Envido* (3 pts) y *Falta Envido* (puntos restantes para 15 en malas o 30 en buenas).
  - En caso de empate en puntos de Envido o Flor, **gana el jugador Mano**.
  - Si un jugador canta Truco en 1ª ronda sin envido previo, el rival puede cantar *"El Envido está primero"*.
- **RF-MVP-05: Sistema de Truco y Rendición**
  - Cantos: *Truco* (2 pts), *Retruco* (3 pts), *Vale Cuatro* (4 pts).
  - Respuestas: *Quiero*, *No Quiero* (concede los puntos previos acumulados) o revire.
  - Acción de *Irse al Mazo* en cualquier momento del turno.
- **RF-MVP-06: Rondas y Resolución de Pardas**
  - 3 rondas por mano.
  - Resolución de empates:
    - Parda en 1ª: define la 2ª ronda.
    - Parda en 2ª: gana quien ganó la 1ª.
    - Parda en 3ª: gana quien ganó la 1ª.
    - Parda en las tres: gana el jugador **Mano**.
  - Tras una parda, abre la siguiente ronda quien tiró primero en la ronda empatada.
- **RF-MVP-07: Tanteador Tradicional**
  - Partida a 30 puntos (15 malas y 15 buenas).
  - Visualización gráfica de marcador mediante fósforos/rayas.

---

### 2. Modalidades de Juego del MVP
- **RF-MVP-08: Modo Solitario Offline vs IA**
  - Juego individual contra bot local con lógica heurística básica (utiliza el paquete `truco_core` directamente en el dispositivo).
  - Funcional sin conexión a internet.
- **RF-MVP-09: Multijugador 1v1 con Amigos (Salas Privadas)**
  - Creación de sala con código alfanumérico de 5 caracteres.
  - El anfitrión comparte el código y el invitado ingresa a la mesa en tiempo real.
- **RF-MVP-10: Partida Rápida Online (Casual)**
  - Cola simple de matchmaking 1v1 que empareja a dos jugadores disponibles.
  - Si transcurren más de 30 segundos sin encontrar rival, ofrece completar con un bot para no frustrar la espera.

---

### 3. Gestión de Usuarios y Cumplimiento con Tiendas
- **RF-MVP-11: Acceso Inmediato (Modo Invitado / Guest)**
  - El usuario puede abrir la app y jugar en 1 toque como "Invitado", sin registro forzado.
  - Opción de vincular posteriormente su cuenta con Google Sign-In o Apple ID.
- **RF-MVP-12: Perfil Mínimo de Jugador**
  - Alias editable, avatar básico seleccionable, contador de partidas ganadas y perdidas.
- **RF-MVP-13: Eliminación de Cuenta en la App (Exigencia Apple & Google)**
  - Botón visible en Ajustes para borrar definitivamente la cuenta y los datos asociados.
- **RF-MVP-14: Silencio y Reporte de Jugador (Exigencia Apple)**
  - Posibilidad de silenciar o reportar al rival en partidas online por conducta antideportiva.

---

### 4. Experiencia de Usuario e Interfaz (UI/UX)
- **RF-MVP-15: Tapete Vertical Diseñado para Uso con Una Mano**
  - Visualización de la Muestra descubierta en la esquina o centro superior.
  - 3 cartas del jugador en la parte inferior con interacción táctil (arrastrar o toque simple para arrojar al centro).
  - Botones de cantos inteligentes: solo se muestran o iluminan aquellos cantos que sean reglamentariamente válidos en ese instante del juego.
- **RF-MVP-16: Feedback Visual y Sonoro Esencial**
  - Sonido de cartas al barajar y repartir.
  - Efectos de sonido clásicos opcionales para los cantos ("¡Truco!", "¡Quiero!").
  - Confirmación por vibración háptica suave al tirar carta.

---

## ⚙️ Requerimientos No Funcionales del MVP (RNF-MVP)

- **RNF-MVP-01 (Servidor Autoritativo)**: La mezcla y validación de cantos en partidas online se ejecuta en el servidor. El cliente solo recibe sus propias 3 cartas y la Muestra.
- **RNF-MVP-02 (Rendimiento)**: 60 FPS estables en animaciones de cartas en dispositivos Android (API 26+) e iOS (15+).
- **RNF-MVP-03 (Latencia de Red)**: Tiempo de procesamiento de jugada en servidor $< 30$ ms y latencia RTT regional $< 120$ ms vía WebSockets.
- **RNF-MVP-04 (Tolerancia a Fallos y Reconexión Rápida)**:
  - Ventana de reconexión de 30 segundos ante desconexión de red móvil.
  - Si el jugador reconecta en ese lapso, la app recupera el estado exacto de la mano.
- **RNF-MVP-05 (Temporizador de Turno / Timeout)**:
  - Temporizador de 20 segundos por turno.
  - Si expira el tiempo para tirar: arroja automáticamente la carta de menor valor.
  - Si expira el tiempo para responder canto: responde automáticamente "No Quiero".
- **RNF-MVP-06 (Economía Sin Juego de Azar)**:
  - No hay apuestas con dinero real. Declaración formal ante las tiendas de ausencia de juegos de azar (*"no gambling"*).

---

## 🚫 Funcionalidades Diferidas (Post-MVP / Fase 2)
Para garantizar una salida rápida y de alta calidad, las siguientes características quedan formalmente excluidas del MVP inicial:
- ❌ Partidas por parejas (2 vs 2) y tríos (3 vs 3).
- ❌ Selector táctil de señas faciales entre compañeros.
- ❌ Sistema de torneos con llaves/brackets.
- ❌ Ranking ELO competitivo con ligas mensuales y temporadas.
- ❌ Chat de texto libre entre usuarios.
- ❌ Tienda de compras in-app y monetización avanzada.
- ❌ Partidas configurables a 40 puntos (el MVP se fija en los tradicionales 30 puntos).
