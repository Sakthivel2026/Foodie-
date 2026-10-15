import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../restaurants/data/datasources/restaurant_remote_data_source.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  return OrderRemoteDataSource(ref.watch(dioProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderRemoteDataSourceProvider));
});

class OrderHistoryState {
  final List<OrderEntity> orders;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isFetchingMore;
  final String? errorMessage;

  const OrderHistoryState({
    this.orders = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = true,
    this.isFetchingMore = false,
    this.errorMessage,
  });

  OrderHistoryState copyWith({
    List<OrderEntity>? orders,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isFetchingMore,
    String? errorMessage,
  }) {
    return OrderHistoryState(
      orders: orders ?? this.orders,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      errorMessage: errorMessage,
    );
  }
}

class OrderHistoryNotifier extends Notifier<OrderHistoryState> {
  @override
  OrderHistoryState build() {
    Future.microtask(() => fetchOrders());
    return const OrderHistoryState();
  }

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  Future<void> fetchOrders() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final result = await _repo.getMyOrders(page: 1);
      final list = (result['data'] as List)
          .map((json) => OrderEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        orders: list,
        page: result['page'] as int? ?? 1,
        totalPages: result['totalPages'] as int? ?? 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchMoreOrders() async {
    if (state.isFetchingMore || state.page >= state.totalPages) return;
    try {
      state = state.copyWith(isFetchingMore: true);
      final nextPage = state.page + 1;
      final result = await _repo.getMyOrders(page: nextPage);
      final list = (result['data'] as List)
          .map((json) => OrderEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        orders: [...state.orders, ...list],
        page: result['page'] as int? ?? nextPage,
        totalPages: result['totalPages'] as int? ?? state.totalPages,
        isFetchingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isFetchingMore: false);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final updated = await _repo.cancelOrder(orderId);
      final updatedList = state.orders.map((o) => o.id == orderId ? updated : o).toList();
      state = state.copyWith(orders: updatedList);
    } catch (e) {
      rethrow;
    }
  }
}

final orderHistoryNotifierProvider =
    NotifierProvider<OrderHistoryNotifier, OrderHistoryState>(OrderHistoryNotifier.new);

class ReorderResult {
  final int addedCount;
  final List<String> unavailableItemNames;

  ReorderResult({
    required this.addedCount,
    required this.unavailableItemNames,
  });
}

Future<ReorderResult> performReorder({
  required WidgetRef ref,
  required OrderEntity order,
}) async {
  final dio = ref.read(dioProvider);
  final restaurantDS = RestaurantRemoteDataSource(dio);

  final restaurant = await restaurantDS.getRestaurantById(order.restaurantId);
  final menuCategories = await restaurantDS.getRestaurantMenu(order.restaurantId);

  // Flatten all menu items across categories
  final allMenuItems = menuCategories.values.expand((items) => items).toList();
  final availableItems = allMenuItems.where((i) => i.isAvailable).toList();

  final cartNotifier = ref.read(cartNotifierProvider.notifier);
  cartNotifier.clearCart();

  final unavailableNames = <String>[];
  var addedCount = 0;

  for (final orderItem in order.items) {
    final matchIndex = availableItems.indexWhere((item) => item.id == orderItem.menuItemId);
    if (matchIndex >= 0) {
      final matchingItem = availableItems[matchIndex];
      for (var i = 0; i < orderItem.quantity; i++) {
        cartNotifier.addItem(restaurant: restaurant, menuItem: matchingItem);
      }
      addedCount++;
    } else {
      unavailableNames.add(orderItem.nameSnapshot);
    }
  }

  return ReorderResult(
    addedCount: addedCount,
    unavailableItemNames: unavailableNames,
  );
}
