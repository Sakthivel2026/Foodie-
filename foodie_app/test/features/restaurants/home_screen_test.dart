import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/widgets/empty_view.dart';
import 'package:foodie_app/core/widgets/error_view.dart';
import 'package:foodie_app/core/widgets/loading_indicator.dart';
import 'package:foodie_app/features/restaurants/domain/entities/menu_item.dart';
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

    testWidgets('does not render toggle chips for food items or restaurants', (tester) async {
      final state = RestaurantListState.initial().copyWith(
        isLoading: false,
        foodItems: [],
      );

      await tester.pumpWidget(buildTestableWidget(state));

      expect(find.textContaining('Food Items ('), findsNothing);
      expect(find.textContaining('Restaurants ('), findsNothing);
    });

    testWidgets('renders EmptyView when food items list is empty', (tester) async {
      final emptyState = RestaurantListState.initial().copyWith(
        isLoading: false,
        isFoodView: true,
        foodItems: [],
      );

      await tester.pumpWidget(buildTestableWidget(emptyState));

      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text('No food items found'), findsOneWidget);
    });

    testWidgets('renders FoodCard when isFoodView is true with items', (tester) async {
      final foodState = RestaurantListState.initial().copyWith(
        isLoading: false,
        isFoodView: true,
        foodItems: [
          MenuItem(
            id: 'item-1',
            restaurantId: 'rest-1',
            name: 'Margherita Pizza',
            description: 'Classic pizza',
            pricePaise: 34900,
            imageUrl: 'https://example.com/pizza.jpg',
            isVeg: true,
            category: 'Italian',
            isAvailable: true,
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(foodState));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Margherita Pizza'), findsOneWidget);
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
