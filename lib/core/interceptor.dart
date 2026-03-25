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

    return switch (statusCode) {
      401 => UnauthorizedException(message: message, originalError: err),
      403 => ForbiddenException(message: message, originalError: err),
      404 => NotFoundException(message: message, originalError: err),
      int s when s >= 500 =>
        ServerException(statusCode: s, message: message, originalError: err),
      _ => UnknownApiException(message: message, originalError: err),
    };
  }

  String _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map) {
        return data['message']?.toString() ?? 'Unknown error';
      }
    } catch (_) {}
    return 'Unknown error';
  }
}
