import 'package:json_annotation/json_annotation.dart';

part 'postal_suggestion_dto.g.dart';

@JsonSerializable()
class PostalSuggestionDto {
  String? postcode;
  String? city;
  String? countryCode;
  String? countryName;
  String? admin1;

  PostalSuggestionDto({
    this.postcode,
    this.city,
    this.countryCode,
    this.countryName,
    this.admin1
  });

  factory PostalSuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$PostalSuggestionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PostalSuggestionDtoToJson(this);
}
