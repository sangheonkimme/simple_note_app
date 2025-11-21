import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> register(String email, String password, String nickname);
  Future<void> googleLogin();
  Future<void> logout();
  Future<bool> checkAuth();
  Future<void> loginAsGuest();
  Future<bool> isGuest();
}

class MockAuthRepository implements AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    // Mock success
    await _storage.write(key: 'access_token', value: 'mock_token');
  }

  @override
  Future<void> register(String email, String password, String nickname) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock success
    await _storage.write(key: 'access_token', value: 'mock_token');
  }

  @override
  Future<void> googleLogin() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User canceled

      // In real app: Get auth headers and send to backend
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      await Future.delayed(const Duration(seconds: 1));
      await _storage.write(key: 'access_token', value: 'mock_google_token');
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _googleSignIn.signOut();
  }

  @override
  Future<bool> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
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
}
