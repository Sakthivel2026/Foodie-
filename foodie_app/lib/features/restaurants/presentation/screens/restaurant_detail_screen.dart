import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/menu_item_tile.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  void _onAddItem(
    BuildContext context,
    WidgetRef ref,
    Restaurant restaurant,
    MenuItem item,
  ) {
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
            'Your cart contains items from ${ref.read(cartNotifierProvider).restaurant?.name}. Would you like to reset your cart and add items from ${restaurant.name}?',
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
                      restaurant: restaurant,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(restaurantId));
    final menuAsync = ref.watch(restaurantMenuProvider(restaurantId));
    final cartState = ref.watch(cartNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: restaurantAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading restaurant details...'),
        error: (error, stack) => ErrorView(
          message: error.toString().replaceFirst('Failure: ', ''),
          onRetry: () {
            ref.invalidate(restaurantDetailProvider(restaurantId));
            ref.invalidate(restaurantMenuProvider(restaurantId));
          },
        ),
        data: (restaurant) {
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        restaurant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Color(0xB3000000),
                            ),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: restaurant.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.restaurant, size: 64),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Info Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                restaurant.cuisine,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      restaurant.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('${restaurant.deliveryTimeMin} mins delivery'),
                              const SizedBox(width: 16),
                              Icon(Icons.delivery_dining,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.deliveryFeePaise == 0
                                    ? 'FREE Delivery'
                                    : CurrencyFormatter.formatPaise(
                                        restaurant.deliveryFeePaise),
                              ),
                            ],
                          ),
                          if (!restaurant.isOpen) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: theme.colorScheme.onErrorContainer),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Restaurant is currently closed. Not accepting orders.',
                                      style: TextStyle(
                                        color: theme.colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  ),

                  // Menu Items Grouped by Category
                  menuAsync.when(
                    loading: () => const SliverFillRemaining(
                      child: LoadingIndicator(message: 'Loading menu...'),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      child: ErrorView(
                        message: error.toString().replaceFirst('Failure: ', ''),
                        onRetry: () => ref.invalidate(restaurantMenuProvider(restaurantId)),
                      ),
                    ),
                    data: (categoriesMap) {
                      if (categoriesMap.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text('No menu items available right now.'),
                          ),
                        );
                      }

                      final categoryNames = categoriesMap.keys.toList();

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final categoryName = categoryNames[index];
                            final items = categoriesMap[categoryName] ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  child: Text(
                                    '$categoryName (${items.length})',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...items.map((item) {
                                  final qty = ref
                                      .watch(cartNotifierProvider.notifier)
                                      .getItemQuantity(item.id);

                                  return MenuItemTile(
                                    menuItem: item,
                                    quantity: qty,
                                    onAdd: () => _onAddItem(
                                      context,
                                      ref,
                                      restaurant,
                                      item,
                                    ),
                                    onRemove: () => ref
                                        .read(cartNotifierProvider.notifier)
                                        .removeItem(item.id),
                                  );
                                }),
                              ],
                            );
                          },
                          childCount: categoryNames.length,
                        ),
                      );
                    },
                  ),

                  // Extra bottom padding for floating cart bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),

              // Floating View Cart Bar
              if (!cartState.isEmpty &&
                  cartState.restaurant?.id == restaurant.id)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
          );
        },
      ),
    );
  }
}
