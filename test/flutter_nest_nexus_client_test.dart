import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_nest_nexus_client/flutter_nest_nexus_client.dart';
import 'package:flutter_nest_nexus_client/testing.dart';

void main() {
  // ─── Result 패턴 ──────────────────────────────────────────────────

  group('Result', () {
    test('success: isSuccess=true, data 반환', () {
      final r = Result.success(42);
      expect(r.isSuccess, true);
      expect(r.isFailure, false);
      expect(r.data, 42);
      expect(r.error, isNull);
    });

    test('failure: isFailure=true, error 반환', () {
      const e = NetworkException(message: 'timeout');
      final r = Result<int>.failure(e);
      expect(r.isFailure, true);
      expect(r.isSuccess, false);
      expect(r.error, isA<NetworkException>());
      expect(r.data, isNull);
    });

    test('fold: 성공 분기 실행', () {
      final r = Result.success('hello');
      final out = r.fold(
        onSuccess: (v) => v.length,
        onFailure: (_) => -1,
      );
      expect(out, 5);
    });

    test('fold: 실패 분기 실행', () {
      final r = Result<String>.failure(
        const NotFoundException(message: 'not found'),
      );
      final out = r.fold(
        onSuccess: (_) => 'ok',
        onFailure: (e) => e.message,
      );
      expect(out, 'not found');
    });

    test('toString: success 표현', () {
      final r = Result.success(1);
      expect(r.toString(), contains('success'));
    });

    test('toString: failure 표현', () {
      final r = Result<int>.failure(
        const UnauthorizedException(message: 'expired'),
      );
      expect(r.toString(), contains('expired'));
    });
  });

  // ─── ApiException 계층 ───────────────────────────────────────────

  group('ApiException', () {
    test('NetworkException: statusCode null', () {
      const e = NetworkException(message: 'no connection');
      expect(e.statusCode, isNull);
      expect(e.message, 'no connection');
    });

    test('UnauthorizedException: statusCode=401', () {
      const e = UnauthorizedException();
      expect(e.statusCode, 401);
    });

    test('ForbiddenException: statusCode=403', () {
      const e = ForbiddenException();
      expect(e.statusCode, 403);
    });

    test('NotFoundException: statusCode=404', () {
      const e = NotFoundException();
      expect(e.statusCode, 404);
    });

    test('ServerException: statusCode=500', () {
      const e = ServerException(statusCode: 500);
      expect(e.statusCode, 500);
    });

    test('toString 포함 statusCode', () {
      const e = ServerException(statusCode: 503);
      expect(e.toString(), contains('503'));
    });
  });

  // ─── PaginatedResult ─────────────────────────────────────────────

  group('PaginatedResult', () {
    test('hasMore: true (1/2 페이지)', () {
      final r = PaginatedResult(
        items: List.generate(20, (i) => i),
        total: 50,
        page: 1,
        limit: 20,
      );
      expect(r.hasMore, true);
      expect(r.totalPages, 3);
      expect(r.isFirstPage, true);
    });

    test('hasMore: false (마지막 페이지)', () {
      final r = PaginatedResult(
        items: List.generate(10, (i) => i),
        total: 30,
        page: 2,
        limit: 20,
      );
      expect(r.hasMore, false);
      expect(r.totalPages, 2);
      expect(r.isFirstPage, false);
    });

    test('empty() 팩토리', () {
      final r = PaginatedResult<int>.empty();
      expect(r.items, isEmpty);
      expect(r.total, 0);
      expect(r.hasMore, false);
    });

    test('totalPages: 경계값 (limit=0)', () {
      final r = PaginatedResult(
        items: const <int>[],
        total: 10,
        page: 1,
        limit: 0,
      );
      expect(r.totalPages, 0);
    });
  });

  // ─── NestConfig ───────────────────────────────────────────────────

  group('NestConfig', () {
    test('fromJson: 기본값 적용', () {
      final config = NestConfig.fromJson({'baseUrl': 'https://api.test.com'});
      expect(config.baseUrl, 'https://api.test.com');
      expect(config.token, isNull);
      expect(config.refreshToken, isNull);
      expect(config.refreshEndpoint, '/auth/refresh');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 30));
      expect(config.enableLog, false);
    });

    test('fromJson: 모든 필드 파싱', () {
      final config = NestConfig.fromJson({
        'baseUrl': 'https://api.test.com',
        'token': 'access-token',
        'refreshToken': 'refresh-token',
        'refreshEndpoint': '/v1/auth/refresh',
        'connectTimeoutMs': 5000,
        'receiveTimeoutMs': 15000,
        'enableLog': true,
      });
      expect(config.token, 'access-token');
      expect(config.refreshToken, 'refresh-token');
      expect(config.refreshEndpoint, '/v1/auth/refresh');
      expect(config.connectTimeout, const Duration(seconds: 5));
      expect(config.receiveTimeout, const Duration(seconds: 15));
      expect(config.enableLog, true);
    });

    test('default baseUrl: https://juny-api.kr', () {
      const config = NestConfig();
      expect(config.baseUrl, 'https://juny-api.kr');
      expect(config.baseUrl, NestConfig.defaultBaseUrl);
    });

    test('fromJson: baseUrl 누락 시 default 사용', () {
      final config = NestConfig.fromJson({'token': 'x'});
      expect(config.baseUrl, NestConfig.defaultBaseUrl);
      expect(config.token, 'x');
    });
  });

  // ─── NestClient ───────────────────────────────────────────────────

  group('NestClient', () {
    test('factory 생성: 토큰 설정', () {
      final client = NestClient.withUrl('https://api.test.com', token: 'abc');
      expect(client.currentToken, 'abc');
    });

    test('factory 생성: 토큰 없음', () {
      final client = NestClient.withUrl('https://api.test.com');
      expect(client.currentToken, isNull);
    });

    test('setToken: 런타임 업데이트', () {
      final client = NestClient.withUrl('https://api.test.com');
      client.setToken('new-token');
      expect(client.currentToken, 'new-token');
    });

    test('setToken: null로 초기화', () {
      final client = NestClient.withUrl('https://api.test.com', token: 'abc');
      client.setToken(null);
      expect(client.currentToken, isNull);
    });

    test('setRefreshToken: 토큰이 설정된 경우만 동작', () {
      // refreshToken 없이 생성 → _refreshInterceptor=null → setRefreshToken no-op
      final client = NestClient.withUrl('https://api.test.com', token: 'abc');
      client.setRefreshToken('new-refresh'); // 예외 없이 실행되어야 함
      expect(client.currentRefreshToken, isNull);
    });

    test('users / auth 접근 가능', () {
      final client = NestClient.withUrl('https://api.test.com');
      expect(client.users, isNotNull);
      expect(client.auth, isNotNull);
    });

    test('default factory: baseUrl 미지정 → juny-api.kr', () {
      // 기본 factory는 default base URL을 사용한다.
      final client = NestClient(token: 'tk');
      expect(client.currentToken, 'tk');
      // 내부 baseUrl을 직접 노출하지는 않으므로 동작 검증은 통합 테스트로 분리.
    });
  });

  // ─── MockNestClient ───────────────────────────────────────────────

  group('MockNestClient', () {
    test('MockUserClient: mockUsers 반환', () async {
      final mock = MockNestClient();
      mock.users.mockUsers = [
        User(id: '1', email: 'a@test.com', name: 'Alice', createdAt: DateTime(2024)),
        User(id: '2', email: 'b@test.com', name: 'Bob', createdAt: DateTime(2024)),
      ];

      final users = await mock.users.get();
      expect(users.length, 2);
      expect(users.first.name, 'Alice');
    });

    test('MockUserClient: mockError throw', () async {
      final mock = MockNestClient();
      mock.users.mockError = const NetworkException(message: 'offline');

      expect(() => mock.users.get(), throwsA(isA<NetworkException>()));
    });

    test('MockUserClient: getSafe — 에러를 Result.failure로 반환', () async {
      final mock = MockNestClient();
      mock.users.mockError = const ServerException(statusCode: 500);

      final result = await mock.users.getSafe();
      expect(result.isFailure, true);
      expect(result.error, isA<ServerException>());
    });

    test('MockUserClient: getPaginated', () async {
      final mock = MockNestClient();
      mock.users.mockUsers = List.generate(
        25,
        (i) => User(id: '$i', email: '$i@test.com', name: 'User$i', createdAt: DateTime(2024)),
      );

      final page1 = await mock.users.getPaginated(page: 1, limit: 10);
      expect(page1.items.length, 10);
      expect(page1.total, 25);
      expect(page1.hasMore, true);

      final page3 = await mock.users.getPaginated(page: 3, limit: 10);
      expect(page3.items.length, 5);
      expect(page3.hasMore, false);
    });

    test('MockAuthClient: login 기본 응답', () async {
      final mock = MockNestClient();
      final auth = await mock.auth.login('test@test.com', 'pass');
      expect(auth.accessToken, isNotEmpty);
      expect(auth.user.email, 'test@test.com');
    });

    test('MockNestClient: setToken', () {
      final mock = MockNestClient();
      mock.setToken('abc');
      expect(mock.currentToken, 'abc');
    });
  });
}
