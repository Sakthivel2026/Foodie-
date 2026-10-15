import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/core/storage/storage_service.dart';
import 'package:foodie_app/features/orders/domain/entities/order_entity.dart';
import 'package:foodie_app/features/orders/domain/repositories/order_repository.dart';
import 'package:foodie_app/features/orders/presentation/providers/order_provider.dart';
import 'package:foodie_app/features/orders/presentation/providers/tracking_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOrderRepository extends Mock implements OrderRepository {}
class MockStorageService extends Mock implements StorageService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockOrderRepository mockOrderRepo;
  late MockStorageService mockStorage;
  late SharedPreferences prefs;

  final sampleOrder = OrderEntity(
    id: 'order-999',
    userId: 'user-1',
    restaurantId: 'rest-1',
    addressId: 'addr-1',
    status: 'PLACED',
    paymentStatus: 'PAID',
    subtotalPaise: 20000,
    deliveryFeePaise: 3000,
    taxPaise: 1000,
    totalPaise: 24000,
    items: [],
    createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
  );

  setUp(() async {
    mockOrderRepo = MockOrderRepository();
    mockStorage = MockStorageService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    when(() => mockOrderRepo.getOrderById('order-999')).thenAnswer((_) async => sampleOrder);
    when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'mock_token');
  });

  test('TrackingNotifier fetches initial order successfully', () async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        storageServiceProvider.overrideWithValue(mockStorage),
      ],
    );

    final trackingNotifier = container.read(trackingNotifierProvider('order-999').notifier);
    await trackingNotifier.fetchInitialOrder();

    final state = container.read(trackingNotifierProvider('order-999'));

    expect(state.isLoading, isFalse);
    expect(state.order?.id, 'order-999');
    expect(state.status, 'PLACED');
  });
}
