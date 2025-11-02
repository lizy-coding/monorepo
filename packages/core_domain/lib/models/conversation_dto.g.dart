// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_dto.dart';

ConversationDto _$ConversationDtoFromJson(Map<String, dynamic> json) =>
    ConversationDto(
      peerId: json['peerId'] as String,
      title: json['title'] as String?,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ConversationDtoToJson(ConversationDto instance) =>
    <String, dynamic>{
      'peerId': instance.peerId,
      'title': instance.title,
      'unread': instance.unread,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
