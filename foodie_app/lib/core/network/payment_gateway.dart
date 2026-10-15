import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentDetails {
  final String orderId;
  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;

  const PaymentDetails({
    required this.orderId,
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });
}

class PaymentResult {
  final bool isSuccess;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? errorMessage;

  const PaymentResult.success({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  })  : isSuccess = true,
        errorMessage = null;

  const PaymentResult.failure({
    required this.errorMessage,
  })  : isSuccess = false,
        razorpayOrderId = null,
        razorpayPaymentId = null,
        razorpaySignature = null;
}

abstract class PaymentGateway {
  Future<PaymentResult> processPayment(PaymentDetails details);
}

class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> processPayment(PaymentDetails details) async {
    // Simulate short payment processing delay
    await Future.delayed(const Duration(milliseconds: 600));

    final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';

    return PaymentResult.success(
      razorpayOrderId: details.razorpayOrderId,
      razorpayPaymentId: mockPaymentId,
      razorpaySignature: 'mock_signature',
    );
  }
}

class RazorpayPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentResult> processPayment(PaymentDetails details) {
    throw UnimplementedError('RazorpayPaymentGateway is implemented in Stage 11');
  }
}

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  const mode = String.fromEnvironment('PAYMENT_MODE', defaultValue: 'mock');
  if (mode == 'razorpay') {
    return RazorpayPaymentGateway();
  }
  return MockPaymentGateway();
});
