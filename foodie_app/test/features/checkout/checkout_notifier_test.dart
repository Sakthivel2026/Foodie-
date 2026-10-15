import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodie_app/core/storage/storage_service.dart';
import 'package:foodie_app/core/network/payment_gateway.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_item.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_state.dart';
import 'package:foodie_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:foodie_app/features/checkout/presentation/providers/checkout_provider.dart';
import 'package:foodie_app/features/orders/domain/entities/order_entity.dart';
import 'package:foodie_app/features/orders/domain/repositories/order_repository.dart';
import 'package:foodie_app/features/restaurants/domain/entities/menu_item.dart';
import 'package:foodie_app/features/restaurants/domain/entities/restaurant.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderRepository extends Mock implements OrderRepository {}
class MockPaymentGateway extends Mock implements PaymentGateway {}
class FakePaymentDetails extends Fake implements PaymentDetails {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakePaymentDetails());
  });

  late MockOrderRepository mockOrderRepo;
  late MockPaymentGateway mockPaymentGateway;
  late SharedPreferences prefs;

  final sampleRestaurant = Restaurant(
    id: 'rest-1',
    name: 'Test Rest',
    cuisine: 'Indian',
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
    name: 'Dosa',
    description: 'Crispy Dosa',
    pricePaise: 10000,
    imageUrl: 'http://example.com/dosa.jpg',
    isVeg: true,
    category: 'Breakfast',
    isAvailable: true,
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  final sampleOrder = OrderEntity(
    id: 'order-123',
    userId: 'user-1',
    restaurantId: 'rest-1',
    addressId: 'addr-1',
    status: 'PENDING_PAYMENT',
    paymentStatus: 'PENDING',
    subtotalPaise: 10000,
    deliveryFeePaise: 2500,
    taxPaise: 500,
    totalPaise: 13000,
    items: [],
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  final sampleVerifiedOrder = OrderEntity(
    id: 'order-123',
    userId: 'user-1',
    restaurantId: 'rest-1',
    addressId: 'addr-1',
    status: 'PLACED',
    paymentStatus: 'PAID',
    subtotalPaise: 10000,
    deliveryFeePaise: 2500,
    taxPaise: 500,
    totalPaise: 13000,
    items: [],
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  setUp(() async {
    mockOrderRepo = MockOrderRepository();
    mockPaymentGateway = MockPaymentGateway();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer makeContainer({CartState? initialCart}) {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        paymentGatewayProvider.overrideWithValue(mockPaymentGateway),
      ],
    );

    if (initialCart != null) {
      container.read(cartNotifierProvider.notifier).state = initialCart;
    }

    return container;
  }

  test('Checkout success flow clears cart and sets verified order', () async {
    final cartState = CartState(
      restaurant: sampleRestaurant,
      items: [CartItem(menuItem: sampleMenuItem, quantity: 1)],
    );

    final container = makeContainer(initialCart: cartState);

    when(() => mockOrderRepo.createOrder(
          restaurantId: any(named: 'restaurantId'),
          addressId: any(named: 'addressId'),
          items: any(named: 'items'),
        )).thenAnswer((_) async => sampleOrder);

    when(() => mockOrderRepo.createPayment('order-123')).thenAnswer((_) async => {
          'razorpayOrderId': 'order_mock_123',
          'amountPaise': 13000,
          'currency': 'INR',
          'keyId': 'mock_key',
        });

    when(() => mockPaymentGateway.processPayment(any())).thenAnswer(
      (_) async => const PaymentResult.success(
        razorpayOrderId: 'order_mock_123',
        razorpayPaymentId: 'pay_mock_123',
        razorpaySignature: 'mock_signature',
      ),
    );

    when(() => mockOrderRepo.verifyPayment(
          orderId: 'order-123',
          razorpayOrderId: 'order_mock_123',
          razorpayPaymentId: 'pay_mock_123',
          razorpaySignature: 'mock_signature',
        )).thenAnswer((_) async => sampleVerifiedOrder);

    final checkoutNotifier = container.read(checkoutNotifierProvider.notifier);

    await checkoutNotifier.placeOrderAndPay(addressId: 'addr-1');

    final finalState = container.read(checkoutNotifierProvider);
    final finalCartState = container.read(cartNotifierProvider);

    expect(finalState.status, CheckoutStatus.success);
    expect(finalState.verifiedOrder?.status, 'PLACED');
    expect(finalCartState.isEmpty, isTrue);
  });

  test('Checkout failed payment preserves cart and sets paymentFailed state', () async {
    final cartState = CartState(
      restaurant: sampleRestaurant,
      items: [CartItem(menuItem: sampleMenuItem, quantity: 1)],
    );

    final container = makeContainer(initialCart: cartState);

    when(() => mockOrderRepo.createOrder(
          restaurantId: any(named: 'restaurantId'),
          addressId: any(named: 'addressId'),
          items: any(named: 'items'),
        )).thenAnswer((_) async => sampleOrder);

    when(() => mockOrderRepo.createPayment('order-123')).thenAnswer((_) async => {
          'razorpayOrderId': 'order_mock_123',
          'amountPaise': 13000,
          'currency': 'INR',
          'keyId': 'mock_key',
        });

    when(() => mockPaymentGateway.processPayment(any())).thenAnswer(
      (_) async => const PaymentResult.failure(errorMessage: 'Payment cancelled'),
    );

    final checkoutNotifier = container.read(checkoutNotifierProvider.notifier);

    await checkoutNotifier.placeOrderAndPay(addressId: 'addr-1');

    final finalState = container.read(checkoutNotifierProvider);
    final finalCartState = container.read(cartNotifierProvider);

    expect(finalState.status, CheckoutStatus.paymentFailed);
    expect(finalState.errorMessage, 'Payment cancelled');
    expect(finalCartState.isEmpty, isFalse);
  });
}
