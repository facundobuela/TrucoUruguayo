import 'card.dart';
import 'suit.dart';

/// Define el rol o jerarquía que asume una carta en relación con la Muestra.
enum CardRole {
  piezaDos(30, 100),
  piezaCuatro(29, 90),
  piezaCinco(28, 80),
  piezaPerico(27, 70), // Caballo (11) o su sustituto Rey
  piezaPerica(27, 60), // Sota (10) o su sustituto Rey
  macho(0, 50),        // 1 de Espada
  hembra(0, 45),       // 1 de Basto
  sieteEspada(0, 40),  // 7 de Espada
  sieteOro(0, 35),     // 7 de Oro
  tresComun(0, 30),
  dosComun(0, 25),
  unoComun(0, 20),     // 1 de Copa / 1 de Oro
  reyComun(0, 15),     // 12 común
  caballoComun(0, 10), // 11 común
  sotaComun(0, 8),     // 10 común
  sieteComun(0, 6),    // 7 de Copa / 7 de Basto
  seisComun(0, 5),
  cincoComun(0, 4),
  cuatroComun(0, 3);

  final int envidoScore;
  final int trickPower; // Jerarquía en las rondas (mayor número gana la ronda)

  const CardRole(this.envidoScore, this.trickPower);

  bool get isPiece =>
      this == CardRole.piezaDos ||
      this == CardRole.piezaCuatro ||
      this == CardRole.piezaCinco ||
      this == CardRole.piezaPerico ||
      this == CardRole.piezaPerica;
}

/// Representa la Muestra de la mano y administra la regla de la Carta Sustituta (Rey 12).
class Sample {
  final TrucoCard card;

  const Sample(this.card);

  Suit get suit => card.suit;

  Map<String, dynamic> toJson() => card.toJson();

  factory Sample.fromId(String id) => Sample(TrucoCard.fromId(id));

  /// Retorna si la muestra descubierta es una de las 5 piezas estándar.
  bool get sampleIsPiece =>
      card.number == 2 ||
      card.number == 4 ||
      card.number == 5 ||
      card.number == 11 ||
      card.number == 10;

  /// Si la muestra es una pieza, el número de dicha pieza que será sustituida por el Rey 12.
  int? get replacedPieceNumber => sampleIsPiece ? card.number : null;

  /// Clasifica una carta según la muestra activa y las reglas del Truco Uruguayo.
  CardRole classify(TrucoCard c) {
    final isSameSuit = c.suit == suit;

    // Regla de Carta Sustituta: Si la muestra es una de las piezas, el 12 (Rey)
    // del mismo palo toma el lugar exacto de esa pieza.
    if (sampleIsPiece && isSameSuit && c.number == 12) {
      return _pieceRoleForNumber(card.number);
    }

    // Piezas estándar del palo de la muestra
    if (isSameSuit) {
      // Si esta carta es la que fue sustituida por salir de muestra,
      // no existe otra igual en el mazo porque la muestra está visible en la mesa.
      switch (c.number) {
        case 2:
          return CardRole.piezaDos;
        case 4:
          return CardRole.piezaCuatro;
        case 5:
          return CardRole.piezaCinco;
        case 11:
          return CardRole.piezaPerico;
        case 10:
          return CardRole.piezaPerica;
      }
    }

    // Matas comunes (independientes del palo de la muestra)
    if (c.number == 1 && c.suit == Suit.espada) return CardRole.macho;
    if (c.number == 1 && c.suit == Suit.basto) return CardRole.hembra;
    if (c.number == 7 && c.suit == Suit.espada) return CardRole.sieteEspada;
    if (c.number == 7 && c.suit == Suit.oro) return CardRole.sieteOro;

    // Resto de la baraja
    switch (c.number) {
      case 3:
        return CardRole.tresComun;
      case 2:
        return CardRole.dosComun;
      case 1:
        return CardRole.unoComun;
      case 12:
        return CardRole.reyComun;
      case 11:
        return CardRole.caballoComun;
      case 10:
        return CardRole.sotaComun;
      case 7:
        return CardRole.sieteComun;
      case 6:
        return CardRole.seisComun;
      case 5:
        return CardRole.cincoComun;
      case 4:
        return CardRole.cuatroComun;
      default:
        throw ArgumentError('Carta inválida: $c');
    }
  }

  CardRole _pieceRoleForNumber(int number) {
    switch (number) {
      case 2:
        return CardRole.piezaDos;
      case 4:
        return CardRole.piezaCuatro;
      case 5:
        return CardRole.piezaCinco;
      case 11:
        return CardRole.piezaPerico;
      case 10:
        return CardRole.piezaPerica;
      default:
        throw StateError('El número $number no es una pieza sustituible');
    }
  }
}
