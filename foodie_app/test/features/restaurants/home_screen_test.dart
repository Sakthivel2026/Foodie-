import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/widgets/empty_view.dart';
import 'package:foodie_app/core/widgets/error_view.dart';
import 'package:foodie_app/core/widgets/loading_indicator.dart';
import 'package:foodie_app/features/restaurants/presentation/providers/restaurant_provider.dart';
import 'package:foodie_app/features/restaurants/presentation/screens/home_screen.dart';

void main() {
  Widget buildTestableWidget(RestaurantListState initialState) {
    return ProviderScope(
      overrides: [
        restaurantListNotifierProvider.overrideWith(() {
          return TestRestaurantListNotifier(initialState);
        }),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('renders LoadingIndicator when loading', (tester) async {
      final loadingState = RestaurantListState.initial().copyWith(
        isLoading: true,
        restaurants: [],
      );

      await tester.pumpWidget(buildTestableWidget(loadingState));

      expect(find.byType(LoadingIndicator), findsOneWidget);
    });

    testWidgets('renders ErrorView on error', (tester) async {
      final errorState = RestaurantListState.initial().copyWith(
        isLoading: false,
        errorMessage: 'Network error occurred',
        restaurants: [],
      );

      await tester.pumpWidget(buildTestableWidget(errorState));

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Network error occurred'), findsOneWidget);
    });

    testWidgets('renders EmptyView when restaurants list is empty', (tester) async {
      final emptyState = RestaurantListState.initial().copyWith(
        isLoading: false,
        restaurants: [],
      );

      await tester.pumpWidget(buildTestableWidget(emptyState));

      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No restaurants found'), findsOneWidget);
    });
  });
}

class TestRestaurantListNotifier extends RestaurantListNotifier {
  final RestaurantListState initialState;

  TestRestaurantListNotifier(this.initialState);

  @override
  RestaurantListState build() {
    return initialState;
  }

  @override
  Future<void> loadRestaurants({bool refresh = false}) async {}

  @override
  Future<void> fetchNextPage() async {}
}
