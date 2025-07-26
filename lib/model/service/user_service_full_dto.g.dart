// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_service_full_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserServiceFullDto _$UserServiceFullDtoFromJson(Map<String, dynamic> json) =>
    UserServiceFullDto(
      id: json['id'] as String,
      serviceType: ShortServiceTypeDto.fromJson(
          json['serviceType'] as Map<String, dynamic>),
      name: json['name'] as String,
      description: json['description'] as String,
      devices: (json['devices'] as List<dynamic>?)
              ?.map((e) => ShortDeviceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      price: (json['price'] as num?)?.toDouble(),
      attributes: (json['attributes'] as List<dynamic>)
          .map((e) => ServiceAttributeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      address: AddressDto.fromJson(json['address'] as Map<String, dynamic>),
      status: $enumDecode(_$ElementStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$UserServiceFullDtoToJson(UserServiceFullDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceType': instance.serviceType,
      'name': instance.name,
      'description': instance.description,
      'devices': instance.devices,
      'price': instance.price,
      'attributes': instance.attributes,
      'attachments': instance.attachments,
      'address': instance.address,
      'status': _$ElementStatusEnumMap[instance.status]!,
    };

const _$ElementStatusEnumMap = {
  ElementStatus.ENABLED: 'ENABLED',
  ElementStatus.DISABLED: 'DISABLED',
};
