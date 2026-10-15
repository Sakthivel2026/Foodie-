import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/addresses/domain/entities/address.dart';
import '../features/addresses/presentation/screens/add_edit_address_screen.dart';
import '../features/addresses/presentation/screens/address_list_screen.dart';
import '../features/addresses/presentation/screens/location_picker_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/orders/presentation/screens/order_detail_screen.dart';
import '../features/orders/presentation/screens/order_history_screen.dart';
import '../features/orders/presentation/screens/tracking_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/restaurants/presentation/screens/home_screen.dart';
import '../features/restaurants/presentation/screens/restaurant_detail_screen.dart';
import '../features/shell/presentation/shell_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isSplash = state.matchedLocation == '/';
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (isSplash) return null;

      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (!isAuthenticated && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      if (isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/restaurant/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RestaurantDetailScreen(restaurantId: id);
            },
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/tracking/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return TrackingScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/addresses',
            builder: (context, state) => const AddressListScreen(),
          ),
          GoRoute(
            path: '/addresses/add',
            builder: (context, state) => const AddEditAddressScreen(),
          ),
          GoRoute(
            path: '/addresses/edit/:id',
            builder: (context, state) {
              final address = state.extra as Address?;
              return AddEditAddressScreen(address: address);
            },
          ),
          GoRoute(
            path: '/addresses/picker',
            builder: (context, state) => const LocationPickerScreen(),
          ),
        ],
      ),
    ],
  );
});
