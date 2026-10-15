import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_item.dart';
import 'package:foodie_app/features/cart/domain/entities/cart_state.dart';
import 'package:foodie_app/features/restaurants/domain/entities/menu_item.dart';
import 'package:foodie_app/features/restaurants/domain/entities/restaurant.dart';

void main() {
  group('Cart Unit Tests', () {
    final restaurantA = Restaurant(
      id: 'rest-a',
      name: 'Spice Garden',
      cuisine: 'Indian',
      imageUrl: 'http://example.com/rest-a.jpg',
      rating: 4.5,
      deliveryTimeMin: 30,
      deliveryFeePaise: 3000, // ₹30.00
      lat: 12.971598,
      lng: 77.594562,
      isOpen: true,
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final item1 = MenuItem(
      id: 'item-1',
      restaurantId: 'rest-a',
      name: 'Butter Chicken',
      description: 'Rich curry',
      pricePaise: 35000, // ₹350.00
      imageUrl: 'http://example.com/item1.jpg',
      isVeg: false,
      category: 'Main Course',
      isAvailable: true,
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    final item2 = MenuItem(
      id: 'item-2',
      restaurantId: 'rest-a',
      name: 'Naan',
      description: 'Garlic naan',
      pricePaise: 5000, // ₹50.00
      imageUrl: 'http://example.com/item2.jpg',
      isVeg: true,
      category: 'Breads',
      isAvailable: true,
      createdAt: DateTime.parse('2026-10-04T00:00:00.000Z'),
    );

    test('Cart totals math matches backend formula strictly', () {
      // Subtotal = (35000 * 2) + (5000 * 3) = 70000 + 15000 = 85000 paise (₹850.00)
      // Delivery fee = 3000 paise (₹30.00)
      // Tax = Math.round(85000 * 0.05) = 4250 paise (₹42.50)
      // Total = 85000 + 3000 + 4250 = 92250 paise (₹922.50)

      final state = CartState(
        restaurant: restaurantA,
        items: [
          CartItem(menuItem: item1, quantity: 2),
          CartItem(menuItem: item2, quantity: 3),
        ],
      );

      expect(state.itemCount, 5);
      expect(state.subtotalPaise, 85000);
      expect(state.deliveryFeePaise, 3000);
      expect(state.taxPaise, 4250);
      expect(state.totalPaise, 92250);
    });

    test('Cart persistence round trip serialization', () {
      final state = CartState(
        restaurant: restaurantA,
        items: [
          CartItem(menuItem: item1, quantity: 2),
        ],
      );

      final encoded = state.encode();
      final decoded = CartState.decode(encoded);

      expect(decoded.restaurant?.id, restaurantA.id);
      expect(decoded.items.length, 1);
      expect(decoded.items.first.menuItem.name, 'Butter Chicken');
      expect(decoded.items.first.quantity, 2);
      expect(decoded.totalPaise, state.totalPaise);
    });
  });
}
