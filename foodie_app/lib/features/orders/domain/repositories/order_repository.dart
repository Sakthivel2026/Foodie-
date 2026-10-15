import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<OrderEntity> createOrder({
    required String restaurantId,
    required String addressId,
    required List<Map<String, dynamic>> items,
  });

  Future<Map<String, dynamic>> createPayment(String orderId);

  Future<OrderEntity> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });

  Future<Map<String, dynamic>> getMyOrders({int page = 1, int limit = 10});

  Future<OrderEntity> getOrderById(String id);

  Future<OrderEntity> cancelOrder(String id);
}
