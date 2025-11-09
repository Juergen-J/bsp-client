// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceType _$DeviceTypeFromJson(Map<String, dynamic> json) => DeviceType(
  id: json['id'] as String,
  parentId: json['parentId'] as String?,
  systemName: json['systemName'] as String,
  displayName: json['displayName'] as String,
  status: $enumDecodeNullable(_$ElementStatusEnumMap, json['status']),
);

Map<String, dynamic> _$DeviceTypeToJson(DeviceType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': instance.parentId,
      'systemName': instance.systemName,
      'displayName': instance.displayName,
      'status': _$ElementStatusEnumMap[instance.status],
    };

const _$ElementStatusEnumMap = {
  ElementStatus.ENABLED: 'ENABLED',
  ElementStatus.DISABLED: 'DISABLED',
};
