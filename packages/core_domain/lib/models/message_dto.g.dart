// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dto.dart';

MessageDto _$MessageDtoFromJson(Map<String, dynamic> json) => MessageDto(
      id: json['id'] as String,
      peerId: json['peerId'] as String,
      direction:
          $enumDecode(_$MessageDirectionEnumMap, json['direction']),
      text: json['text'] as String,
      ts: json['ts'] == null ? null : DateTime.parse(json['ts'] as String),
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.delivered,
    );

Map<String, dynamic> _$MessageDtoToJson(MessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'peerId': instance.peerId,
      'direction': _$MessageDirectionEnumMap[instance.direction]!,
      'text': instance.text,
      'ts': instance.ts.toIso8601String(),
      'status': _$MessageStatusEnumMap[instance.status],
    };

const _$MessageDirectionEnumMap = {
  MessageDirection.in_: 'in',
  MessageDirection.out: 'out',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
};
