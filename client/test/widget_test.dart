import 'package:flutter_test/flutter_test.dart';
import 'package:truco_client/main.dart';

void main() {
  testWidgets('TrucoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrucoApp());
    expect(find.text('Truco Uruguayo (1v1 vs Bot)'), findsOneWidget);
  });
}
