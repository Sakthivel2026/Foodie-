/// Environment configuration for Foodie App.
/// Allows compile-time or runtime overrides via `--dart-define`.
abstract class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String paymentMode = String.fromEnvironment(
    'PAYMENT_MODE',
    defaultValue: 'mock',
  );
}
