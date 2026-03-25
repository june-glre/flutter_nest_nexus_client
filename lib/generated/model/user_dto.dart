// GENERATED CODE — DO NOT MODIFY BY HAND
//
// 이 파일은 아키텍처 참조 구현체입니다.
// 실제 서버 연동 시 scripts/generate.sh 를 실행하면 이 파일이 교체됩니다.
//
// scripts/generate.sh https://your-api.com/api-json

import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  final String id;
  final String email;
  final String name;

  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

/// NestJS 표준 페이지네이션 응답 래퍼.
/// `{ data: [...], meta: { total, page, limit } }` 구조.
///
/// N+1 HTTP 호출 방지: getUsers() 한 번으로 items + pagination meta를 모두 수신.
@JsonSerializable(genericArgumentFactories: true)
class PagedResponseDto<T> {
  final List<T> data;
  final PageMetaDto meta;

  const PagedResponseDto({required this.data, required this.meta});

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$PagedResponseDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$PagedResponseDtoToJson(this, toJsonT);
}

/// 페이지네이션 메타 정보.
@JsonSerializable()
class PageMetaDto {
  final int total;
  final int page;
  final int limit;

  const PageMetaDto({
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PageMetaDto.fromJson(Map<String, dynamic> json) =>
      _$PageMetaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PageMetaDtoToJson(this);
}
