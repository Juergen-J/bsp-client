import 'package:berlin_service_portal/model/service/price_dto.dart';
import 'package:berlin_service_portal/model/service/service_attribute_dto.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../address_dto.dart';
import '../attachment/attachment_dto.dart';
import '../device/short_device_dto.dart';
import '../element_status.dart';

part 'user_service_full_dto.g.dart';

@JsonSerializable()
class UserServiceFullDto {
  final String id;

  final ShortServiceTypeDto serviceType;

   final String name;

   final String description;

  final List<ShortDeviceDto> devices;

  final PriceDto price;

  final String userId;

  final List<ServiceAttributeDto> attributes;

  final List<AttachmentDto> attachments;

  final AddressDto address;

  final ElementStatus status;

  const UserServiceFullDto({
    required this.id,
    required this.serviceType,
    required this.name,
    required this.description,
    this.devices = const [],
    required this.price,
    required this.userId,
    required this.attributes,
    this.attachments = const [],
    required this.address,
    required this.status,
  });

  factory UserServiceFullDto.fromJson(Map<String, dynamic> json) =>
      _$UserServiceFullDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserServiceFullDtoToJson(this);
}
