import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:novita/src/core/exceptions.dart';

/// Global error handler utility
class ErrorHandler {
  ErrorHandler._();

  /// Convert any error to user-friendly message
  static String getMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    return '알 수 없는 오류가 발생했습니다';
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '요청 시간이 초과되었습니다';
      case DioExceptionType.connectionError:
        return '인터넷 연결을 확인해주세요';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (data is Map<String, dynamic>) {
          final message = data['message'] as String?;
          if (message != null) return message;
        }

        switch (statusCode) {
          case 400:
            return '잘못된 요청입니다';
          case 401:
            return '인증이 필요합니다';
          case 403:
            return '접근 권한이 없습니다';
          case 404:
            return '요청한 리소스를 찾을 수 없습니다';
          case 409:
            return '이미 존재하는 데이터입니다';
          case 500:
          case 502:
          case 503:
            return '서버 오류가 발생했습니다';
          default:
            return '오류가 발생했습니다 (코드: $statusCode)';
        }
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다';
      default:
        return '네트워크 오류가 발생했습니다';
    }
  }
}

/// Extension for showing errors easily in BuildContext
extension ErrorHandlerExtension on BuildContext {
  void showError(Object error) {
    final message = ErrorHandler.getMessage(error);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
