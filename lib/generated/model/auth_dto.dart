// GENERATED CODE — DO NOT MODIFY BY HAND
//
// 이 파일은 아키텍처 참조 구현체입니다.
// 실제 서버 연동 시 scripts/generate.sh 를 실행하면 이 파일이 교체됩니다.

import 'package:json_annotation/json_annotation.dart';

import 'user_dto.dart';

part 'auth_dto.g.dart';

@JsonSerializable()
class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}

@JsonSerializable()
class AuthResponseDto {
  final String accessToken;
  final String? refreshToken;
  final UserDto user;

  const AuthResponseDto({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}

@JsonSerializable()
class RefreshRequestDto {
  final String refreshToken;

  const RefreshRequestDto({required this.refreshToken});

  factory RefreshRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshRequestDtoToJson(this);
}

@JsonSerializable()
class RefreshResponseDto {
  final String accessToken;
  final String? refreshToken;

  const RefreshResponseDto({
    required this.accessToken,
    this.refreshToken,
  });

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshResponseDtoToJson(this);
}
