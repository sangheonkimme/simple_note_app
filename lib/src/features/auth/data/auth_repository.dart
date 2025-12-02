import 'package:novita/src/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> register(String email, String password, String name);
  Future<void> googleLogin();
  Future<void> logout();
  Future<User?> checkAuth();
  Future<void> loginAsGuest();
  Future<bool> isGuest();
}
