import 'package:json_annotation/json_annotation.dart';

part 'short_service_type_dto.g.dart';

@JsonSerializable()
class ShortServiceTypeDto {
  final String id;

  final String systemName;

  final String displayName;

  ShortServiceTypeDto(this.id, this.systemName, this.displayName);

  factory ShortServiceTypeDto.fromJson(Map<String, dynamic> json) =>
      _$ShortServiceTypeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShortServiceTypeDtoToJson(this);
}
