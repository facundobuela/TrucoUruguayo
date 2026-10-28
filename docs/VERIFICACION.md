# Verificación de la estructura y documentos (26/10/2026)

## Inconsistencias entre documentos (a decidir por el equipo)

| Tema | SRS v0.2.0 | REQUERIMIENTOS_MVP | ARQUITECTURA / READMEs |
|------|-----------|--------------------|------------------------|
| Ventana de reconexión | 45 s | **30 s** | 45 s |
| Tiempo de turno | configurable 15/30/60 s | **20 s** fijo | – |
| Espera antes de ofrecer bot | 45 s | **30 s** | – |
| Cantos de envido | Envido, **Envido-Envido**, Real, Falta | sin Envido-Envido | – |
| Cantos de flor | Flor, Contraflor, Me achico, **Al Resto** | sin Al Resto | – |
| Bloqueo de jugadores | silenciar, reportar y **bloquear** | sólo silenciar y reportar (Apple exige bloquear) | – |
| Ubicación del SRS | `docs/REQUERIMIENTOS.txt` (README raíz, árbol) | – | el archivo está en la **raíz**, y el link del README apunta a la raíz |
| Servidor | "Dart" (RNF-ADA-01) | – | `server/README.md` usa estructura `src/` de Node/TS; en Dart sería `bin/` + `lib/` |
| Acción `REVIRAR` | – | – | no existe en el motor (ver DECISIONES_DE_REGLAS.md) |
| Aleatoriedad | CSPRNG + hash de semilla | CSPRNG | `core/README.md` dice "aleatoria con semilla": una semilla fija no es CSPRNG; implementado como semilla CSPRNG + expansión determinista |
| `core` "máquina de estados inmutable" | – | – | implementada **mutable** y serializable (`toJson`/`fromJson`), suficiente para snapshots de Redis |

## Estado del código existente

- `core` original: modelos, jerarquía, envido, flor y pardas correctos; 27 tests pasaban.
- Faltaba todo lo dinámico: mazo, turnos, cantos, truco, mazo/fold, marcador, bot, protocolo.
- No había `analysis_options.yaml` aunque `lints` estaba en dev_dependencies.
- `server/` y `client/` contienen solo README (sin código).

## Qué se implementó en esta iteración

Ver `core/README.md`. Servidor y cliente **no** se han iniciado.
