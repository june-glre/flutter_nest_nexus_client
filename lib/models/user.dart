import '../generated/model/auth_dto.dart';
import '../generated/model/user_dto.dart';

/// Flutter 앱 친화적 User 모델.
/// generated/UserDto와 분리되어 앱이 generated 코드를 직접 의존하지 않음.
/// openapi-generator 재생성 시 이 파일은 변경되지 않음.
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory User.fromDto(UserDto dto) => User(
        id: dto.id,
        email: dto.email,
        name: dto.name,
        createdAt: dto.createdAt,
      );

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 로그인/토큰 갱신 성공 시 반환되는 인증 정보.
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final User user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromDto(AuthResponseDto dto) => AuthResponse(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
        user: User.fromDto(dto.user),
      );

  @override
  String toString() =>
      'AuthResponse(user: ${user.email}, hasRefreshToken: ${refreshToken != null})';
}
