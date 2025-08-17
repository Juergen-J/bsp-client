// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_user_service_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewUserServiceDto _$NewUserServiceDtoFromJson(Map<String, dynamic> json) =>
    NewUserServiceDto(
      serviceTypeId: json['serviceTypeId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      mainAttachment: json['mainAttachment'] as String? ?? '',
      devices: (json['devices'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      price: PriceDto.fromJson(json['price'] as Map<String, dynamic>),
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) =>
                  ServiceAttributeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      address: AddressDto.fromJson(json['address'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NewUserServiceDtoToJson(NewUserServiceDto instance) =>
    <String, dynamic>{
      'serviceTypeId': instance.serviceTypeId,
      'name': instance.name,
      'description': instance.description,
      'mainAttachment': instance.mainAttachment,
      'devices': instance.devices,
      'price': instance.price,
      'attributes': instance.attributes,
      'address': instance.address,
    };
