import 'package:flutter_test/flutter_test.dart';
import 'package:app_notas/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('App de Notas'), findsOneWidget);
  });
}