import 'package:dio/dio.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/order_entity.dart';

class OrderRemoteDataSource {
  final Dio _dio;

  OrderRemoteDataSource(this._dio);

  Future<OrderEntity> createOrder({
    required String restaurantId,
    required String addressId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: {
          'restaurantId': restaurantId,
          'addressId': addressId,
          'items': items,
        },
      );
      return OrderEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createPayment(String orderId) async {
    try {
      final response = await _dio.post(
        '/payments/create',
        data: {'orderId': orderId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<OrderEntity> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/verify',
        data: {
          'orderId': orderId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      final json = response.data as Map<String, dynamic>;
      final orderJson = json['order'] as Map<String, dynamic>;
      return OrderEntity.fromJson(orderJson);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getMyOrders({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<OrderEntity> getOrderById(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return OrderEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<OrderEntity> cancelOrder(String id) async {
    try {
      final response = await _dio.post('/orders/$id/cancel');
      return OrderEntity.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}
