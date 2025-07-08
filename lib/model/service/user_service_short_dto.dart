import 'package:berlin_service_portal/model/service/service_attribute_dto.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../address_dto.dart';
import '../attachment/attachment_dto.dart';
import '../device/short_device_dto.dart';
import '../element_status.dart';

part 'user_service_short_dto.g.dart';

@JsonSerializable()
class UserServiceShortDto {
  final String id;

  final ShortServiceTypeDto serviceType;

  final String name;

  final String description;

  final double price;

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
