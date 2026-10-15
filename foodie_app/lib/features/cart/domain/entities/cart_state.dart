import 'dart:convert';
import '../../../restaurants/domain/entities/restaurant.dart';
import 'cart_item.dart';

class CartState {
  final Restaurant? restaurant;
  final List<CartItem> items;

  const CartState({
    this.restaurant,
    this.items = const [],
  });

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotalPaise =>
      items.fold(0, (sum, item) => sum + item.subtotalPaise);

  int get deliveryFeePaise => restaurant?.deliveryFeePaise ?? 0;

  // 5% tax rounded using Math.round equivalent in Dart
  int get taxPaise => (subtotalPaise * 0.05).round();

  int get totalPaise => subtotalPaise + deliveryFeePaise + taxPaise;

  CartState copyWith({
    Restaurant? restaurant,
    List<CartItem>? items,
  }) {
    return CartState(
      restaurant: restaurant ?? this.restaurant,
      items: items ?? this.items,
    );
  }

  factory CartState.fromJson(Map<String, dynamic> json) {
    final restaurantJson = json['restaurant'] as Map<String, dynamic>?;
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return CartState(
      restaurant:
          restaurantJson != null ? Restaurant.fromJson(restaurantJson) : null,
      items: itemsJson
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant': restaurant?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String encode() => jsonEncode(toJson());

  factory CartState.decode(String str) =>
      CartState.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
