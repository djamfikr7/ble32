import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ble_scale/main.dart';

void main() {
  testWidgets('App builds and shows navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BLEScaleApp(),
      ),
    );

    // Verify that the app builds successfully
    expect(find.text('Smart Scale'), findsOneWidget);
  });
}
