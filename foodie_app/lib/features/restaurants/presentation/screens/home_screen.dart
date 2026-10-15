import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/cuisine_filter_chips.dart';
import '../widgets/restaurant_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListNotifierProvider);
    final notifier = ref.read(restaurantListNotifierProvider.notifier);
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
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: notifier.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search restaurants or cuisines...',
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

          // Cuisine Chips
          CuisineFilterChips(
            selectedCuisine: state.selectedCuisine,
            onSelected: notifier.onCuisineSelected,
          ),
          const SizedBox(height: 8),

          // Main List / States
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadRestaurants(refresh: true),
              child: _buildBody(state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RestaurantListState state, RestaurantListNotifier notifier) {
    if (state.isLoading && state.restaurants.isEmpty) {
      return const LoadingIndicator(message: 'Finding delicious food near you...');
    }

    if (state.errorMessage != null && state.restaurants.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => notifier.loadRestaurants(refresh: true),
      );
    }

    if (state.restaurants.isEmpty) {
      return const EmptyView(
        title: 'No restaurants found',
        message: 'Try adjusting your search query or filter chips.',
        icon: Icons.search_off,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.restaurants.length + (state.isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.restaurants.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final restaurant = state.restaurants[index];
        return RestaurantCard(
          restaurant: restaurant,
          onTap: () => context.push('/restaurant/${restaurant.id}'),
        );
      },
    );
  }
}
