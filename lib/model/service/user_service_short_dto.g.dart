// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_service_short_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserServiceShortDto _$UserServiceShortDtoFromJson(Map<String, dynamic> json) =>
    UserServiceShortDto(
      id: json['id'] as String,
      serviceType: ShortServiceTypeDto.fromJson(
          json['serviceType'] as Map<String, dynamic>),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserServiceShortDtoToJson(
        UserServiceShortDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceType': instance.serviceType,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'attachments': instance.attachments,
    };
