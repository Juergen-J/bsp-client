// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressDto _$AddressDtoFromJson(Map<String, dynamic> json) => AddressDto(
  street1: json['street1'] as String?,
  street2: json['street2'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  postcode: (json['postcode'] as num?)?.toInt(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AddressDtoToJson(AddressDto instance) =>
    <String, dynamic>{
      'street1': instance.street1,
      'street2': instance.street2,
      'city': instance.city,
      'state': instance.state,
      'postcode': instance.postcode,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
    };
