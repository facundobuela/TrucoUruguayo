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

## Dependencias Clave
- `truco_core`: Referencia local al paquete `../core` (motor de reglas único).
- `web_socket_channel`: Comunicación WSS en tiempo real.
- `flutter_bloc`: Gestión de estados predecible y reactiva.
- `flutter_secure_storage`: Almacenamiento cifrado en Keystore (Android) y Keychain (iOS).
