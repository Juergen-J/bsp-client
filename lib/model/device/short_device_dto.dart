import 'package:berlin_service_portal/model/attachment/attachment_dto.dart';
import 'package:berlin_service_portal/model/device/brand.dart';
import 'package:berlin_service_portal/model/device/device_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'attribute_present.dart';

part 'short_device_dto.g.dart';

@JsonSerializable()
class ShortDeviceDto {
  final String id;

  final DeviceType deviceType;

  final Brand brand;

  final String? skuCode;

  final String name;

  final List<AttributePresent> attributes;

  final List<AttachmentDto> attachments;

  ShortDeviceDto({
    required this.id,
    required this.deviceType,
    required this.brand,
    this.skuCode,
    required this.name,
    this.attributes = const [],
    this.attachments = const [],
  });

  factory ShortDeviceDto.fromJson(Map<String, dynamic> json) =>
      _$ShortDeviceDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShortDeviceDtoToJson(this);
}
