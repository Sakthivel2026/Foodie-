import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env.dart';
import '../storage/storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final StorageService _storageService;
  final void Function()? _onSessionExpired;
  final Dio _refreshDio;

  static Completer<String?>? _refreshCompleter;

  AuthInterceptor(
    this._storageService,
    this._onSessionExpired, [
    Dio? refreshDio,
  ]) : _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      final currentToken = await _storageService.getAccessToken();
      final requestToken = err.requestOptions.headers['Authorization']
          ?.toString()
          .replaceFirst('Bearer ', '');

      // If token in storage is already newer than the failed request token, retry immediately
      if (currentToken != null &&
          currentToken.isNotEmpty &&
          requestToken != null &&
          currentToken != requestToken) {
        try {
          final retriedResponse = await _retryRequest(err.requestOptions, currentToken);
          return handler.resolve(retriedResponse);
        } catch (e) {
          return handler.next(err);
        }
      }

      // 1. If another refresh is already in-flight, wait for it
      if (_refreshCompleter != null) {
        final newAccessToken = await _refreshCompleter!.future;
        if (newAccessToken != null) {
          try {
            final retriedResponse = await _retryRequest(err.requestOptions, newAccessToken);
            return handler.resolve(retriedResponse);
          } catch (e) {
            return handler.next(err);
          }
        }
        return handler.next(err);
      }

      // 2. Synchronously claim the refresh completer before any async gap
      final completer = Completer<String?>();
      _refreshCompleter = completer;

      try {
        final refreshToken = await _storageService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          _resetCompleter(completer);
          completer.complete(null);
          await _handleSessionExpired();
          return handler.next(err);
        }

        final refreshResponse = await _refreshDio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
          final data = refreshResponse.data as Map<String, dynamic>;
          final newAccessToken = data['accessToken'] as String;
          final newRefreshToken = data['refreshToken'] as String;

          await _storageService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );

          completer.complete(newAccessToken);
          _resetCompleter(completer);

          final retriedResponse = await _retryRequest(err.requestOptions, newAccessToken);
          return handler.resolve(retriedResponse);
        } else {
          _resetCompleter(completer);
          completer.complete(null);
          await _handleSessionExpired();
          return handler.next(err);
        }
      } catch (e) {
        _resetCompleter(completer);
        completer.complete(null);
        await _handleSessionExpired();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  void _resetCompleter(Completer<String?> completer) {
    scheduleMicrotask(() {
      if (_refreshCompleter == completer) {
        _refreshCompleter = null;
      }
    });
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newAccessToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $newAccessToken',
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
    );

    return _refreshDio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _handleSessionExpired() async {
    await _storageService.clearTokens();
    _onSessionExpired?.call();
  }
}
