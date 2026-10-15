import 'order_item_entity.dart';

class OrderEntity {
  final String id;
  final String userId;
  final String restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final String addressId;
  final String status;
  final String paymentStatus;
  final int subtotalPaise;
  final int deliveryFeePaise;
  final int taxPaise;
  final int totalPaise;
  final List<OrderItemEntity> items;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    required this.addressId,
    required this.status,
    required this.paymentStatus,
    required this.subtotalPaise,
    required this.deliveryFeePaise,
    required this.taxPaise,
    required this.totalPaise,
    required this.items,
    required this.createdAt,
  });

  bool get isCancellable => status == 'PENDING_PAYMENT' || status == 'PLACED';

  bool get isPaid => paymentStatus == 'PAID';

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      restaurantName: json['restaurant_name'] as String?,
      restaurantImageUrl: json['restaurant_image_url'] as String?,
      addressId: json['address_id'] as String,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      subtotalPaise: json['subtotal_paise'] as int,
      deliveryFeePaise: json['delivery_fee_paise'] as int,
      taxPaise: json['tax_paise'] as int,
      totalPaise: json['total_paise'] as int,
      items: rawItems
          .map((i) => OrderItemEntity.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'restaurant_image_url': restaurantImageUrl,
      'address_id': addressId,
      'status': status,
      'payment_status': paymentStatus,
      'subtotal_paise': subtotalPaise,
      'delivery_fee_paise': deliveryFeePaise,
      'tax_paise': taxPaise,
      'total_paise': totalPaise,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
