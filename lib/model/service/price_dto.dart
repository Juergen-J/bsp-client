import 'package:json_annotation/json_annotation.dart';

part 'price_dto.g.dart';

@JsonSerializable()
class PriceDto {
  final double amount;
  final String currencyCode;
  final String currencyName;
  final bool negotiable;

  PriceDto(this.amount, this.currencyCode, this.currencyName, this.negotiable);

  factory PriceDto.fromJson(Map<String, dynamic> json) =>
      _$PriceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PriceDtoToJson(this);
}
