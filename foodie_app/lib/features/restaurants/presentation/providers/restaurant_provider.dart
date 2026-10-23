import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/restaurant_remote_data_source.dart';
import '../../data/models/paginated_restaurants.dart';
import '../../data/repositories/restaurant_repository_impl.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/restaurant_repository.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remoteDataSource = RestaurantRemoteDataSource(dio);
  return RestaurantRepositoryImpl(remoteDataSource);
});

class RestaurantListState {
  final List<Restaurant> restaurants;
  final List<MenuItem> foodItems;
  final bool isFoodView;
  final bool isLoading;
  final bool isFetchingMore;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCuisine;
  final int page;
  final int totalPages;

  const RestaurantListState({
    required this.restaurants,
    this.foodItems = const [],
    this.isFoodView = true,
    required this.isLoading,
    required this.isFetchingMore,
    this.errorMessage,
    required this.searchQuery,
    required this.selectedCuisine,
    required this.page,
    required this.totalPages,
  });

  factory RestaurantListState.initial() => const RestaurantListState(
        restaurants: [],
        foodItems: [],
        isFoodView: true,
        isLoading: true,
        isFetchingMore: false,
        errorMessage: null,
        searchQuery: '',
        selectedCuisine: 'All',
        page: 1,
        totalPages: 1,
      );

  RestaurantListState copyWith({
    List<Restaurant>? restaurants,
    List<MenuItem>? foodItems,
    bool? isFoodView,
    bool? isLoading,
    bool? isFetchingMore,
    String? errorMessage,
    String? searchQuery,
    String? selectedCuisine,
    int? page,
    int? totalPages,
  }) {
    return RestaurantListState(
      restaurants: restaurants ?? this.restaurants,
      foodItems: foodItems ?? this.foodItems,
      isFoodView: isFoodView ?? this.isFoodView,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCuisine: selectedCuisine ?? this.selectedCuisine,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class RestaurantListNotifier extends Notifier<RestaurantListState> {
  Timer? _debounceTimer;

  @override
  RestaurantListState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    // Load initial list
    Future.microtask(() => loadRestaurants());
    return RestaurantListState.initial();
  }

  Future<void> loadRestaurants({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, isLoading: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final repository = ref.read(restaurantRepositoryProvider);
      final results = await Future.wait([
        repository.getRestaurants(
          search: state.searchQuery,
          cuisine: state.selectedCuisine,
          page: 1,
          limit: 10,
        ),
        repository.getMenuItems(
          search: state.searchQuery,
          cuisine: state.selectedCuisine,
          page: 1,
          limit: 50,
        ),
      ]);

      final paginated = results[0] as PaginatedRestaurants;
      final items = results[1] as List<MenuItem>;

      state = state.copyWith(
        restaurants: paginated.data,
        foodItems: items,
        isLoading: false,
        page: paginated.page,
        totalPages: paginated.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Failure: ', ''),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isFetchingMore || state.page >= state.totalPages) {
      return;
    }

    state = state.copyWith(isFetchingMore: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(restaurantRepositoryProvider);
      final paginated = await repository.getRestaurants(
        search: state.searchQuery,
        cuisine: state.selectedCuisine,
        page: nextPage,
        limit: 10,
      );

      state = state.copyWith(
        restaurants: [...state.restaurants, ...paginated.data],
        isFetchingMore: false,
        page: paginated.page,
        totalPages: paginated.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      loadRestaurants(refresh: true);
    });
  }

  void onCuisineSelected(String cuisine) {
    if (state.selectedCuisine == cuisine) return;
    state = state.copyWith(selectedCuisine: cuisine, isFoodView: true);
    loadRestaurants(refresh: true);
  }

  void toggleViewMode(bool isFoodView) {
    if (state.isFoodView == isFoodView) return;
    state = state.copyWith(isFoodView: isFoodView);
  }
}

final restaurantListNotifierProvider =
    NotifierProvider<RestaurantListNotifier, RestaurantListState>(() {
  return RestaurantListNotifier();
});

// Single Restaurant Detail Provider
final restaurantDetailProvider =
    FutureProvider.family<Restaurant, String>((ref, id) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return await repository.getRestaurantById(id);
});

// Restaurant Menu Provider
final restaurantMenuProvider =
    FutureProvider.family<Map<String, List<MenuItem>>, String>((ref, id) async {
  final repository = ref.watch(restaurantRepositoryProvider);
  return await repository.getRestaurantMenu(id);
});
