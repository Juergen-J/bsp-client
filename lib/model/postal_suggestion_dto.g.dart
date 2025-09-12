// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'postal_suggestion_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostalSuggestionDto _$PostalSuggestionDtoFromJson(Map<String, dynamic> json) =>
    PostalSuggestionDto(
      postcode: json['postcode'] as String?,
      city: json['city'] as String?,
      countryCode: json['countryCode'] as String?,
      countryName: json['countryName'] as String?,
      admin1: json['admin1'] as String?,
    );

Map<String, dynamic> _$PostalSuggestionDtoToJson(
        PostalSuggestionDto instance) =>
    <String, dynamic>{
      'postcode': instance.postcode,
      'city': instance.city,
      'countryCode': instance.countryCode,
      'countryName': instance.countryName,
      'admin1': instance.admin1,
    };
