import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/payment_gateway.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../orders/data/datasources/order_remote_data_source.dart';
import '../../../orders/data/repositories/order_repository_impl.dart';
import '../../../orders/domain/entities/order_entity.dart';
import '../../../orders/domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remoteDataSource = OrderRemoteDataSource(dio);
  return OrderRepositoryImpl(remoteDataSource);
});

enum CheckoutStatus {
  initial,
  submittingOrder,
  processingPayment,
  verifyingPayment,
  success,
  paymentFailed,
  error,
}

class CheckoutState {
  final CheckoutStatus status;
  final OrderEntity? createdOrder;
  final OrderEntity? verifiedOrder;
  final String? errorMessage;
  final bool isSubmitting;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.createdOrder,
    this.verifiedOrder,
    this.errorMessage,
    this.isSubmitting = false,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    OrderEntity? createdOrder,
    OrderEntity? verifiedOrder,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      createdOrder: createdOrder ?? this.createdOrder,
      verifiedOrder: verifiedOrder ?? this.verifiedOrder,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<void> placeOrderAndPay({required String addressId}) async {
    // 1. Double-submit protection
    if (state.isSubmitting) return;

    final cartState = ref.read(cartNotifierProvider);
    if (cartState.isEmpty || cartState.restaurant == null) {
      state = state.copyWith(
        status: CheckoutStatus.error,
        errorMessage: 'Cart is empty',
      );
      return;
    }

    state = state.copyWith(
      status: CheckoutStatus.submittingOrder,
      isSubmitting: true,
      errorMessage: null,
    );

    try {
      final orderRepository = ref.read(orderRepositoryProvider);
      final paymentGateway = ref.read(paymentGatewayProvider);

      final itemsPayload = cartState.items
          .map((item) => {
                'menuItemId': item.menuItem.id,
                'quantity': item.quantity,
              })
          .toList();

      // 2. Create Order
      final order = await orderRepository.createOrder(
        restaurantId: cartState.restaurant!.id,
        addressId: addressId,
        items: itemsPayload,
      );

      state = state.copyWith(
        status: CheckoutStatus.processingPayment,
        createdOrder: order,
      );

      // 3. Create Payment Details
      final paymentInfo = await orderRepository.createPayment(order.id);

      final paymentDetails = PaymentDetails(
        orderId: order.id,
        razorpayOrderId: paymentInfo['razorpayOrderId'] as String,
        amountPaise: paymentInfo['amountPaise'] as int,
        currency: paymentInfo['currency'] as String? ?? 'INR',
        keyId: paymentInfo['keyId'] as String? ?? 'mock_key',
      );

      // 4. Process Payment
      final paymentResult = await paymentGateway.processPayment(paymentDetails);

      if (!paymentResult.isSuccess) {
        state = state.copyWith(
          status: CheckoutStatus.paymentFailed,
          isSubmitting: false,
          errorMessage: paymentResult.errorMessage ?? 'Payment cancelled or failed',
        );
        return;
      }

      // 5. Verify Payment
      state = state.copyWith(status: CheckoutStatus.verifyingPayment);

      final verifiedOrder = await orderRepository.verifyPayment(
        orderId: order.id,
        razorpayOrderId: paymentResult.razorpayOrderId!,
        razorpayPaymentId: paymentResult.razorpayPaymentId!,
        razorpaySignature: paymentResult.razorpaySignature!,
      );

      // 6. Clear Cart ONLY after successful payment verification
      ref.read(cartNotifierProvider.notifier).clearCart();

      state = state.copyWith(
        status: CheckoutStatus.success,
        verifiedOrder: verifiedOrder,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.error,
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Failure: ', ''),
      );
    }
  }

  Future<void> retryPaymentForCreatedOrder() async {
    final order = state.createdOrder;
    if (order == null || state.isSubmitting) return;

    state = state.copyWith(
      status: CheckoutStatus.processingPayment,
      isSubmitting: true,
      errorMessage: null,
    );

    try {
      final orderRepository = ref.read(orderRepositoryProvider);
      final paymentGateway = ref.read(paymentGatewayProvider);

      final paymentInfo = await orderRepository.createPayment(order.id);

      final paymentDetails = PaymentDetails(
        orderId: order.id,
        razorpayOrderId: paymentInfo['razorpayOrderId'] as String,
        amountPaise: paymentInfo['amountPaise'] as int,
        currency: paymentInfo['currency'] as String? ?? 'INR',
        keyId: paymentInfo['keyId'] as String? ?? 'mock_key',
      );

      final paymentResult = await paymentGateway.processPayment(paymentDetails);

      if (!paymentResult.isSuccess) {
        state = state.copyWith(
          status: CheckoutStatus.paymentFailed,
          isSubmitting: false,
          errorMessage: paymentResult.errorMessage ?? 'Payment cancelled or failed',
        );
        return;
      }

      state = state.copyWith(status: CheckoutStatus.verifyingPayment);

      final verifiedOrder = await orderRepository.verifyPayment(
        orderId: order.id,
        razorpayOrderId: paymentResult.razorpayOrderId!,
        razorpayPaymentId: paymentResult.razorpayPaymentId!,
        razorpaySignature: paymentResult.razorpaySignature!,
      );

      ref.read(cartNotifierProvider.notifier).clearCart();

      state = state.copyWith(
        status: CheckoutStatus.success,
        verifiedOrder: verifiedOrder,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.error,
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Failure: ', ''),
      );
    }
  }
}

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(() {
  return CheckoutNotifier();
});
