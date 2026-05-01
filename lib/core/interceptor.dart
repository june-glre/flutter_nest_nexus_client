import 'dart:developer' as dev;

import 'package:dio/dio.dart';

import 'exception.dart';

/// Bearer 토큰을 모든 요청 헤더에 자동 삽입.
/// setToken()으로 런타임 업데이트 가능.
class AuthInterceptor extends Interceptor {
  String? _token;

  AuthInterceptor({String? initialToken}) : _token = initialToken;

  String? get token => _token;
  set token(String? value) => _token = value;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_token != null) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }
}

/// 요청/응답 로깅 인터셉터.
/// NestClient 생성 시 enableLog=true 로 활성화.
class NestLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dev.log('--> ${options.method} ${options.path}', name: 'NestClient');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dev.log(
      '<-- ${response.statusCode} ${response.requestOptions.path}',
      name: 'NestClient',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      'ERROR ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}',
      name: 'NestClient',
    );
    handler.next(err);
  }
}

/// DioException을 ApiException으로 변환.
/// 인터셉터 체인에서 마지막에 등록되어 모든 에러를 처리.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TokenRefreshInterceptor가 이미 처리한 ApiException은 재변환하지 않음
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final apiException = _convert(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        type: err.type,
        response: err.response,
        message: apiException.message,
      ),
    );
  }

  ApiException _convert(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: err.message ?? 'Network error',
        originalError: err,
      );
    }

    final statusCode = err.response?.statusCode;
    final message = _extractMessage(err.response);

    // 백엔드의 비즈니스 에러 코드(message가 anchor 역할)에 따라 specialized
    // exception을 우선 매핑한다. statusCode 기반 generic 매핑은 fallback.
    final specialized = _mapBusinessCode(message, err);
    if (specialized != null) return specialized;

    return switch (statusCode) {
      401 => UnauthorizedException(message: message, originalError: err),
      403 => ForbiddenException(message: message, originalError: err),
      404 => NotFoundException(message: message, originalError: err),
      int s when s >= 500 =>
        ServerException(statusCode: s, message: message, originalError: err),
      _ => UnknownApiException(message: message, originalError: err),
    };
  }

  /// 백엔드가 throw하는 의미적 코드(`RECEIPT_INVALID` 등)를 도메인 예외로 매핑.
  /// 본 SDK는 nest-nexus가 `BadRequestException('CODE')` 패턴으로 throw한다고
  /// 가정한다(HttpExceptionFilter가 message를 그대로 전달).
  ApiException? _mapBusinessCode(String message, DioException err) {
    if (message.contains('RECEIPT_INVALID')) {
      return ReceiptInvalidException(
        message: message,
        originalError: err,
      );
    }
    if (message.contains('PLAN_NOT_FOUND')) {
      return PlanNotFoundException(message: message, originalError: err);
    }
    if (message.contains('PRODUCT_PLATFORM_MISMATCH')) {
      return ProductPlatformMismatchException(
        message: message,
        originalError: err,
      );
    }
    return null;
  }

  String _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map) {
        final raw = data['message'];
        if (raw is List) {
          return raw.map((e) => e?.toString() ?? '').join('; ');
        }
        return raw?.toString() ?? 'Unknown error';
      }
    } catch (_) {}
    return 'Unknown error';
  }
}
