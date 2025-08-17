// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceDto _$PriceDtoFromJson(Map<String, dynamic> json) => PriceDto(
      (json['amount'] as num).toDouble(),
      json['currencyCode'] as String,
      json['currencyName'] as String,
      json['negotiable'] as bool,
    );

Map<String, dynamic> _$PriceDtoToJson(PriceDto instance) => <String, dynamic>{
      'amount': instance.amount,
      'currencyCode': instance.currencyCode,
      'currencyName': instance.currencyName,
      'negotiable': instance.negotiable,
    };
