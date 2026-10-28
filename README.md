# Truco Uruguayo 🇺🇾

Plataforma móvil multiplataforma (iOS y Android) para jugar al auténtico **Truco Uruguayo** tanto en modo solitario contra Inteligencia Artificial como en partidas multijugador online en tiempo real (1v1, 2v2 y 3v3).

---

## 🏛️ Arquitectura del Repositorio (Monorepo Modular)

El proyecto está organizado en módulos desacoplados para garantizar la reutilización de código, escalabilidad y mantenibilidad:

```
TrucoUruguayo/
├── core/                  # Motor de reglas único y puro (Single Source of Truth en Dart)
│   ├── lib/               # Modelos, jerarquías, cálculo de Flor/Envido/Truco y pardas
│   └── test/              # Suite exhaustiva de pruebas unitarias (TDD con >95% cobertura)
│
├── client/                # Aplicación móvil en Flutter (iOS & Android)
│   ├── lib/               # UI reactiva a 60 FPS, animaciones 2D, señas, audio y estado
│   └── assets/            # Baraja española de 40 cartas, audios de cantos folclóricos
│
├── server/                # Servidor autoritativo de partidas en tiempo real
│   ├── src/               # Game rooms, matchmaking, WebSockets (WSS), Redis y PostgreSQL
│   └── docker/            # Contenedores para despliegue local y producción
│
├── docs/                  # Especificaciones, arquitectura y contratos de comunicación
│   ├── ARQUITECTURA.md    # Diseño de capas, diagramas de secuencia y eventos WS
│   ├── REQUERIMIENTOS_MVP.md
│   ├── DECISIONES_DE_REGLAS.md
│   └── VERIFICACION.md
│
├── .gitignore             # Exclusiones completas para mobile, backend, IDEs y secretos
└── README.md              # Este archivo
```

---

## 🎯 Principios de Ingeniería

- **Single Source of Truth (`core`)**: El paquete `core` no depende de Flutter ni de librerías de red; es código puro que se ejecuta idénticamente en el cliente local (modo offline) y en el servidor autoritativo (modo online).
- **Servidor Autoritativo Zero-Trust**: La generación criptográfica del mazo (CSPRNG), el reparto y la validación de cantos se realiza en el servidor para impedir cualquier trampa en partidas online.
- **Reglas Fieles al Truco Uruguayo**:
  - Gestión rigurosa de la **Muestra** y las **5 Piezas** (2, 4, 5, 11-Perico, 10-Perica).
  - Regla universal de **Carta Sustituta** (el 12-Rey reemplaza a cualquier pieza que salga como muestra).
  - Precedencia absoluta de la **Flor** sobre el Envido y cálculo con piezas (30, 29, 28, 27).
  - Resolución completa de empates (**pardas**) y señas faciales digitales para equipos.

---

## 📋 Documentación de Referencia

- [Especificación Completa de Requerimientos (SRS v0.2.0)](REQUERIMIENTOS_TRUCO_URUGUAYO.txt)
- [Documento de Arquitectura y Contratos de Eventos](docs/ARQUITECTURA.md)
