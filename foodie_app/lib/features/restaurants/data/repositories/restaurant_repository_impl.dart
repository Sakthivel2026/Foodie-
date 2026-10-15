import '../../domain/entities/restaurant.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/repositories/restaurant_repository.dart';
import '../datasources/restaurant_remote_data_source.dart';
import '../models/paginated_restaurants.dart';

class RestaurantRepositoryImpl implements RestaurantRepository {
  final RestaurantRemoteDataSource _remoteDataSource;

  RestaurantRepositoryImpl(this._remoteDataSource);

  @override
  Future<PaginatedRestaurants> getRestaurants({
    String? search,
    String? cuisine,
    int page = 1,
    int limit = 10,
  }) async {
    return await _remoteDataSource.getRestaurants(
      search: search,
      cuisine: cuisine,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Restaurant> getRestaurantById(String id) async {
    return await _remoteDataSource.getRestaurantById(id);
  }

  @override
  Future<Map<String, List<MenuItem>>> getRestaurantMenu(
    String restaurantId, {
    String? category,
  }) async {
    return await _remoteDataSource.getRestaurantMenu(
      restaurantId,
      category: category,
    );
  }
}
