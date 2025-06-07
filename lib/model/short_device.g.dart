// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'short_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShortDevice _$ShortDeviceFromJson(Map<String, dynamic> json) => ShortDevice(
      id: json['id'] as String,
      deviceType:
          DeviceType.fromJson(json['deviceType'] as Map<String, dynamic>),
      brand: Brand.fromJson(json['brand'] as Map<String, dynamic>),
      skuCode: json['skuCode'] as String?,
      name: json['name'] as String,
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => AttributePresent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      imagePath: json['imagePath'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ShortDeviceToJson(ShortDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceType': instance.deviceType,
      'brand': instance.brand,
      'skuCode': instance.skuCode,
      'name': instance.name,
      'attributes': instance.attributes,
      'imagePath': instance.imagePath,
      'attachments': instance.attachments,
    };
