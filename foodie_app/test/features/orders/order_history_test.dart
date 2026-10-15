import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/orders/domain/entities/order_entity.dart';

void main() {
  group('Order History & Logic Unit Tests', () {
    final pendingOrder = OrderEntity(
      id: 'order-1',
      userId: 'user-1',
      restaurantId: 'rest-1',
      addressId: 'addr-1',
      status: 'PENDING_PAYMENT',
      paymentStatus: 'PENDING',
      subtotalPaise: 10000,
      deliveryFeePaise: 2000,
      taxPaise: 500,
      totalPaise: 12500,
      items: [],
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final placedOrder = OrderEntity(
      id: 'order-2',
      userId: 'user-1',
      restaurantId: 'rest-1',
      addressId: 'addr-1',
      status: 'PLACED',
      paymentStatus: 'PAID',
      subtotalPaise: 10000,
      deliveryFeePaise: 2000,
      taxPaise: 500,
      totalPaise: 12500,
      items: [],
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final preparingOrder = OrderEntity(
      id: 'order-3',
      userId: 'user-1',
      restaurantId: 'rest-1',
      addressId: 'addr-1',
      status: 'PREPARING',
      paymentStatus: 'PAID',
      subtotalPaise: 10000,
      deliveryFeePaise: 2000,
      taxPaise: 500,
      totalPaise: 12500,
      items: [],
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final deliveredOrder = OrderEntity(
      id: 'order-4',
      userId: 'user-1',
      restaurantId: 'rest-1',
      addressId: 'addr-1',
      status: 'DELIVERED',
      paymentStatus: 'PAID',
      subtotalPaise: 10000,
      deliveryFeePaise: 2000,
      taxPaise: 500,
      totalPaise: 12500,
      items: [],
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    test('Cancel-allowed rule strictly permits only PENDING_PAYMENT and PLACED', () {
      bool canCancel(OrderEntity o) => o.status == 'PENDING_PAYMENT' || o.status == 'PLACED';

      expect(canCancel(pendingOrder), isTrue);
      expect(canCancel(placedOrder), isTrue);
      expect(canCancel(preparingOrder), isFalse);
      expect(canCancel(deliveredOrder), isFalse);
    });
  });
}
