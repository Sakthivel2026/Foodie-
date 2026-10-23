import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:foodie_app/core/storage/storage_service.dart';
import 'package:foodie_app/features/addresses/domain/entities/address.dart';
import 'package:foodie_app/features/addresses/presentation/providers/address_provider.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_item.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_state.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:foodie_app/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:foodie_app/features/restaurants/domain/entities/menu_item.dart';
import 'package:foodie_app/features/restaurants/domain/entities/restaurant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAddressListNotifier extends AddressListNotifier {
  final AddressListState _stubState;
  MockAddressListNotifier(this._stubState);

  @override
  AddressListState build() => _stubState;

  @override
  Future<void> loadAddresses() async {}
}

class TestCartNotifier extends CartNotifier {
  final CartState _stubState;
  TestCartNotifier(this._stubState);

  @override
  CartState build() => _stubState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  final sampleRestaurant = Restaurant(
    id: 'rest-1',
    name: 'Meghana Foods',
    cuisine: 'Biryani',
    imageUrl: 'http://example.com/img.jpg',
    rating: 4.5,
    deliveryTimeMin: 30,
    deliveryFeePaise: 2500,
    lat: 12.9716,
    lng: 77.5946,
    isOpen: true,
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  final sampleMenuItem = MenuItem(
    id: 'item-1',
    restaurantId: 'rest-1',
    name: 'Biryani',
    description: 'Hot Biryani',
    pricePaise: 20000,
    imageUrl: 'http://example.com/b.jpg',
    isVeg: false,
    category: 'Biryani',
    isAvailable: true,
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  final sampleAddress = Address(
    id: 'addr-1',
    userId: 'user-1',
    label: 'Home',
    line1: '123 Koramangala',
    line2: '4th Block',
    city: 'Bengaluru',
    pincode: '560034',
    lat: 12.9345,
    lng: 77.6242,
    isDefault: true,
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidgetUnderTest(AddressListState addressState) {
    final cartState = CartState(
      restaurant: sampleRestaurant,
      items: [CartItem(menuItem: sampleMenuItem, quantity: 1)],
    );

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/tracking/:id',
          builder: (context, state) => const Scaffold(body: Text('Tracking')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        cartNotifierProvider.overrideWith(() => TestCartNotifier(cartState)),
        addressListNotifierProvider.overrideWith(
          () => MockAddressListNotifier(addressState),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('CheckoutScreen displays empty address view and disables Place Order when no address exists',
      (tester) async {
    const emptyState = AddressListState(
      addresses: [],
      isLoading: false,
      errorMessage: null,
    );

    await tester.pumpWidget(createWidgetUnderTest(emptyState));
    await tester.pumpAndSettle();

    expect(find.text('No saved delivery addresses found.'), findsOneWidget);
    expect(find.text('Add Delivery Address'), findsOneWidget);
    expect(find.text('Select Delivery Address to Place Order'), findsOneWidget);

    final placeOrderBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Select Delivery Address to Place Order'),
    );
    expect(placeOrderBtn.onPressed, isNull);
  });

  testWidgets('CheckoutScreen preselects default address and enables Place Order',
      (tester) async {
    final populatedState = AddressListState(
      addresses: [sampleAddress],
      isLoading: false,
      errorMessage: null,
    );

    await tester.pumpWidget(createWidgetUnderTest(populatedState));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('123 Koramangala'), findsOneWidget);
    expect(find.text('Bengaluru - 560034'), findsOneWidget);

    // Place Order button should be enabled with price
    final placeOrderFinder = find.widgetWithText(ElevatedButton, 'Place Order - ₹235.00');
    expect(placeOrderFinder, findsOneWidget);

    final placeOrderBtn = tester.widget<ElevatedButton>(placeOrderFinder);
    expect(placeOrderBtn.onPressed, isNotNull);
  });

  testWidgets('CheckoutScreen displays error view when address loading fails',
      (tester) async {
    const errorState = AddressListState(
      addresses: [],
      isLoading: false,
      errorMessage: 'Network connection failed',
    );

    await tester.pumpWidget(createWidgetUnderTest(errorState));
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load saved addresses: Network connection failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Add Address'), findsOneWidget);
  });
}
