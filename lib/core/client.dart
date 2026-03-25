import 'package:dio/dio.dart';

import '../generated/api/auth_api.dart';
import '../generated/api/user_api.dart';
import '../modules/auth/auth_client.dart';
import '../modules/user/user_client.dart';
import 'config.dart';
import 'interceptor.dart';
import 'token_refresh_interceptor.dart';

/// DI 및 테스트에서 [NestClient]와 [MockNestClient]를 교체할 수 있게 하는 인터페이스.
///
/// 사용 예 (의존성 주입):
/// ```dart
/// class MyRepository {
///   final NestClientBase _api;
///   MyRepository(this._api);
/// }
///
/// // 프로덕션
/// MyRepository(NestClient('https://api.example.com'));
///
/// // 테스트
/// MyRepository(MockNestClient());
/// ```
abstract class NestClientBase {
  UserClientBase get users;
  AuthClientBase get auth;
  void setToken(String? token);
  void setRefreshToken(String? token);
  String? get currentToken;
  String? get currentRefreshToken;
}

/// flutter_nest_nexus_client의 진입점 (Facade 패턴).
///
/// 기본 사용법:
/// ```dart
/// final api = NestClient('https://api.example.com', token: 'your-token');
/// final users = await api.users.get();
/// ```
///
/// 설정 파일 사용:
/// ```dart
/// final api = await NestClient.fromConfig('assets/config.json');
/// ```
///
/// 로그인 후 토큰 업데이트:
/// ```dart
/// final auth = await api.auth.login('email@example.com', 'password');
/// api.setToken(auth.accessToken);
/// api.setRefreshToken(auth.refreshToken);
/// ```
class NestClient extends NestClientBase {
  final UserClient users;
  final AuthClient auth;

  final AuthInterceptor _authInterceptor;
  final TokenRefreshInterceptor? _refreshInterceptor;

  NestClient._({
    required this.users,
    required this.auth,
    required AuthInterceptor authInterceptor,
    TokenRefreshInterceptor? refreshInterceptor,
  })  : _authInterceptor = authInterceptor,
        _refreshInterceptor = refreshInterceptor;

  /// 직접 생성.
  ///
  /// [baseUrl] NestJS API 서버 기본 URL
  /// [token] 초기 access token (선택)
  /// [refreshToken] 초기 refresh token (선택). 설정 시 자동 갱신 활성화.
  /// [refreshEndpoint] 토큰 갱신 엔드포인트 (기본: '/auth/refresh')
  /// [enableLog] 요청/응답 로깅 활성화 여부
  factory NestClient(
    String baseUrl, {
    String? token,
    String? refreshToken,
    String refreshEndpoint = '/auth/refresh',
    bool enableLog = false,
  }) {
    return _build(NestConfig(
      baseUrl: baseUrl,
      token: token,
      refreshToken: refreshToken,
      refreshEndpoint: refreshEndpoint,
      enableLog: enableLog,
    ));
  }

  /// JSON 설정 파일에서 NestClient 생성.
  ///
  /// 경로 분기:
  /// - `/`로 시작하거나 `X:\`(Windows 드라이브) → 파일 시스템
  /// - 나머지 → Flutter assets (pubspec.yaml에 등록 필요)
  static Future<NestClient> fromConfig(String path) async {
    final config = _isAbsolutePath(path)
        ? await NestConfig.fromFile(path)
        : await NestConfig.fromAsset(path);
    return _build(config);
  }

  static bool _isAbsolutePath(String path) {
    return path.startsWith('/') || RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path);
  }

  static NestClient _build(NestConfig config) {
    final authInterceptor = AuthInterceptor(initialToken: config.token);

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    TokenRefreshInterceptor? refreshInterceptor;

    // refresh token이 설정된 경우에만 자동 갱신 인터셉터 등록
    if (config.refreshToken != null) {
      refreshInterceptor = TokenRefreshInterceptor(
        dio: dio,
        authInterceptor: authInterceptor,
        refreshEndpoint: config.refreshEndpoint,
        refreshToken: config.refreshToken,
      );
    }

    // 인터셉터 체인: Auth → (Refresh) → Error → (Log)
    dio.interceptors.add(authInterceptor);
    if (refreshInterceptor != null) {
      dio.interceptors.add(refreshInterceptor);
    }
    dio.interceptors.add(ErrorInterceptor());
    if (config.enableLog) {
      dio.interceptors.add(NestLogInterceptor());
    }

    final userApi = UserApi(dio);
    final authApi = AuthApi(dio);

    return NestClient._(
      users: UserClient(userApi),
      auth: AuthClient(authApi),
      authInterceptor: authInterceptor,
      refreshInterceptor: refreshInterceptor,
    );
  }

  /// 런타임 access token 업데이트.
  /// 로그인 성공 후 즉시 호출하여 이후 모든 요청에 새 토큰을 사용.
  void setToken(String? token) => _authInterceptor.token = token;

  /// 런타임 refresh token 업데이트.
  void setRefreshToken(String? token) {
    _refreshInterceptor?.refreshToken = token;
  }

  /// 현재 access token.
  String? get currentToken => _authInterceptor.token;

  /// 현재 refresh token.
  String? get currentRefreshToken => _refreshInterceptor?.refreshToken;
}
