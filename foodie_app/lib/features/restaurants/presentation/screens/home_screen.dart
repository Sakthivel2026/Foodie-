import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../cart/domain/entities/cart_state.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/cuisine_filter_chips.dart';
import '../widgets/food_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(restaurantListNotifierProvider.notifier).fetchNextPage();
    }
  }

  void _onAddItem(BuildContext context, MenuItem item) {
    final state = ref.read(restaurantListNotifierProvider);
    Restaurant? restaurant;
    for (final r in state.restaurants) {
      if (r.id == item.restaurantId) {
        restaurant = r;
        break;
      }
    }
    restaurant ??= Restaurant(
      id: item.restaurantId,
      name: item.displayRestaurantName,
      cuisine: item.displayCuisine,
      imageUrl: item.imageUrl,
      rating: item.displayRating,
      deliveryTimeMin: item.displayDeliveryTime,
      deliveryFeePaise: 4000,
      lat: 12.9716,
      lng: 77.5946,
      isOpen: true,
      createdAt: item.createdAt,
    );

    final result = ref.read(cartNotifierProvider.notifier).addItem(
          restaurant: restaurant,
          menuItem: item,
        );

    if (result == AddToCartResult.restaurantMismatch) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace cart item?'),
          content: Text(
            'Your cart contains items from ${ref.read(cartNotifierProvider).restaurant?.name}. Would you like to reset your cart and add items from ${restaurant!.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(cartNotifierProvider.notifier).replaceCartWithItem(
                      restaurant: restaurant!,
                      menuItem: item,
                    );
              },
              child: const Text('REPLACE'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListNotifierProvider);
    final notifier = ref.read(restaurantListNotifierProvider.notifier);
    final cartState = ref.watch(cartNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Foodie',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search food items, cuisines, or restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              notifier.onSearchChanged('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),

              // Cuisine Filter Chips
              CuisineFilterChips(
                selectedCuisine: state.selectedCuisine,
                onSelected: notifier.onCuisineSelected,
              ),
              const SizedBox(height: 8),

              // Main List / States
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => notifier.loadRestaurants(refresh: true),
                  child: _buildBody(state, notifier, cartState),
                ),
              ),
            ],
          ),

          // Floating View Cart Bar
          if (!cartState.isEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cartState.itemCount} ${cartState.itemCount == 1 ? 'ITEM' : 'ITEMS'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(cartState.subtotalPaise),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary,
                        minimumSize: const Size(120, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text(
                        'View Cart',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    RestaurantListState state,
    RestaurantListNotifier notifier,
    CartState cartState,
  ) {
    final hasNoData = state.foodItems.isEmpty;

    if (state.isLoading && hasNoData) {
      return const LoadingIndicator(
        message: 'Finding delicious dishes near you...',
      );
    }

    if (state.errorMessage != null && hasNoData) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => notifier.loadRestaurants(refresh: true),
      );
    }

    if (hasNoData) {
      final isFiltered = state.selectedCuisine != 'All';
      final emptyTitle = isFiltered
          ? 'No ${state.selectedCuisine} food items found'
          : 'No food items found';

      return EmptyView(
        title: emptyTitle,
        message: state.searchQuery.isNotEmpty
            ? 'No matches found for "${state.searchQuery}". Try a different search.'
            : 'Try adjusting your search query or filter chips.',
        icon: Icons.fastfood_outlined,
      );
    }

    return ListView.builder(
      key: const PageStorageKey('food_items_list'),
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: state.foodItems.length,
      itemBuilder: (context, index) {
        final item = state.foodItems[index];
        final qty = cartState.getItemQuantity(item.id);

        return FoodCard(
          menuItem: item,
          quantity: qty,
          onAdd: () => _onAddItem(context, item),
          onRemove: () => ref.read(cartNotifierProvider.notifier).removeItem(item.id),
          onTap: () => context.push('/restaurant/${item.restaurantId}'),
        );
      },
    );
  }
}

