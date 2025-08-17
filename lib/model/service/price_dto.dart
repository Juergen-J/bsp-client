import 'package:json_annotation/json_annotation.dart';

part 'price_dto.g.dart';

@JsonSerializable()
class PriceDto {
  @JsonKey(fromJson: _amountFromJson, toJson: _amountToJson)
  final num amount;

  @JsonKey(defaultValue: 'EUR')
  final String currencyCode;

  @JsonKey(defaultValue: 'Euro')
  final String currencyName;

  @JsonKey(defaultValue: false)
  final bool negotiable;

  const PriceDto(
    this.amount,
    this.currencyCode,
    this.currencyName,
    this.negotiable,
  );

  factory PriceDto.fromJson(Map<String, dynamic> json) =>
      _$PriceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PriceDtoToJson(this);

  static num _amountFromJson(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.parse(v.replaceAll(',', '.'));
    throw FormatException('Unexpected amount json: $v');
  }

  static dynamic _amountToJson(num v) => v;
}
