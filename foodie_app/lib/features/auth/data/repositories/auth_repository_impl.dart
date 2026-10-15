import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_response.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _remoteDataSource.login(email, password);
    await _storageService.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<AuthResponse> register(String name, String email, String password) async {
    final response = await _remoteDataSource.register(name, email, password);
    await _storageService.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  @override
  Future<User> me() async {
    return await _remoteDataSource.me();
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _remoteDataSource.logout(refreshToken);
      } catch (_) {
        // Suppress server logout error if offline
      }
    }
    await _storageService.clearTokens();
  }

  @override
  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _remoteDataSource.refresh(refreshToken);
    await _storageService.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }
}
