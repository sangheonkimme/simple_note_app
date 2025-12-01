import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/features/auth/data/auth_repository.dart';
import 'package:novita/src/features/auth/domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.checkAuth();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.login(email, password);
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password, String nickname) async {
    state = const AsyncValue.loading();
    try {
      await _repository.register(email, password, nickname);
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> googleLogin() async {
    state = const AsyncValue.loading();
    try {
      await _repository.googleLogin();
      await checkAuth();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginAsGuest() async {
    state = const AsyncValue.loading();
    try {
      await _repository.loginAsGuest();
      // Guest is treated as null user for now, or we can create a guest user object
      // If we want to navigate to Home, we just need to stop loading.
      // But since Home is always visible, this just updates the state.
      state = const AsyncValue.data(null); 
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
