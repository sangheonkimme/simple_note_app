import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/network/dio_provider.dart';
import 'package:novita/src/features/auth/data/api_auth_repository.dart';
import 'package:novita/src/features/auth/data/auth_repository.dart';
import 'package:novita/src/features/auth/domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiAuthRepository(
    dio: dio,
    tokenStorage: tokenStorage,
  );
});

final authStateProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = await _authRepository.checkAuth();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.login(email, password);
      final user = await _authRepository.checkAuth();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.register(email, password, name);
      final user = await _authRepository.checkAuth();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> googleLogin() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.googleLogin();
      final user = await _authRepository.checkAuth();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loginAsGuest() async {
    await _authRepository.loginAsGuest();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    await _checkAuth();
  }
}
