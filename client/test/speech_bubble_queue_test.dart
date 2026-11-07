import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/features/game/controller/speech_bubbles.dart';
import 'package:truco_core/truco_core.dart';

void main() {
  testWidgets('los globos se muestran de a uno y en orden', (WidgetTester tester) async {
    var changes = 0;
    final q = SpeechBubbleQueue(onChanged: () => changes++);

    q.say(Seat.b, '¡Truco!');
    q.say(Seat.a, '¡Quiero!');
    expect(q.active?.text, '¡Truco!');
    expect(q.active?.seat, Seat.b);
    expect(q.busy, isTrue);

    // El primero dura 1300 ms y luego hay una pausa de 150 ms.
    await tester.pump(const Duration(milliseconds: 1400));
    expect(q.active, isNull);
    expect(q.busy, isTrue, reason: 'queda uno en espera');

    await tester.pump(const Duration(milliseconds: 200));
    expect(q.active?.text, '¡Quiero!');
    expect(q.active?.seat, Seat.a);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(q.active, isNull);
    expect(q.busy, isFalse);
    expect(changes >= 4, isTrue);
    q.dispose();
  });

  testWidgets('los textos largos duran más que los cortos', (WidgetTester tester) async {
    final q = SpeechBubbleQueue(onChanged: () {});
    q.say(Seat.b, '¡Falta envido!');
    final shortMs = q.active!.durationMs;
    q.clear();
    q.say(Seat.b, 'Esto es un mensaje bastante largo para leer con calma');
    expect(q.active!.durationMs > shortMs, isTrue);
    q.dispose();
  });

  testWidgets('clear descarta el globo activo y los pendientes', (WidgetTester tester) async {
    final q = SpeechBubbleQueue(onChanged: () {});
    q.say(Seat.b, '¡Truco!');
    q.say(Seat.a, '¡Quiero!');
    q.clear();
    expect(q.active, isNull);
    expect(q.busy, isFalse);

    await tester.pump(const Duration(seconds: 5));
    expect(q.active, isNull, reason: 'no debe reaparecer nada tras clear');
    q.dispose();
  });

  testWidgets('el globo dura al menos lo que dura su voz', (
    WidgetTester tester,
  ) async {
    final q = SpeechBubbleQueue(onChanged: () {});
    q.say(Seat.b, 'Tengo 28', voice: 'tengo_28', minDurationMs: 2500);
    expect(q.active!.durationMs, 2500);
    expect(q.active!.voice, 'tengo_28');
    q.dispose();
  });

  testWidgets('onShow avisa cuando cada globo pasa a mostrarse, en orden', (
    WidgetTester tester,
  ) async {
    final shown = <String>[];
    final q = SpeechBubbleQueue(
      onChanged: () {},
      onShow: (m) => shown.add(m.voice ?? '-'),
    );
    q.say(Seat.a, '¡Truco!', voice: 'truco');
    q.say(Seat.b, '¡Quiero!', voice: 'quiero');
    expect(shown, ['truco']);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(shown, ['truco', 'quiero']);
    q.dispose();
  });
}
