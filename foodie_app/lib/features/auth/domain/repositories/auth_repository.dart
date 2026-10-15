import '../entities/user.dart';
import '../../data/models/auth_response.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String name, String email, String password);
  Future<User> me();
  Future<void> logout();
  Future<AuthResponse> refresh(String refreshToken);
}
