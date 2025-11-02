// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_event_dto.dart';

BleEventDto _$BleEventDtoFromJson(Map<String, dynamic> json) => BleEventDto(
      type: json['type'] as String,
      deviceId: json['deviceId'] as String,
      payload: json['payload'] as String?,
      ts: json['ts'] == null ? null : DateTime.parse(json['ts'] as String),
    );

Map<String, dynamic> _$BleEventDtoToJson(BleEventDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'deviceId': instance.deviceId,
      'payload': instance.payload,
      'ts': instance.ts.toIso8601String(),
    };
