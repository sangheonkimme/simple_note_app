import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:novita/src/core/constants.dart';
import 'package:novita/src/data/datasources/local/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio dio;

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          final opts = err.requestOptions;
          final token = await tokenStorage.getAccessToken();
          opts.headers['Authorization'] = 'Bearer $token';

          final response = await dio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }

      // Clear tokens and propagate error
      await tokenStorage.clearTokens();
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'refreshToken=$refreshToken',
        },
      )).post(AppConstants.refreshTokenEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final authData = data['data'] as Map<String, dynamic>? ?? data;
        final newAccessToken = authData['accessToken'] as String?;

        if (newAccessToken != null) {
          await tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return false;
    }
  }
}
