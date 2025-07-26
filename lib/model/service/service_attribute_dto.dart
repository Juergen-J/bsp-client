import 'package:json_annotation/json_annotation.dart';

part 'service_attribute_dto.g.dart';

@JsonSerializable()
class ServiceAttributeDto {
  final String property;

  String value;

  ServiceAttributeDto(this.property, this.value);

  factory ServiceAttributeDto.fromJson(Map<String, dynamic> json) =>
      _$ServiceAttributeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAttributeDtoToJson(this);
}
