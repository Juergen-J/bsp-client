import 'package:berlin_service_portal/model/service/price_dto.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../attachment/attachment_dto.dart';

part 'user_service_short_dto.g.dart';

@JsonSerializable()
class UserServiceShortDto {
  final String id;

  final ShortServiceTypeDto serviceType;

  final String name;

  final String description;

  final PriceDto price;

  final List<AttachmentDto> attachments;

  const UserServiceShortDto({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.price,
    this.attachments = const [],
  });

  factory UserServiceShortDto.fromJson(Map<String, dynamic> json) =>
      _$UserServiceShortDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserServiceShortDtoToJson(this);
}
