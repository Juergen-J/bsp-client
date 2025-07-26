import 'package:berlin_service_portal/model/service/service_attribute_dto.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../address_dto.dart';
import '../attachment/attachment_dto.dart';
import '../device/short_device_dto.dart';
import '../element_status.dart';

part 'new_user_service_dto.g.dart';

@JsonSerializable()
class NewUserServiceDto {
  final String serviceTypeId;

  final String name;

  final String description;

  String mainAttachment;

  List<String> devices;

  final double? price;

  List<ServiceAttributeDto> attributes;

  final AddressDto address;

  NewUserServiceDto(
      {required this.serviceTypeId,
      required this.name,
      required this.description,
      this.mainAttachment = '',
      this.devices = const [],
      required this.price,
      this.attributes = const [],
      required this.address});

  factory NewUserServiceDto.fromJson(Map<String, dynamic> json) =>
      _$NewUserServiceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NewUserServiceDtoToJson(this);
}
