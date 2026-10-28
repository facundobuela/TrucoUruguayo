# Especificación de Tareas de UI / Frontend
## Proyecto: Truco Uruguayo Móvil (Client)
**Fecha:** 28 de Octubre de 2026  
**Referencia:** Feedback visual sobre simulación iPhone 16 (393 × 852 px) y estilo de naipes.

---

## 📌 TAREA-UI-01: Rediseño Responsivo de la Botonera de Acciones (Fix de Visibilidad de Truco y Mazo)

### Problema Detectado
En pantallas de smartphones estándar (ej. iPhone 16 con ancho de 393 px), la barra de acciones utilizaba un contenedor horizontal lineal de una sola fila. Cuando coexistían opciones de envite (*Envido*, *Real Envido*, *Falta Envido*) y de mano (*Truco*, *Irse al Mazo*), los botones de la derecha quedaban cortados y ocultos fuera de la pantalla sin redimensionarse automáticamente.

### Criterios de Aceptación
1. **Visibilidad Total sin Desborde (Zero Overflow)**:
   - Ningún botón legal debe quedar oculto ni requerir scroll horizontal ciego.
   - La botonera debe adaptarse dinámicamente a anchos de pantalla desde 360 px (Android compactos) hasta 430 px (iPhone Pro Max / Plus).
2. **Jerarquía Visual y Organización por Grupos**:
   - **Modo Respuesta (cuando el rival canta)**:
     - Botones grandes y contrastantes: `QUIERO` (verde) y `NO QUIERO` (rojo).
     - Si es posible revirar (ej. subir a *Retruco* o *Real Envido*), se muestran contiguos como opción de contraataque.
   - **Modo Iniciativa (turno propio)**:
     - Grupo 1 (Envite / Flor): Botones de *Envido*, *Real Envido*, *Falta Envido*, *Flor* en tonos azules/violetas.
     - Grupo 2 (Truco): Botón de *Truco* destacado en color ámbar/dorado con mayor peso visual.
     - Grupo 3 (Mazo): Botón de *Irse al Mazo* visible pero diferenciado con estilo Outline en rojo para evitar toques accidentales.
3. **Distribución Adaptativa (Wrap / Multi-Row)**:
   - Uso de `Wrap` o disposición en dos filas compactas con espaciado consistente (`runSpacing: 6`, `spacing: 6`) y padding ergonómico táctil (mínimo 44 px de altura de toque conforme a las directrices de Apple y Material Design).

---

## 📌 TAREA-UI-02: Integración de la Baraja Española Tradicional (Estilo Fournier 40 Cartas)

### Problema Detectado
Actualmente las cartas se representan mediante un diseño vectorial genérico esquemático (número + icono de color). Se requiere la estética visual folclórica y auténtica de la **baraja española clásica de 40 cartas** (estilo tradicional de figuras grabadas e ilustraciones detalladas).

### Requisitos Visuales del Mazo (según referencia gráfica adjunta):
1. **Ilustraciones Auténticas por Palo**:
   - **Espadas**: Espada flamígera curva con lazo ornamental multicolor en el As de Espada (Macho), espadas rectas de hoja azulada y guarda dorada en el resto.
   - **Bastos**: Garrotes nudosos de madera verde con detalles rojos y amarillos (As de Basto / Hembra y bastos cruzados ornamentados).
   - **Oros**: Monedas doradas con el perfil clásico en relieve circular (medallón del As de Oro) y cinta decorativa.
   - **Copas**: Cáliz dorado ornamentado con tapa roja/turquesa y detalles grabados.
   - **Figuras**: Sota (10), Caballo (11) y Rey (12) con vestimentas y armaduras tradicionales.
2. **Reverso de Carta (Dorso Tradicional)**:
   - Patrón clásico de trama geométrica en tonos rojos o azules para las cartas del rival y el mazo cubierto.
3. **Optimización de Assets**:
   - Formatos admitidos: SVG vectoriales nítidos para cualquier resolución O imágenes WebP/PNG optimizadas a 2x y 3x.
   - Directorio de assets: `client/assets/cards/` con nomenclatura estandarizada: `<numero>_<palo>.png` (ej. `1_espada.png`, `2_basto.png`, `dorso.png`).
   - Declaración oficial en `pubspec.yaml` bajo la clave `flutter: assets:`.
4. **Relación de Aspecto y Escalado**:
   - Las cartas deben mantener la proporción áurea tradicional de naipes (relación aproximada de $1 : 1.55$ o $62 \times 95\text{ mm}$), garantizando legibilidad en la Muestra (arriba), cartas tiradas en la mesa (centro) y mano del jugador (abajo).
