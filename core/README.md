# `truco_core`

Núcleo determinista y puro de reglas para el **Truco Uruguayo**.

## Responsabilidades
- Baraja española de 40 cartas y generación aleatoria con semilla.
- Determinación de la **Muestra**, **Piezas** (2, 4, 5, 11-Perico, 10-Perica) y **Carta Sustituta** (Rey 12).
- Jerarquía estricta de cartas y desempates.
- Algoritmo de cálculo de **Flor** y **Envido** con piezas uruguayas.
- Árbitro de rondas, pardas (empates en 1ª, 2ª y 3ª) y cantos de Truco.
- Máquina de estados inmutable de la mano.

Este paquete no depende de Flutter, lo que permite su importación directa tanto en la app cliente como en el backend.
