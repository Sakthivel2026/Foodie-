import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<OrderEntity> createOrder({
    required String restaurantId,
    required String addressId,
    required List<Map<String, dynamic>> items,
  }) =>
      _remoteDataSource.createOrder(
        restaurantId: restaurantId,
        addressId: addressId,
        items: items,
      );

  @override
  Future<Map<String, dynamic>> createPayment(String orderId) =>
      _remoteDataSource.createPayment(orderId);

  @override
  Future<OrderEntity> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      _remoteDataSource.verifyPayment(
        orderId: orderId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

  @override
  Future<Map<String, dynamic>> getMyOrders({int page = 1, int limit = 10}) =>
      _remoteDataSource.getMyOrders(page: page, limit: limit);

  @override
  Future<OrderEntity> getOrderById(String id) =>
      _remoteDataSource.getOrderById(id);

  @override
  Future<OrderEntity> cancelOrder(String id) =>
      _remoteDataSource.cancelOrder(id);
}
