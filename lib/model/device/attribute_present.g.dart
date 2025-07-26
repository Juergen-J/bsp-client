// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute_present.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributePresent _$AttributePresentFromJson(Map<String, dynamic> json) =>
    AttributePresent(
      propertyId: json['propertyId'] as String,
      propertySystemName: json['propertySystemName'] as String,
      propertyName: json['propertyName'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$AttributePresentToJson(AttributePresent instance) =>
    <String, dynamic>{
      'propertyId': instance.propertyId,
      'propertySystemName': instance.propertySystemName,
      'propertyName': instance.propertyName,
      'value': instance.value,
    };
