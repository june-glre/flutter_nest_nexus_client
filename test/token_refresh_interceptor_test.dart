import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_nest_nexus_client/core/exception.dart';
import 'package:flutter_nest_nexus_client/core/interceptor.dart';
import 'package:flutter_nest_nexus_client/core/token_refresh_interceptor.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late AuthInterceptor authInterceptor;
  late TokenRefreshInterceptor refreshInterceptor;

  const refreshEndpoint = '/auth/refresh';
  const initialToken = 'access-token-initial';
  const refreshToken = 'refresh-token-initial';

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    adapter = DioAdapter(dio: dio);

    authInterceptor = AuthInterceptor(initialToken: initialToken);
    refreshInterceptor = TokenRefreshInterceptor(
      dio: dio,
      authInterceptor: authInterceptor,
      refreshEndpoint: refreshEndpoint,
      refreshToken: refreshToken,
    );

    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(refreshInterceptor);
    dio.interceptors.add(ErrorInterceptor());
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 1. refreshToken=null → 401 pass-through (갱신 시도 안 함)
  // ──────────────────────────────────────────────────────────────────────────

  test('refreshToken=null → 401 그대로 전파', () async {
    final noRefreshDio = Dio(BaseOptions(baseUrl: 'https://api.test.com'));
    final noRefreshAdapter = DioAdapter(dio: noRefreshDio);

    final auth = AuthInterceptor(initialToken: initialToken);
    final noRefresh = TokenRefreshInterceptor(
      dio: noRefreshDio,
      authInterceptor: auth,
      refreshEndpoint: refreshEndpoint,
      refreshToken: null, // refresh token 없음
    );

    noRefreshDio.interceptors.addAll([auth, noRefresh, ErrorInterceptor()]);

    noRefreshAdapter.onGet(
      '/protected',
      (server) => server.reply(401, {'message': 'Unauthorized'}),
    );

    expect(
      () => noRefreshDio.get('/protected'),
      throwsA(
        predicate((e) =>
            e is DioException && e.error is UnauthorizedException),
      ),
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 2. skipRefresh=true 요청의 401 → pass-through (무한 루프 방지)
  // ──────────────────────────────────────────────────────────────────────────

  test('skipRefresh=true인 요청의 401 → 인터셉터 통과 (무한 루프 방지)', () async {
    adapter.onPost(
      refreshEndpoint,
      (server) => server.reply(401, {'message': 'Refresh token expired'}),
      data: {'refreshToken': refreshToken},
    );

    // skipRefresh=true로 직접 POST 요청 → ErrorInterceptor로 전달됨
    expect(
      () => dio.post<Map<String, dynamic>>(
        refreshEndpoint,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipRefresh': true}),
      ),
      throwsA(
        predicate((e) =>
            e is DioException && e.error is UnauthorizedException),
      ),
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 3. refresh 성공 → 새 토큰 저장
  //    (retry 성공 여부와 무관하게, refresh 완료 직후 토큰이 업데이트되는지 검증)
  // ──────────────────────────────────────────────────────────────────────────

  test('401 후 refresh 성공 → 새 accessToken과 refreshToken 저장', () async {
    const newAccessToken = 'new-access-token';
    const newRefreshToken = 'new-refresh-token';

    // 최초 GET /protected → 401
    adapter.onGet(
      '/protected',
      (server) => server.reply(401, {}),
    );

    // refresh 성공 — data matcher 필수 (body 있는 POST 매칭)
    adapter.onPost(
      refreshEndpoint,
      (server) => server.reply(200, {
        'accessToken': newAccessToken,
        'refreshToken': newRefreshToken,
      }),
      data: {'refreshToken': refreshToken},
    );

    // retry는 mock 없음:
    // _retry()가 skipRefresh:true로 실패 → catch → handler.reject
    // 단, token update는 _retry() 호출 이전에 완료됨
    try {
      await dio.get<Map<String, dynamic>>('/protected');
    } catch (_) {
      // retry 실패로 인한 UnauthorizedException — 무시
    }

    // refresh 완료 후 토큰이 업데이트되었는지 검증
    expect(authInterceptor.token, newAccessToken);
    expect(refreshInterceptor.refreshToken, newRefreshToken);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 4. refresh 실패 → UnauthorizedException throw
  // ──────────────────────────────────────────────────────────────────────────

  test('refresh 엔드포인트 실패 → UnauthorizedException throw', () async {
    // 원래 요청: 401
    adapter.onGet(
      '/protected',
      (server) => server.reply(401, {'message': 'Unauthorized'}),
    );

    // refresh 실패 (예: 서버 에러)
    adapter.onPost(
      refreshEndpoint,
      (server) => server.reply(500, {'message': 'Server error'}),
      data: {'refreshToken': refreshToken},
    );

    expect(
      () => dio.get('/protected'),
      throwsA(
        predicate((e) {
          if (e is! DioException) return false;
          return e.error is UnauthorizedException &&
              (e.error as UnauthorizedException).message ==
                  'Token refresh failed';
        }),
      ),
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // 5. refreshToken setter 동작 확인
  // ──────────────────────────────────────────────────────────────────────────

  test('refreshToken setter: 런타임 업데이트', () {
    expect(refreshInterceptor.refreshToken, refreshToken);
    refreshInterceptor.refreshToken = 'updated-refresh-token';
    expect(refreshInterceptor.refreshToken, 'updated-refresh-token');
    refreshInterceptor.refreshToken = null;
    expect(refreshInterceptor.refreshToken, isNull);
  });
}
