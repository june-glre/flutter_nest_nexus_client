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

// ─── Subscription / IAP 도메인 예외 ────────────────────────────────

/// 백엔드가 IAP 영수증을 거절한 경우. 영수증이 위변조되었거나, 환불됐거나,
/// 만료된 경우 발생. 사용자에게는 "결제를 다시 시도해주세요" 정도 메시지가 적합.
///
/// 매핑 규칙: HTTP 400 + 응답 `message` 또는 server `code` 가 `RECEIPT_INVALID`.
class ReceiptInvalidException extends ApiException {
  const ReceiptInvalidException({
    super.message = 'Receipt invalid',
    super.originalError,
  }) : super(statusCode: 400);
}

/// 백엔드의 Plan 카탈로그에 일치하는 productId가 없는 경우. 클라이언트가
/// 관리되지 않는 productId로 verify를 시도했거나, 백엔드 plan 등록이 누락됐을 때.
///
/// 매핑 규칙: HTTP 404 + 응답 `message` 또는 server `code` 가 `PLAN_NOT_FOUND`.
class PlanNotFoundException extends ApiException {
  const PlanNotFoundException({
    super.message = 'Plan not found',
    super.originalError,
  }) : super(statusCode: 404);
}

/// 활성 구독을 찾을 수 없을 때. me/restore 응답이 free tier로 정규화되어 오므로
/// 실사용에서는 거의 발생하지 않으며, 명시적으로 활성 구독을 찾는 호출에서만 발생.
class SubscriptionNotFoundException extends ApiException {
  const SubscriptionNotFoundException({
    super.message = 'Subscription not found',
    super.originalError,
  }) : super(statusCode: 404);
}

/// 클라이언트가 보낸 platform과 productId의 등록된 plan이 다른 플랫폼 컬럼에만
/// 매핑된 경우(예: 안드로이드인데 iOS productId 전달). 클라이언트 버그.
class ProductPlatformMismatchException extends ApiException {
  const ProductPlatformMismatchException({
    super.message = 'Product platform mismatch',
    super.originalError,
  }) : super(statusCode: 400);
}
