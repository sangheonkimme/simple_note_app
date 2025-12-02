/// Base exception for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code});

  factory AuthException.invalidCredentials() =>
      const AuthException('이메일 또는 비밀번호가 일치하지 않습니다', code: 'INVALID_CREDENTIALS');

  factory AuthException.emailAlreadyExists() =>
      const AuthException('이미 사용 중인 이메일입니다', code: 'EMAIL_ALREADY_EXISTS');

  factory AuthException.googleSignInCancelled() =>
      const AuthException('Google 로그인이 취소되었습니다', code: 'GOOGLE_SIGNIN_CANCELLED');

  factory AuthException.googleSignInFailed() =>
      const AuthException('Google 로그인에 실패했습니다', code: 'GOOGLE_SIGNIN_FAILED');

  factory AuthException.tokenExpired() =>
      const AuthException('세션이 만료되었습니다. 다시 로그인해주세요', code: 'TOKEN_EXPIRED');

  factory AuthException.tokenRevoked() =>
      const AuthException('인증이 취소되었습니다. 다시 로그인해주세요', code: 'TOKEN_REVOKED');

  factory AuthException.refreshTokenMissing() =>
      const AuthException('리프레시 토큰이 없습니다', code: 'REFRESH_TOKEN_MISSING');

  factory AuthException.unauthorized() =>
      const AuthException('인증이 필요합니다', code: 'UNAUTHORIZED');
}

/// Sync related exceptions
class SyncException extends AppException {
  const SyncException(super.message, {super.code});

  factory SyncException.syncFailed() =>
      const SyncException('동기화에 실패했습니다', code: 'SYNC_FAILED');

  factory SyncException.invalidData() =>
      const SyncException('동기화 데이터가 올바르지 않습니다', code: 'INVALID_SYNC_DATA');

  factory SyncException.conflictDetected() =>
      const SyncException('데이터 충돌이 발생했습니다', code: 'CONFLICT_DETECTED');
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});

  factory ValidationException.invalidInput(String field) =>
      ValidationException('$field이(가) 올바르지 않습니다', code: 'INVALID_INPUT');

  factory ValidationException.requiredField(String field) =>
      ValidationException('$field은(는) 필수 항목입니다', code: 'REQUIRED_FIELD');
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});

  factory NetworkException.noConnection() =>
      const NetworkException('인터넷 연결을 확인해주세요', code: 'NO_CONNECTION');

  factory NetworkException.timeout() =>
      const NetworkException('요청 시간이 초과되었습니다', code: 'TIMEOUT');

  factory NetworkException.serverError() =>
      const NetworkException('서버 오류가 발생했습니다', code: 'SERVER_ERROR');
}

/// Resource not found exception
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});

  factory NotFoundException.note() =>
      const NotFoundException('메모를 찾을 수 없습니다', code: 'NOTE_NOT_FOUND');

  factory NotFoundException.folder() =>
      const NotFoundException('폴더를 찾을 수 없습니다', code: 'FOLDER_NOT_FOUND');
}
