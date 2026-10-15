import '../../domain/entities/restaurant.dart';

class PaginatedRestaurants {
  final List<Restaurant> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedRestaurants({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedRestaurants.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>)
        .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedRestaurants(
      data: list,
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
