// GENERATED CODE — DO NOT MODIFY BY HAND
//
// 이 파일은 아키텍처 참조 구현체입니다.
// 실제 서버 연동 시 scripts/generate.sh 를 실행하면 이 파일이 교체됩니다.

import 'package:dio/dio.dart';

import '../model/user_dto.dart';

class UserApi {
  final Dio _dio;

  const UserApi(this._dio);

  /// 페이지네이션 유저 목록 반환.
  /// NestJS 표준 응답 `{ data, meta }` 구조로 단일 HTTP 호출.
  Future<PagedResponseDto<UserDto>> getUsers({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/users',
      queryParameters: {'page': page, 'limit': limit},
    );
    return PagedResponseDto.fromJson(
      response.data!,
      (e) => UserDto.fromJson(e as Map<String, dynamic>),
    );
  }

  Future<UserDto> getUserById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/users/$id');
    return UserDto.fromJson(response.data!);
  }
}
