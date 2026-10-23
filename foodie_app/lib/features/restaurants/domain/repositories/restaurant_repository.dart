import '../entities/restaurant.dart';
import '../entities/menu_item.dart';
import '../../data/models/paginated_restaurants.dart';

abstract class RestaurantRepository {
  Future<PaginatedRestaurants> getRestaurants({
    String? search,
    String? cuisine,
    int page = 1,
    int limit = 10,
  });

  Future<Restaurant> getRestaurantById(String id);

  Future<Map<String, List<MenuItem>>> getRestaurantMenu(
    String restaurantId, {
    String? category,
  });

  Future<List<MenuItem>> getMenuItems({
    String? search,
    String? cuisine,
    int page = 1,
    int limit = 50,
  });
}
