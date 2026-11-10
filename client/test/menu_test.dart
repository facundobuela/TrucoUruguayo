import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/app.dart';
import 'package:truco_client/features/game/controller/game_controller.dart';
import 'package:truco_client/features/game/controller/offline_game_controller.dart';
import 'package:truco_client/features/game/presentation/game_screen.dart';
import 'package:truco_client/features/modes/game_mode.dart';
import 'package:truco_client/features/modes/game_session_factory.dart';
import 'package:truco_client/features/ranked/ranked_service.dart';

/// Servicio clasificatorio de mentira que "ya funciona": prueba que la
/// estructura deja enchufar una implementación real sin tocar la pantalla.
class _ReadyRankedService implements RankedService {
  @override
  RankedAvailability get availability => RankedAvailability.ready;

  @override
  Future<RankedProfile?> loadProfile() async =>
      const RankedProfile(rating: 1234, gamesPlayed: 10, wins: 7, losses: 3);

  @override
  Future<GameController> findMatch(GameMode mode) async =>
      OfflineGameController();
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group('Menú principal', () {
    testWidgets('muestra el título y los botones Jugar y Partidas Elo', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());

      expect(find.text('TRUCO URUGUAYO'), findsOneWidget);
      expect(find.text('Jugar'), findsOneWidget);
      expect(find.text('Partidas Elo'), findsOneWidget);
      expect(find.text('Próximamente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final size in const [
      Size(360, 640),
      Size(390, 844),
      Size(440, 956),
      Size(800, 600),
    ]) {
      testWidgets(
        'sin overflow en ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          _setSize(tester, size);
          await tester.pumpWidget(const TrucoApp());
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Jugar', () {
    testWidgets('lista los tres modos; dos están como Próximamente', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();

      expect(find.text('1 vs 1 contra el Bot'), findsOneWidget);
      expect(find.text('1 vs 1 contra jugador'), findsOneWidget);
      expect(find.text('2 vs 2'), findsOneWidget);
      expect(find.text('Próximamente'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin overflow en 360x640', (WidgetTester tester) async {
      _setSize(tester, const Size(360, 640));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('un modo próximamente no abre la partida: avisa', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2 vs 2'));
      await tester.pump();

      expect(find.byType(GameScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('próximamente'), findsOneWidget);
    });

    testWidgets('1 vs 1 contra el Bot abre la partida con su título', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1 vs 1 contra el Bot'));
      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('1 vs 1 contra el Bot'), findsOneWidget); // AppBar
      expect(tester.takeException(), isNull);
    });

    testWidgets('el botón atrás pide confirmación y vuelve a los modos', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Jugar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 vs 1 contra el Bot'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('¿Abandonar la partida?'), findsOneWidget);

      // "Seguir jugando" se queda en la partida.
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // "Abandonar" vuelve a la lista de modos.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonar'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Elegí cómo querés jugar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Partidas Elo', () {
    testWidgets('sin servidor: Elo vacío, modos clasificatorios y reglas', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Partidas Elo'));
      await tester.pumpAndSettle();

      expect(find.text('Tu Elo'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(
        find.text('Las partidas clasificatorias estarán disponibles pronto.'),
        findsOneWidget,
      );
      expect(find.text('Clasificatoria 1 vs 1'), findsOneWidget);
      expect(find.text('Clasificatoria 2 vs 2'), findsOneWidget);
      expect(
        find.text('Las partidas contra el Bot no suman Elo.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Clasificatoria 1 vs 1'));
      await tester.pump();
      expect(find.byType(GameScreen), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin overflow en 360x640', (WidgetTester tester) async {
      _setSize(tester, const Size(360, 640));
      await tester.pumpWidget(const TrucoApp());
      await tester.tap(find.text('Partidas Elo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('con un servicio listo muestra el perfil y abre la mesa', (
      WidgetTester tester,
    ) async {
      _setSize(tester, const Size(440, 956));
      await tester.pumpWidget(TrucoApp(rankedService: _ReadyRankedService()));
      await tester.tap(find.text('Partidas Elo'));
      await tester.pumpAndSettle();

      expect(find.text('1234'), findsOneWidget);
      expect(find.textContaining('10 partidas'), findsOneWidget);

      await tester.tap(find.text('Clasificatoria 1 vs 1'));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
