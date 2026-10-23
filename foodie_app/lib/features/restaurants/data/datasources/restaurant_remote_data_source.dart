import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/entities/menu_item.dart';
import '../models/paginated_restaurants.dart';

class RestaurantRemoteDataSource {
  final Dio _dio;

  RestaurantRemoteDataSource(this._dio);

  Future<PaginatedRestaurants> getRestaurants({
    String? search,
    String? cuisine,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }
      if (cuisine != null && cuisine.trim().isNotEmpty && cuisine != 'All') {
        queryParameters['cuisine'] = cuisine.trim();
      }

      final response = await _dio.get(
        '/restaurants',
        queryParameters: queryParameters,
      );

      return PaginatedRestaurants.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Restaurant> getRestaurantById(String id) async {
    try {
      final response = await _dio.get('/restaurants/$id');
      return Restaurant.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Map<String, List<MenuItem>>> getRestaurantMenu(
    String restaurantId, {
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.trim().isNotEmpty) {
        queryParams['category'] = category.trim();
      }

      final response = await _dio.get(
        '/restaurants/$restaurantId/menu',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final categoriesJson = data['categories'] as Map<String, dynamic>;

      final Map<String, List<MenuItem>> result = {};
      categoriesJson.forEach((categoryName, itemsList) {
        final list = (itemsList as List<dynamic>)
            .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
            .toList();
        result[categoryName] = list;
      });

      return result;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<List<MenuItem>> getMenuItems({
    String? search,
    String? cuisine,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }
      if (cuisine != null && cuisine.trim().isNotEmpty && cuisine != 'All') {
        queryParameters['cuisine'] = cuisine.trim();
      }

      final response = await _dio.get(
        '/restaurants/items',
        queryParameters: queryParameters,
      );

      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((item) => MenuItem.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

