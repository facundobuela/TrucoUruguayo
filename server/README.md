# Servidor Autoritativo de Juego - Truco Uruguayo

Backend en tiempo real para la gestión de salas, emparejamiento (matchmaking) y arbitraje autoritativo de partidas de Truco Uruguayo.

## Estructura del Servidor
```
server/
├── src/
│   ├── api/          # Endpoints REST (Auth, perfiles, auditoría de partidas)
│   ├── ws/           # Servidor WebSocket y manejador de eventos de mesa
│   ├── rooms/        # Gestión de mesas (1v1, 2v2, 3v3, privadas)
│   ├── matchmaking/  # Cola de emparejamiento por ELO y fallback a bots
│   └── persistence/  # Adaptadores para Redis (memoria) y PostgreSQL
├── docker/
│   ├── docker-compose.yml # PostgreSQL + Redis para desarrollo local
│   └── Dockerfile
└── README.md
```

## Principio Autoritativo (Zero-Trust)
- El servidor ejecuta `truco_core` para validar cada tirada de carta y cada canto.
- La baraja se genera con `CSPRNG` y sólo se despachan a cada cliente sus propias 3 cartas.
- Persistencia rápida en Redis para restaurar estados en la ventana de reconexión de 45 segundos.
