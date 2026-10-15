import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodie_app/app/app.dart';
import 'package:foodie_app/core/storage/storage_service.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const FoodieApp(),
      ),
    );

    // Verify splash screen branding
    expect(find.text('Foodie'), findsOneWidget);
    expect(find.text('Delicious food, delivered fast'), findsOneWidget);

    // Advance timer past splash delay
    await tester.pump(const Duration(seconds: 3));
  });
}
