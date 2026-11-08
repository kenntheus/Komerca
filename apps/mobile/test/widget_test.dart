import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komerca/main.dart';

void main() {
  testWidgets('App renders component gallery', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KomercaApp()),
    );
    await tester.pump();
    expect(find.text('Component Gallery'), findsOneWidget);
  });
}
