import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/storage_service.dart';
import 'auth_interceptor.dart';

class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void trigger() => state = true;
  void reset() => state = false;
}

final sessionExpiredNotifierProvider =
    NotifierProvider<SessionExpiredNotifier, bool>(SessionExpiredNotifier.new);

final dioProvider = Provider<Dio>((ref) {
  final storageService = ref.watch(storageServiceProvider);

  final options = BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  // Attach Auth Interceptor for JWT handling & serialized token refresh
  dio.interceptors.add(
    AuthInterceptor(
      storageService,
      () {
        ref.read(sessionExpiredNotifierProvider.notifier).trigger();
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('--> ${options.method} ${options.uri}');
          final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
          if (sanitizedHeaders.containsKey('Authorization')) {
            sanitizedHeaders['Authorization'] = 'Bearer [REDACTED]';
          }
          if (sanitizedHeaders.containsKey('x-admin-key')) {
            sanitizedHeaders['x-admin-key'] = '[REDACTED]';
          }
          debugPrint('Headers: $sanitizedHeaders');

          if (options.data != null) {
            if (options.data is Map) {
              final Map dataCopy = Map.from(options.data as Map);
              if (dataCopy.containsKey('password')) {
                dataCopy['password'] = '[REDACTED]';
              }
              if (dataCopy.containsKey('refreshToken')) {
                dataCopy['refreshToken'] = '[REDACTED]';
              }
              debugPrint('Body: $dataCopy');
            } else {
              debugPrint('Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          debugPrint('<-- ERROR ${error.response?.statusCode} ${error.requestOptions.uri}');
          debugPrint('Error Message: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  return dio;
});
