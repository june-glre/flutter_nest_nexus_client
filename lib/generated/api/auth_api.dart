// GENERATED CODE — DO NOT MODIFY BY HAND
//
// 이 파일은 아키텍처 참조 구현체입니다.
// 실제 서버 연동 시 scripts/generate.sh 를 실행하면 이 파일이 교체됩니다.

import 'package:dio/dio.dart';

import '../model/auth_dto.dart';
import '../model/user_dto.dart';

class AuthApi {
  final Dio _dio;

  const AuthApi(this._dio);

  Future<AuthResponseDto> login(LoginRequestDto body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: body.toJson(),
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  Future<UserDto> me() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserDto.fromJson(response.data!);
  }

  Future<RefreshResponseDto> refresh(RefreshRequestDto body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: body.toJson(),
    );
    return RefreshResponseDto.fromJson(response.data!);
  }
}
