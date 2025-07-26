import 'package:json_annotation/json_annotation.dart';

part 'address_dto.g.dart';

@JsonSerializable()
class AddressDto {
  String? street1;

  String? street2;

  String? city;

  String? state;

  int? postcode;

  double? longitude;

  double? latitude;

  AddressDto({
    this.street1,
    this.street2,
    this.city,
    this.state,
    this.postcode,
    this.longitude,
    this.latitude,
  });

  factory AddressDto.fromJson(Map<String, dynamic> json) =>
      _$AddressDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AddressDtoToJson(this);
}
