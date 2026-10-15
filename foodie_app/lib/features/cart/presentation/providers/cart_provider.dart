import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../restaurants/domain/entities/menu_item.dart';
import '../../../restaurants/domain/entities/restaurant.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/cart_state.dart';

enum AddToCartResult {
  success,
  restaurantMismatch,
}

class CartNotifier extends Notifier<CartState> {
  static const String _storageKey = 'foodie_cart';

  @override
  CartState build() {
    _loadFromStorage();
    return const CartState();
  }

  void _loadFromStorage() {
    final storage = ref.read(storageServiceProvider);
    final raw = storage.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        state = CartState.decode(raw);
      } catch (_) {
        // Ignore corrupt storage data
      }
    }
  }

  Future<void> _persist() async {
    final storage = ref.read(storageServiceProvider);
    if (state.isEmpty) {
      await storage.remove(_storageKey);
    } else {
      await storage.setString(_storageKey, state.encode());
    }
  }

  AddToCartResult addItem({
    required Restaurant restaurant,
    required MenuItem menuItem,
  }) {
    if (state.restaurant != null && state.restaurant!.id != restaurant.id) {
      return AddToCartResult.restaurantMismatch;
    }

    final existingIndex =
        state.items.indexWhere((item) => item.menuItem.id == menuItem.id);

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + 1);
      newItems = List.from(state.items)..[existingIndex] = updated;
    } else {
      newItems = [
        ...state.items,
        CartItem(menuItem: menuItem, quantity: 1),
      ];
    }

    state = state.copyWith(
      restaurant: restaurant,
      items: newItems,
    );
    _persist();
    return AddToCartResult.success;
  }

  void replaceCartWithItem({
    required Restaurant restaurant,
    required MenuItem menuItem,
  }) {
    state = CartState(
      restaurant: restaurant,
      items: [CartItem(menuItem: menuItem, quantity: 1)],
    );
    _persist();
  }

  void removeItem(String menuItemId) {
    final existingIndex =
        state.items.indexWhere((item) => item.menuItem.id == menuItemId);
    if (existingIndex < 0) return;

    final existing = state.items[existingIndex];
    List<CartItem> newItems;

    if (existing.quantity > 1) {
      final updated = existing.copyWith(quantity: existing.quantity - 1);
      newItems = List.from(state.items)..[existingIndex] = updated;
    } else {
      newItems = List.from(state.items)..removeAt(existingIndex);
    }

    state = CartState(
      restaurant: newItems.isEmpty ? null : state.restaurant,
      items: newItems,
    );
    _persist();
  }

  void clearCart() {
    state = const CartState();
    _persist();
  }

  int getItemQuantity(String menuItemId) {
    for (final item in state.items) {
      if (item.menuItem.id == menuItemId) {
        return item.quantity;
      }
    }
    return 0;
  }
}

final cartNotifierProvider =
    NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});
