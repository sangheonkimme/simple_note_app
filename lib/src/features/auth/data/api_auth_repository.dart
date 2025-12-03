import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novita/src/core/constants.dart';
import 'package:novita/src/core/exceptions.dart';
import 'package:novita/src/data/datasources/local/token_storage.dart';
import 'package:novita/src/features/auth/data/auth_repository.dart';
import 'package:novita/src/features/auth/domain/user_model.dart';

/// Production implementation of AuthRepository using real API
class ApiAuthRepository implements AuthRepository {
  final Dio dio;
  final TokenStorage tokenStorage;
  final GoogleSignIn googleSignIn;

  ApiAuthRepository({
    required this.dio,
    required this.tokenStorage,
    GoogleSignIn? googleSignIn,
  }) : googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             serverClientId:
                 '1025837073515-0gg891802fmkglbfuqg99j3138l8f86h.apps.googleusercontent.com',
           );

  @override
  Future<void> login(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storeAuthData(data);
      } else {
        throw AuthException.invalidCredentials();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException.invalidCredentials();
      }
      rethrow;
    }
  }

  @override
  Future<void> register(String email, String password, String name) async {
    try {
      final response = await dio.post(
        AppConstants.registerEndpoint,
        data: {'email': email, 'password': password, 'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await _storeAuthData(data);
      } else {
        throw const AuthException('회원가입에 실패했습니다');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data as Map<String, dynamic>?;
        final message = data?['message'] as String? ?? '잘못된 입력입니다';
        throw AuthException(message);
      }
      if (e.response?.statusCode == 409) {
        throw AuthException.emailAlreadyExists();
      }
      rethrow;
    }
  }

  @override
  Future<void> googleLogin() async {
    try {
      debugPrint('Starting Google Sign-In...');

      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user');
        throw AuthException.googleSignInCancelled();
      }

      debugPrint('Google user obtained: ${googleUser.email}');

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;

      debugPrint('ID Token obtained: ${idToken?.substring(0, 20)}...');

      if (idToken == null) {
        debugPrint('Failed to get Google ID token');
        throw AuthException.googleSignInFailed();
      }

      // Step 3: Send credential to backend for verification
      debugPrint('Sending credential to backend...');
      final response = await dio.post(
        AppConstants.googleLoginEndpoint,
        data: {'credential': idToken},
      );

      debugPrint('Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storeAuthData(data);
        debugPrint('Google login successful!');
      } else {
        debugPrint('Backend returned: ${response.statusCode}');
        throw AuthException.googleSignInFailed();
      }
    } on AuthException {
      debugPrint('Auth exception caught');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Google login error: $error');
      debugPrint('Stack trace: $stackTrace');
      throw AuthException.googleSignInFailed();
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Try to notify server about logout (don't fail if it errors)
      try {
        await dio.post(AppConstants.logoutEndpoint);
      } catch (e) {
        // Ignore server errors during logout
      }

      // Clear local data
      await tokenStorage.clearTokens();
      await googleSignIn.signOut();
    } catch (e) {
      // Even if something fails, clear tokens
      await tokenStorage.clearTokens();
    }
  }

  @override
  Future<User?> checkAuth() async {
    try {
      final hasTokens = await tokenStorage.hasValidTokens();

      if (!hasTokens) {
        return null;
      }

      // Try to get user info from server to verify token is still valid
      final response = await dio.get(AppConstants.meEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Handle wrapped response: {success, data: {user}}
        final userData = data['data'] as Map<String, dynamic>? ?? data;
        return User.fromJson(userData);
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token invalid, clear it
        await tokenStorage.clearTokens();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> loginAsGuest() async {
    // Guest mode - just clear any existing tokens
    await tokenStorage.clearTokens();
  }

  @override
  Future<bool> isGuest() async {
    final hasTokens = await tokenStorage.hasValidTokens();
    return !hasTokens;
  }

  /// Store authentication data from server response
  Future<void> _storeAuthData(Map<String, dynamic> data) async {
    // Handle wrapped response: {success, message, data: {user, accessToken, refreshToken?}}
    final authData = data['data'] as Map<String, dynamic>? ?? data;

    final accessToken = authData['accessToken'] as String?;
    final refreshToken = authData['refreshToken'] as String?;
    final userId = authData['user']?['id'] as String?;

    if (accessToken == null) {
      throw const AuthException('Invalid authentication response');
    }

    // Use accessToken as refreshToken if not provided (some auth systems do this)
    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken ?? accessToken,
    );

    if (userId != null) {
      await tokenStorage.saveUserId(userId);
    }
  }
}
