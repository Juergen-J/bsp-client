// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Brand _$BrandFromJson(Map<String, dynamic> json) => Brand(
      id: json['id'] as String,
      name: json['name'] as String,
      status: $enumDecodeNullable(_$ElementStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$BrandToJson(Brand instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': _$ElementStatusEnumMap[instance.status],
    };

const _$ElementStatusEnumMap = {
  ElementStatus.ENABLED: 'ENABLED',
  ElementStatus.DISABLED: 'DISABLED',
};
