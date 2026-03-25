/// API 에러의 기반 클래스. 모든 SDK 예외는 이를 상속.
abstract class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic originalError;

  const ApiException({
    this.statusCode,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'ApiException[$statusCode]: $message';
}

/// 네트워크 연결 실패 또는 타임아웃.
class NetworkException extends ApiException {
  const NetworkException({required super.message, super.originalError})
      : super(statusCode: null);
}

/// 401 Unauthorized — 토큰 만료 또는 갱신 실패.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.originalError,
  }) : super(statusCode: 401);
}

/// 403 Forbidden — 권한 없음.
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Forbidden',
    super.originalError,
  }) : super(statusCode: 403);
}

/// 404 Not Found.
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Not Found',
    super.originalError,
  }) : super(statusCode: 404);
}

/// 5xx 서버 에러.
class ServerException extends ApiException {
  const ServerException({
    required super.statusCode,
    super.message = 'Server Error',
    super.originalError,
  });
}

/// 알 수 없는 에러.
class UnknownApiException extends ApiException {
  const UnknownApiException({
    required super.message,
    super.originalError,
  }) : super(statusCode: null);
}
