import '../rules/round_resolver.dart';

/// Asiento / bando en la mesa. En 1 vs 1 cada bando es un único jugador.
enum Seat {
  a,
  b;

  Seat get other => this == Seat.a ? Seat.b : Seat.a;

  RoundWinner get asRoundWinner =>
      this == Seat.a ? RoundWinner.bandoA : RoundWinner.bandoB;

  HandWinner get asHandWinner =>
      this == Seat.a ? HandWinner.bandoA : HandWinner.bandoB;

  static Seat fromName(String name) =>
      Seat.values.firstWhere((s) => s.name == name,
          orElse: () => throw FormatException('Asiento inválido: $name'));
}
