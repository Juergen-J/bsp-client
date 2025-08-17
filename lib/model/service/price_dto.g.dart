// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceDto _$PriceDtoFromJson(Map<String, dynamic> json) => PriceDto(
      PriceDto._amountFromJson(json['amount']),
      json['currencyCode'] as String? ?? 'EUR',
      json['currencyName'] as String? ?? 'Euro',
      json['negotiable'] as bool? ?? false,
    );

Map<String, dynamic> _$PriceDtoToJson(PriceDto instance) => <String, dynamic>{
      'amount': PriceDto._amountToJson(instance.amount),
      'currencyCode': instance.currencyCode,
      'currencyName': instance.currencyName,
      'negotiable': instance.negotiable,
    };
