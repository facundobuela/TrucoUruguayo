# Audio de la partida

```
sfx/                      efectos (WAV)
  card_place_1..3.wav     carta que cae sobre la mesa (se elige una al azar)
  cards_to_deck.wav       cartas que se recogen / se van al mazo
voice/player/<clave>.mp3  TU voz (cantos, respuestas, tantos)
voice/rival/<clave>.mp3   voz del rival (mismas claves)
```

## ⚠️ Estado: marcadores de posición
Todos estos audios están **generados por computadora** con `tools/generate_audio.py`:
los efectos se sintetizan con numpy y las voces con **espeak-ng** (voz robótica).
Sirven para desarrollar y probar el ritmo del juego, **no para publicar**.

Para publicar, reemplazá las voces por grabaciones reales (RF-20: "locuciones típicas
con audio folclórico") **con exactamente los mismos nombres de archivo**, y luego
recalculá las duraciones:

```
python3 tools/generate_audio.py --manifest-only
```

(el globo de texto dura lo que dura su voz; ese comando actualiza
`lib/features/game/audio/voice_durations.dart`).

## Claves de voz
`envido`, `envido_envido`, `real_envido`, `falta_envido`, `flor`, `contraflor`, `truco`,
`retruco` ("Quiero retruco"), `vale_cuatro` ("Quiero vale cuatro"), `quiero`, `quiero_dale`,
`no_quiero`, `no_no_quiero`, `con_flor_me_achico`, `me_voy_al_mazo`, `al_mazo`, `son_buenas`,
`tengo_0` … `tengo_59` (envido) y `flor_de_20` … `flor_de_87`.
El test `test/game_voices_test.dart` falla si falta alguno.

## Licencias
- `espeak-ng` es GPL-3; el audio que genera se usa aquí sólo como marcador de posición.
- **No uses las voces MBROLA** (`--engine mbrola`): su licencia prohíbe incorporarlas a un
  producto que se venda o con fines comerciales. Esa opción existe sólo para probar en local.
- Cualquier grabación, banco de sonidos o voz de terceros que agregues debe permitir uso
  comercial; verificá su licencia antes de publicar.
