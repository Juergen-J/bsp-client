// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_service_full_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserServiceFullDto _$UserServiceFullDtoFromJson(Map<String, dynamic> json) =>
    UserServiceFullDto(
      id: json['id'] as String,
      serviceType: ShortServiceTypeDto.fromJson(
        json['serviceType'] as Map<String, dynamic>,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
      devices:
          (json['devices'] as List<dynamic>?)
              ?.map((e) => ShortDeviceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      price: PriceDto.fromJson(json['price'] as Map<String, dynamic>),
      userId: json['userId'] as String,
      attributes: (json['attributes'] as List<dynamic>)
          .map((e) => ServiceAttributeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      address: AddressDto.fromJson(json['address'] as Map<String, dynamic>),
      status: $enumDecode(_$ElementStatusEnumMap, json['status']),
      favorite: json['favorite'] as bool? ?? false,
    );

Map<String, dynamic> _$UserServiceFullDtoToJson(UserServiceFullDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceType': instance.serviceType,
      'name': instance.name,
      'description': instance.description,
      'devices': instance.devices,
      'price': instance.price,
      'userId': instance.userId,
      'attributes': instance.attributes,
      'attachments': instance.attachments,
      'address': instance.address,
      'status': _$ElementStatusEnumMap[instance.status]!,
      'favorite': instance.favorite,
    };

const _$ElementStatusEnumMap = {
  ElementStatus.ENABLED: 'ENABLED',
  ElementStatus.DISABLED: 'DISABLED',
};
