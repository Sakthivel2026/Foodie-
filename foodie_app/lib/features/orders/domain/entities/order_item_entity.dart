class OrderItemEntity {
  final String id;
  final String orderId;
  final String menuItemId;
  final String nameSnapshot;
  final int pricePaiseSnapshot;
  final int quantity;

  const OrderItemEntity({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.nameSnapshot,
    required this.pricePaiseSnapshot,
    required this.quantity,
  });

  int get subtotalPaise => pricePaiseSnapshot * quantity;

  factory OrderItemEntity.fromJson(Map<String, dynamic> json) {
    return OrderItemEntity(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      nameSnapshot: json['name_snapshot'] as String,
      pricePaiseSnapshot: json['price_paise_snapshot'] as int,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'name_snapshot': nameSnapshot,
      'price_paise_snapshot': pricePaiseSnapshot,
      'quantity': quantity,
    };
  }
}
