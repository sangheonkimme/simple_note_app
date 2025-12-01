import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novita/src/features/auth/domain/user_model.dart';

abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> register(String email, String password, String nickname);
  Future<void> googleLogin();
  Future<void> logout();
  Future<User?> checkAuth();
  Future<void> loginAsGuest();
  Future<bool> isGuest();
}

class MockAuthRepository implements AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    // Mock success - Create a mock user
    final user = User(
      id: 'mock_user_id',
      email: email,
      displayName: 'Mock User',
    );
    await _saveUser(user);
  }

  @override
  Future<void> register(String email, String password, String nickname) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock success
    final user = User(
      id: 'mock_user_id',
      email: email,
      displayName: nickname,
    );
    await _saveUser(user);
  }

  @override
  Future<void> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // In real app: Get auth headers and send to backend
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final user = User(
        id: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoURL: googleUser.photoUrl,
      );

      await _saveUser(user);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'user_data');
    await _googleSignIn.signOut();
  }

  @override
  Future<User?> checkAuth() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> loginAsGuest() async {
    await _storage.write(key: 'access_token', value: 'guest_token');
  }

  @override
  Future<bool> isGuest() async {
    final token = await _storage.read(key: 'access_token');
    return token == 'guest_token';
  }

  Future<void> _saveUser(User user) async {
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
  }
}
