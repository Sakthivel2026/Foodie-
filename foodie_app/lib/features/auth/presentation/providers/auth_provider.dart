import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storageService = ref.watch(storageServiceProvider);
  final remoteDataSource = AuthRemoteDataSource(dio);
  return AuthRepositoryImpl(remoteDataSource, storageService);
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Listen for session expiration events from Dio AuthInterceptor
    ref.listen<bool>(sessionExpiredNotifierProvider, (previous, next) {
      if (next) {
        state = AuthState.unauthenticated('Session expired. Please log in again.');
        ref.read(sessionExpiredNotifierProvider.notifier).reset();
      }
    });
    return AuthState.initial();
  }

  Future<void> restoreSession() async {
    final storageService = ref.read(storageServiceProvider);
    final accessToken = await storageService.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      state = AuthState.unauthenticated();
      return;
    }

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.me();
      state = AuthState.authenticated(user);
    } catch (_) {
      await storageService.clearTokens();
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(email, password);
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Failure: ', '');
      state = AuthState.unauthenticated(message);
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = AuthState.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.register(name, email, password);
      state = AuthState.authenticated(response.user);
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Failure: ', '');
      state = AuthState.unauthenticated(message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
    } catch (_) {
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearTokens();
    } finally {
      state = AuthState.unauthenticated();
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthListenable extends ChangeNotifier {
  final Ref _ref;

  AuthListenable(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final authListenableProvider = Provider<AuthListenable>((ref) {
  return AuthListenable(ref);
});
