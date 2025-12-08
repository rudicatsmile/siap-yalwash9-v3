import 'package:flutter_test/flutter_test.dart';
import 'package:siap/main.dart';

void main() {
  setUpAll(() async {
    // Initialize services before tests
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const SiapApp());

    // Verify splash screen appears
    expect(find.text('SIAP'), findsOneWidget);
    
    // Let async operations complete
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
