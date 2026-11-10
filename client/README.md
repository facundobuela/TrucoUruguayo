# Cliente Móvil Flutter - Truco Uruguayo

Aplicación móvil desarrollada con **Flutter** para plataformas Android e iOS.

## Estructura del Cliente
```
client/
├── android/          # Configuración nativa Android (Keystore, API 26+)
├── ios/              # Configuración nativa iOS (Keychain, iOS 15+)
├── lib/
│   ├── app/          # Inyección de dependencias, temas visuales y rutas
│   ├── features/     # Módulos funcionales:
│   │   ├── auth/     # Login con Google, Apple, Invitado
│   │   ├── game/     # Tapete de juego 2D, mesa, animaciones de cartas
│   │   ├── signals/  # Menú táctil de señas visuales entre compañeros
│   │   ├── school/   # Tutorial interactivo y modo escuela
│   │   ├── profile/  # Perfil, estadísticas ELO, eliminación de cuenta
│   │   └── settings/ # Opciones de audio folclórico, daltonismo
│   └── main.dart     # Entrada principal
└── pubspec.yaml
```

## Feature `game` (estructura actual)
```
lib/features/game/
├── controller/
│   ├── game_controller.dart          # Contrato: HandView + acciones (UI no conoce el motor)
│   ├── offline_game_controller.dart  # TrucoMatch local + bot + temporizadores
│   └── speech_bubbles.dart           # Cola de globos de texto (Dart puro)
├── text/game_texts.dart              # Textos y frases (base para i18n)
└── presentation/
    ├── game_screen.dart              # Ensambla los widgets desde el GameController
    └── widgets/                      # Un widget por archivo, sin lógica de reglas
```
Reglas del módulo: los widgets leen **`HandView`** (nunca `TrucoHand`) y el modo
online se agrega como un nuevo `GameController` sin tocar los widgets. El estado
se resuelve hoy con `ChangeNotifier`; migrar a `flutter_bloc` sólo afecta a `controller/`.

## Menú y modos de juego
```
lib/features/
├── menu/       main_menu_screen.dart (Jugar / Partidas Elo), play_modes_screen.dart, widgets/
├── modes/      game_mode.dart (catálogo de modos), game_session_factory.dart (modo -> GameController)
└── ranked/     ranked_service.dart (contrato de Elo; hoy "no disponible"), ranked_screen.dart
```
- **Agregar un modo**: definirlo en `GameModes` y resolverlo en `DefaultGameSessionFactory.create`.
  Un modo con `availability: comingSoon` aparece en el menú como "Próximamente".
- **Partidas Elo**: cuando exista el servidor, implementar `RankedService` (perfil + búsqueda
  de mesa) y pasarlo a `TrucoApp(rankedService: ...)`; la pantalla no cambia. El cálculo
  de Elo vive en `truco_core` (`Elo`).
- Las partidas contra el Bot nunca suman Elo (RF-02): `GameMode.countsForElo`.

## Sonido
Efectos (carta que cae, cartas al mazo) y voces de cantos/respuestas/tantos, con el
paquete `audioplayers`. La lógica no depende del plugin: `GameAudio` (Dart puro) es el
contrato, `AudioPlayersGameAudio` la implementación real y `SilentGameAudio` la muda
(tests). El botón de volumen de la barra superior silencia todo. Detalles, claves de
voz y licencias en `assets/audio/README.md`; generador en `tools/generate_audio.py`.

## Dependencias Clave
- `truco_core`: Referencia local al paquete `../core` (motor de reglas único).
- `web_socket_channel`: Comunicación WSS en tiempo real.
- `flutter_bloc`: Gestión de estados predecible y reactiva.
- `flutter_secure_storage`: Almacenamiento cifrado en Keystore (Android) y Keychain (iOS).
