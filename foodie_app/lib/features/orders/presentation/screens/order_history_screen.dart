import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/order_entity.dart';
import '../providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderHistoryNotifierProvider.notifier).fetchMoreOrders();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(OrderHistoryState state) {
    if (state.isLoading) {
      return const LoadingIndicator(message: 'Loading your orders...');
    }

    if (state.errorMessage != null && state.orders.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => ref.read(orderHistoryNotifierProvider.notifier).fetchOrders(),
      );
    }

    if (state.orders.isEmpty) {
      return const EmptyView(
        title: 'No Orders Yet',
        message: 'Hungry? Place your first food order today!',
        icon: Icons.receipt_long_outlined,
      );
    }

    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');

    return RefreshIndicator(
      onRefresh: () => ref.read(orderHistoryNotifierProvider.notifier).fetchOrders(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final order = state.orders[index];
          return _OrderCard(
            order: order,
            currencyFormatter: currencyFormatter,
            dateFormatter: dateFormatter,
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderEntity order;
  final NumberFormat currencyFormatter;
  final DateFormat dateFormatter;

  const _OrderCard({
    required this.order,
    required this.currencyFormatter,
    required this.dateFormatter,
  });

  bool get _canCancel => order.status == 'PENDING_PAYMENT' || order.status == 'PLACED';
  bool get _isActive =>
      order.status == 'PENDING_PAYMENT' ||
      order.status == 'PLACED' ||
      order.status == 'PREPARING' ||
      order.status == 'OUT_FOR_DELIVERY';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant info & status
            Row(
              children: [
                if (order.restaurantImageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: order.restaurantImageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName ?? 'Restaurant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatter.format(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const Divider(height: 24),

            // Item summary
            Text(
              order.items.map((i) => '${i.quantity}x ${i.nameSnapshot}').join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Total price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: theme.textTheme.bodySmall),
                Text(
                  currencyFormatter.format(order.totalPaise / 100),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (_isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/tracking/${order.id}'),
                      icon: const Icon(Icons.navigation, size: 16),
                      label: const Text('Track Order'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_canCancel) ...[
                  OutlinedButton(
                    onPressed: () => _confirmCancel(context, ref),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _handleReorder(context, ref),
                  icon: const Icon(Icons.replay, size: 16),
                  label: const Text('Reorder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(orderHistoryNotifierProvider.notifier).cancelOrder(order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel order: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleReorder(BuildContext context, WidgetRef ref) async {
    try {
      final res = await performReorder(ref: ref, order: order);
      if (!context.mounted) return;

      if (res.unavailableItemNames.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Some items unavailable'),
            content: Text(
              'The following items are currently unavailable and were not added:\n• ${res.unavailableItemNames.join("\n• ")}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      if (context.mounted) {
        context.go('/cart');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reorder failed: $e')),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'PLACED':
      case 'PREPARING':
      case 'OUT_FOR_DELIVERY':
        return Colors.orange.shade800;
      case 'DELIVERED':
        return Colors.green.shade800;
      case 'CANCELLED':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
