import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foodie_app/core/network/auth_interceptor.dart';
import 'package:foodie_app/core/storage/storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

class TestAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) fetchHandler;
  TestAdapter(this.fetchHandler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return fetchHandler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    when(() => mockStorageService.clearTokens()).thenAnswer((_) async {});
  });

  test('Attaches Bearer token to request header when token is present', () async {
    when(() => mockStorageService.getAccessToken())
        .thenAnswer((_) async => 'valid_access_token');

    RequestOptions? capturedOptions;

    final mainDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    mainDio.httpClientAdapter = TestAdapter((options) async {
      capturedOptions = options;
      return jsonResponse({'status': 'ok'}, 200);
    });

    mainDio.interceptors.add(
      AuthInterceptor(mockStorageService, null, mainDio),
    );

    await mainDio.get('/test');

    expect(capturedOptions?.headers['Authorization'], 'Bearer valid_access_token');
  });

  test('Refreshes token on 401 and retries original request', () async {
    String currentAccess = 'expired_access_token';
    when(() => mockStorageService.getAccessToken())
        .thenAnswer((_) async => currentAccess);
    when(() => mockStorageService.getRefreshToken())
        .thenAnswer((_) async => 'old_refresh_token');
    when(() => mockStorageService.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((invocation) async {
      currentAccess = invocation.namedArguments[#accessToken] as String;
    });

    int requestAttempts = 0;

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    refreshDio.httpClientAdapter = TestAdapter((options) async {
      if (options.path == '/auth/refresh') {
        return jsonResponse({
          'accessToken': 'new_access_token',
          'refreshToken': 'new_refresh_token',
        }, 200);
      }
      return jsonResponse({'data': 'success', 'auth': options.headers['Authorization']}, 200);
    });

    final mainDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    mainDio.httpClientAdapter = TestAdapter((options) async {
      requestAttempts++;
      if (requestAttempts == 1) {
        await Future.delayed(Duration.zero);
        return jsonResponse({'error': 'Unauthorized'}, 401);
      }
      return jsonResponse({'data': 'success', 'auth': options.headers['Authorization']}, 200);
    });

    mainDio.interceptors.add(
      AuthInterceptor(mockStorageService, null, refreshDio),
    );

    final response = await mainDio.get('/orders');

    expect(response.statusCode, 200);
    expect(response.data['data'], 'success');
    expect(response.data['auth'], 'Bearer new_access_token');
    verify(() => mockStorageService.saveTokens(
          accessToken: 'new_access_token',
          refreshToken: 'new_refresh_token',
        )).called(1);
  });

  test('Concurrent 401s cause exactly ONE refresh call', () async {
    int refreshCallCount = 0;

    String currentAccess = 'expired_access_token';
    when(() => mockStorageService.getAccessToken())
        .thenAnswer((_) async => currentAccess);
    when(() => mockStorageService.getRefreshToken())
        .thenAnswer((_) async => 'old_refresh_token');
    when(() => mockStorageService.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((invocation) async {
      currentAccess = invocation.namedArguments[#accessToken] as String;
    });

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    refreshDio.httpClientAdapter = TestAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCallCount++;
        await Future.delayed(const Duration(milliseconds: 20));
        return jsonResponse({
          'accessToken': 'new_access_token',
          'refreshToken': 'new_refresh_token',
        }, 200);
      }
      return jsonResponse({'path': options.path}, 200);
    });

    final Map<String, int> callCounts = {};

    final mainDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    mainDio.httpClientAdapter = TestAdapter((options) async {
      callCounts[options.path] = (callCounts[options.path] ?? 0) + 1;
      if (callCounts[options.path] == 1) {
        await Future.delayed(Duration.zero);
        return jsonResponse({'error': 'Unauthorized'}, 401);
      }
      return jsonResponse({'path': options.path}, 200);
    });

    mainDio.interceptors.add(
      AuthInterceptor(mockStorageService, null, refreshDio),
    );

    final responses = await Future.wait([
      mainDio.get('/orders/1'),
      mainDio.get('/orders/2'),
    ]);

    expect(responses[0].statusCode, 200);
    expect(responses[1].statusCode, 200);
    expect(refreshCallCount, equals(1));
  });

  test('Refresh failure clears tokens and notifies session expired', () async {
    bool sessionExpiredNotified = false;

    when(() => mockStorageService.getAccessToken())
        .thenAnswer((_) async => 'expired_access_token');
    when(() => mockStorageService.getRefreshToken())
        .thenAnswer((_) async => 'revoked_token');

    final refreshDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    refreshDio.httpClientAdapter = TestAdapter((options) async {
      return jsonResponse({'error': 'Invalid or expired refresh token'}, 401);
    });

    final mainDio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    mainDio.httpClientAdapter = TestAdapter((options) async {
      await Future.delayed(Duration.zero);
      return jsonResponse({'error': 'Unauthorized'}, 401);
    });

    mainDio.interceptors.add(
      AuthInterceptor(
        mockStorageService,
        () {
          sessionExpiredNotified = true;
        },
        refreshDio,
      ),
    );

    try {
      await mainDio.get('/orders');
    } catch (_) {}

    verify(() => mockStorageService.clearTokens()).called(1);
    expect(sessionExpiredNotified, isTrue);
  });
}
