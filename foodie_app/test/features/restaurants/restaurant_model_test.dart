import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_app/features/restaurants/domain/entities/menu_item.dart';
import 'package:foodie_app/features/restaurants/domain/entities/restaurant.dart';
import 'package:foodie_app/features/restaurants/data/models/paginated_restaurants.dart';

void main() {
  group('Restaurant Model Tests', () {
    final sampleRestaurantJson = {
      'id': 'c39a7977-943f-42ae-a7be-e5e78ec6b510',
      'name': 'Spice Garden',
      'cuisine': 'Indian',
      'image_url': 'http://10.0.2.2:3000/images/spice_garden.jpg',
      'rating': 4.5,
      'delivery_time_min': 30,
      'delivery_fee_paise': 2500,
      'lat': 12.971598,
      'lng': 77.594562,
      'is_open': true,
      'created_at': '2026-10-04T00:00:00.000Z',
    };

    final sampleMenuItemJson = {
      'id': 'a1111111-1111-1111-1111-111111111111',
      'restaurant_id': 'c39a7977-943f-42ae-a7be-e5e78ec6b510',
      'name': 'Butter Chicken',
      'description': 'Rich creamy chicken curry',
      'price_paise': 35000,
      'image_url': 'http://10.0.2.2:3000/images/butter_chicken.jpg',
      'is_veg': false,
      'category': 'Main Course',
      'is_available': true,
      'created_at': '2026-10-04T00:00:00.000Z',
    };

    test('Restaurant.fromJson parses sample API response correctly', () {
      final restaurant = Restaurant.fromJson(sampleRestaurantJson);

      expect(restaurant.id, 'c39a7977-943f-42ae-a7be-e5e78ec6b510');
      expect(restaurant.name, 'Spice Garden');
      expect(restaurant.cuisine, 'Indian');
      expect(restaurant.rating, 4.5);
      expect(restaurant.deliveryTimeMin, 30);
      expect(restaurant.deliveryFeePaise, 2500);
      expect(restaurant.isOpen, isTrue);
    });

    test('MenuItem.fromJson parses sample API response correctly', () {
      final menuItem = MenuItem.fromJson(sampleMenuItemJson);

      expect(menuItem.id, 'a1111111-1111-1111-1111-111111111111');
      expect(menuItem.restaurantId, 'c39a7977-943f-42ae-a7be-e5e78ec6b510');
      expect(menuItem.name, 'Butter Chicken');
      expect(menuItem.pricePaise, 35000);
      expect(menuItem.isVeg, isFalse);
      expect(menuItem.isAvailable, isTrue);
    });

    test('MenuItem.fromJson parses joined cuisine & restaurant details correctly', () {
      final italianItemJson = {
        'id': 'b2222222-2222-2222-2222-222222222222',
        'restaurant_id': 'c39a7977-943f-42ae-a7be-e5e78ec6b510',
        'name': 'Margherita Pizza',
        'description': 'Classic mozzarella, basil, and tomato sauce pizza',
        'price_paise': 39900,
        'image_url': 'http://10.0.2.2:3000/images/margherita.jpg',
        'is_veg': true,
        'category': 'Italian',
        'is_available': true,
        'created_at': '2026-10-04T00:00:00.000Z',
        'restaurant_name': 'Toit Craft Brewery & Kitchen',
        'restaurant_cuisine': 'Italian, Pizza, Continental',
        'restaurant_rating': '4.6',
        'delivery_time_min': 40,
      };

      final item = MenuItem.fromJson(italianItemJson);

      expect(item.name, 'Margherita Pizza');
      expect(item.pricePaise, 39900);
      expect(item.isVeg, isTrue);
      expect(item.category, 'Italian');
      expect(item.displayRating, 4.6);
      expect(item.displayDeliveryTime, 40);
      expect(item.displayRestaurantName, 'Toit Craft Brewery & Kitchen');
      expect(item.displayCuisine, 'Italian, Pizza, Continental');
    });

    test('PaginatedRestaurants.fromJson parses pagination payload', () {
      final paginatedJson = {
        'data': [sampleRestaurantJson],
        'page': 1,
        'limit': 10,
        'total': 1,
        'totalPages': 1,
      };

      final paginated = PaginatedRestaurants.fromJson(paginatedJson);

      expect(paginated.data.length, 1);
      expect(paginated.page, 1);
      expect(paginated.limit, 10);
      expect(paginated.total, 1);
      expect(paginated.totalPages, 1);
      expect(paginated.data.first.name, 'Spice Garden');
    });
  });
}
