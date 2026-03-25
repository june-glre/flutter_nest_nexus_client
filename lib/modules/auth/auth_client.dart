import '../../generated/api/auth_api.dart';
import '../../generated/model/auth_dto.dart';
import '../../models/user.dart';

/// 토큰 갱신 결과 (사용자 정보 없음).
class RefreshResult {
  final String accessToken;
  final String? refreshToken;

  const RefreshResult({
    required this.accessToken,
    this.refreshToken,
  });
}

/// DI 및 테스트에서 [AuthClient]와 [MockAuthClient]를 교체할 수 있게 하는 인터페이스.
abstract class AuthClientBase {
  Future<AuthResponse> login(String email, String password);
  Future<User> me();
  Future<RefreshResult> refresh(String refreshToken);
}

class AuthClient extends AuthClientBase {
  final AuthApi _api;

  AuthClient(this._api);

  /// 이메일/비밀번호로 로그인.
  /// 성공 시 [AuthResponse] (accessToken, refreshToken, user) 반환.
  Future<AuthResponse> login(String email, String password) async {
    final dto = await _api.login(
      LoginRequestDto(email: email, password: password),
    );
    return AuthResponse.fromDto(dto);
  }

  /// 현재 인증된 사용자 정보 조회.
  /// Authorization 헤더에 유효한 토큰이 있어야 함.
  Future<User> me() async {
    final dto = await _api.me();
    return User.fromDto(dto);
  }

  /// refreshToken으로 새 accessToken 발급.
  /// [RefreshResult]로 반환 (사용자 정보 없음).
  /// 자동 갱신은 TokenRefreshInterceptor가 처리하므로 직접 호출은 드묾.
  Future<RefreshResult> refresh(String refreshToken) async {
    final dto = await _api.refresh(
      RefreshRequestDto(refreshToken: refreshToken),
    );
    return RefreshResult(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
    );
  }
}
