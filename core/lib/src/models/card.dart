import 'suit.dart';

/// Representación inmutable de una carta de la baraja española de 40 cartas.
class TrucoCard {
  final int number;
  final Suit suit;

  const TrucoCard(this.number, this.suit)
      : assert(
          number >= 1 && number <= 12 && number != 8 && number != 9,
          'El número de carta debe estar entre 1 y 12 (excluyendo 8 y 9)',
        );

  /// Valor facial base para el cómputo de envido o flor tradicional sin piezas.
  /// Las cartas del 1 al 7 valen su número; las figuras (10, 11, 12) valen 0.
  int get envidoFaceValue {
    if (number >= 10 && number <= 12) {
      return 0;
    }
    return number;
  }

  /// Retorna si es una figura (10=Sota, 11=Caballo, 12=Rey).
  bool get isFigure => number >= 10 && number <= 12;

  /// Identificador estable usado en el protocolo de red, p. ej. `espada_2`.
  String get id => '${suit.name}_$number';

  /// Reconstruye una carta desde su [id] (`espada_2`). Lanza [FormatException]
  /// si el texto no corresponde a una carta válida de la baraja de 40.
  static TrucoCard fromId(String id) {
    final parts = id.split('_');
    if (parts.length != 2) throw FormatException('Id de carta inválido: $id');
    final suit = Suit.values.where((s) => s.name == parts[0]).firstOrNull;
    final number = int.tryParse(parts[1]);
    if (suit == null ||
        number == null ||
        number < 1 ||
        number > 12 ||
        number == 8 ||
        number == 9) {
      throw FormatException('Id de carta inválido: $id');
    }
    return TrucoCard(number, suit);
  }

  Map<String, dynamic> toJson() => {'id': id, 'number': number, 'suit': suit.name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrucoCard &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          suit == other.suit;

  @override
  int get hashCode => number.hashCode ^ suit.hashCode;

  @override
  String toString() => '$number de ${suit.displayName}';
}
