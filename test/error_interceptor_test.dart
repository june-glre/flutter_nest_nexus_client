import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_nest_nexus_client/core/exception.dart';
import 'package:flutter_nest_nexus_client/core/interceptor.dart';

/// [ErrorInterceptor]가 DioException을 올바른 [ApiException] 서브타입으로
/// 변환하는지 검증.
void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    adapter = DioAdapter(dio: dio);
    dio.interceptors.add(ErrorInterceptor());
  });

  // HTTP 상태 코드별 예외 타입 검증 헬퍼
  Future<ApiException> fetchAndCapture(
    String path, {
    int statusCode = 500,
    Map<String, dynamic>? body,
  }) async {
    adapter.onGet(
      path,
      (server) => server.reply(statusCode, body ?? {}),
    );
    try {
      await dio.get<Map<String, dynamic>>(path);
      fail('예외가 발생해야 합니다');
    } on DioException catch (e) {
      return e.error as ApiException;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 타임아웃 → NetworkException
  // ──────────────────────────────────────────────────────────────────────────

  test('connectionTimeout → NetworkException', () {
    final timeoutDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    final timeoutAdapter = DioAdapter(dio: timeoutDio);
    timeoutDio.interceptors.add(ErrorInterceptor());

    timeoutAdapter.onGet(
      '/slow',
      (server) => server.throws(
        1,
        DioException(
          requestOptions: RequestOptions(path: '/slow'),
          type: DioExceptionType.connectionTimeout,
        ),
      ),
    );

    expect(
      () => timeoutDio.get('/slow'),
      throwsA(
        predicate(
            (e) => e is DioException && e.error is NetworkException),
      ),
    );
  });

  test('receiveTimeout → NetworkException', () {
    final timeoutDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    final timeoutAdapter = DioAdapter(dio: timeoutDio);
    timeoutDio.interceptors.add(ErrorInterceptor());

    timeoutAdapter.onGet(
      '/slow',
      (server) => server.throws(
        1,
        DioException(
          requestOptions: RequestOptions(path: '/slow'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
    );

    expect(
      () => timeoutDio.get('/slow'),
      throwsA(
        predicate(
            (e) => e is DioException && e.error is NetworkException),
      ),
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // HTTP 상태 코드 → 정확한 ApiException 서브타입
  // ──────────────────────────────────────────────────────────────────────────

  test('statusCode=401 → UnauthorizedException', () async {
    final e = await fetchAndCapture('/test', statusCode: 401);
    expect(e, isA<UnauthorizedException>());
    expect(e.statusCode, 401);
  });

  test('statusCode=403 → ForbiddenException', () async {
    final e = await fetchAndCapture('/test', statusCode: 403);
    expect(e, isA<ForbiddenException>());
    expect(e.statusCode, 403);
  });

  test('statusCode=404 → NotFoundException', () async {
    final e = await fetchAndCapture('/test', statusCode: 404);
    expect(e, isA<NotFoundException>());
    expect(e.statusCode, 404);
  });

  test('statusCode=500 → ServerException(statusCode: 500)', () async {
    final e = await fetchAndCapture('/test', statusCode: 500);
    expect(e, isA<ServerException>());
    expect(e.statusCode, 500);
  });

  test('statusCode=503 → ServerException(statusCode: 503)', () async {
    final e = await fetchAndCapture('/test', statusCode: 503);
    expect(e, isA<ServerException>());
    expect(e.statusCode, 503);
  });

  test('statusCode=422 → UnknownApiException', () async {
    final e = await fetchAndCapture('/test', statusCode: 422);
    expect(e, isA<UnknownApiException>());
  });

  // ──────────────────────────────────────────────────────────────────────────
  // response.data['message'] 파싱
  // ──────────────────────────────────────────────────────────────────────────

  test('response body에서 message 파싱', () async {
    final e = await fetchAndCapture(
      '/test',
      statusCode: 404,
      body: {'message': 'User not found'},
    );
    expect(e.message, 'User not found');
  });

  test('response body에 message 없으면 기본값 사용', () async {
    final e = await fetchAndCapture('/test', statusCode: 404, body: {});
    expect(e.message, 'Unknown error');
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 이미 ApiException인 경우 재변환하지 않음
  // ──────────────────────────────────────────────────────────────────────────

  test('에러가 이미 ApiException이면 동일 예외 유지', () {
    // ApiException을 이미 담은 DioException이 ErrorInterceptor를 통과할 때
    // 재변환 없이 같은 타입으로 전달되는지 검증.
    const original = UnauthorizedException(message: 'already converted');

    // 에러를 주입하는 커스텀 인터셉터 + ErrorInterceptor 순서로 등록
    final testDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    final testAdapter = DioAdapter(dio: testDio);

    testDio.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) {
          // DioException에 ApiException을 미리 래핑해서 전달
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: original,
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    testDio.interceptors.add(ErrorInterceptor());

    testAdapter.onGet(
      '/test',
      (server) => server.reply(401, {}),
    );

    expect(
      () => testDio.get('/test'),
      throwsA(
        predicate((e) {
          if (e is! DioException) return false;
          final err = e.error;
          return err is UnauthorizedException &&
              err.message == 'already converted';
        }),
      ),
    );
  });
}
