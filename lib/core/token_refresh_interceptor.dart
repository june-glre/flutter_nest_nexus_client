import 'dart:convert';

import 'package:dio/dio.dart';

import 'exception.dart';
import 'interceptor.dart';

/// 401 응답 시 자동으로 토큰을 갱신하고 원래 요청을 재시도.
///
/// 동작 흐름:
/// 1. 401 응답 수신
/// 2. refreshEndpoint로 POST 요청 (refreshToken 포함)
/// 3. 성공: 새 accessToken으로 AuthInterceptor 업데이트 → 원래 요청 재시도
/// 4. 실패: UnauthorizedException throw
///
/// 동시에 여러 401이 발생하면 하나만 refresh를 시도하고
/// 나머지는 대기 큐에서 갱신 완료 후 재시도.
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final AuthInterceptor _authInterceptor;
  final String refreshEndpoint;

  String? _refreshToken;
  bool _isRefreshing = false;
  final _pendingHandlers = <_PendingRequest>[];

  TokenRefreshInterceptor({
    required Dio dio,
    required AuthInterceptor authInterceptor,
    required String refreshEndpoint,
    String? refreshToken,
  })  : _dio = dio,
        _authInterceptor = authInterceptor,
        this.refreshEndpoint = refreshEndpoint,
        _refreshToken = refreshToken;

  String? get refreshToken => _refreshToken;
  set refreshToken(String? value) => _refreshToken = value;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // refresh 요청 자체는 재귀 처리하지 않음 (무한 루프 방지)
    if (err.requestOptions.extra['skipRefresh'] == true) {
      handler.next(err);
      return;
    }

    if (err.response?.statusCode != 401 || _refreshToken == null) {
      handler.next(err);
      return;
    }

    // 이미 refresh 진행 중이면 대기 큐에 추가
    if (_isRefreshing) {
      _pendingHandlers.add(_PendingRequest(err.requestOptions, handler));
      return;
    }

    _isRefreshing = true;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        refreshEndpoint,
        data: {'refreshToken': _refreshToken},
        options: Options(
          // refresh 요청 자체는 인터셉터를 통하지 않음 (무한 루프 방지)
          extra: {'skipRefresh': true},
        ),
      );

      // response.data는 Map (Dio JSON responseType) 또는 String (mock 환경)일 수 있음
      final responseMap = _toMap(response.data);
      final newAccessToken = responseMap?['accessToken'] as String?;
      final newRefreshToken = responseMap?['refreshToken'] as String?;

      if (newAccessToken == null) {
        _failAll(err);
        return;
      }

      // 토큰 업데이트
      _authInterceptor.token = newAccessToken;
      if (newRefreshToken != null) _refreshToken = newRefreshToken;

      // 원래 요청 재시도
      final retried = await _retry(err.requestOptions);
      handler.resolve(retried);

      // 대기 중인 요청들도 재시도
      for (final pending in _pendingHandlers) {
        try {
          final retriedPending = await _retry(pending.options);
          pending.handler.resolve(retriedPending);
        } catch (e) {
          pending.handler.next(err);
        }
      }
    } catch (_) {
      _failAll(err);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(
            message: 'Token refresh failed',
          ),
          type: DioExceptionType.badResponse,
        ),
      );
    } finally {
      _pendingHandlers.clear();
      _isRefreshing = false;
    }
  }

  /// response.data를 Map으로 변환. String이면 JSON 디코딩, 그 외는 null.
  static Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  void _failAll(DioException err) {
    for (final pending in _pendingHandlers) {
      pending.handler.next(err);
    }
  }

  Future<Response> _retry(RequestOptions options) {
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        // 재시도 요청은 다시 refresh를 트리거하지 않음.
        // 토큰 갱신 직후 다시 401이 오면 재시도이므로 재갱신 불필요.
        extra: {
          ...options.extra,
          'skipRefresh': true,
        },
        headers: {
          ...options.headers,
          'Authorization': 'Bearer ${_authInterceptor.token}',
        },
      ),
    );
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest(this.options, this.handler);
}
