// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'createdAt': instance.createdAt.toIso8601String(),
};

PagedResponseDto<T> _$PagedResponseDtoFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object?) fromJsonT,
) => PagedResponseDto<T>(
  data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
  meta: PageMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PagedResponseDtoToJson<T>(
  PagedResponseDto<T> instance,
  Object? Function(T) toJsonT,
) => <String, dynamic>{
  'data': instance.data.map(toJsonT).toList(),
  'meta': instance.meta.toJson(),
};

PageMetaDto _$PageMetaDtoFromJson(Map<String, dynamic> json) => PageMetaDto(
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$PageMetaDtoToJson(PageMetaDto instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
