// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
      'uid': instance.uid,
      'nickname': instance.nickname,
      'createdAt': instance.createdAt.toIso8601String(),
    };
