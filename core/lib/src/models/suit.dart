/// Palos de la baraja española tradicional de 40 cartas.
enum Suit {
  espada,
  basto,
  oro,
  copa;

  String get displayName {
    switch (this) {
      case Suit.espada:
        return 'Espada';
      case Suit.basto:
        return 'Basto';
      case Suit.oro:
        return 'Oro';
      case Suit.copa:
        return 'Copa';
    }
  }
}
