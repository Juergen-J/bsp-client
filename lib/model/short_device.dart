import 'package:berlin_service_portal/model/attachment/attachment_dto.dart';
import 'package:berlin_service_portal/model/brand.dart';
import 'package:berlin_service_portal/model/device_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'attribute_present.dart';

part 'short_device.g.dart';

@JsonSerializable()
class ShortDevice {
  final String id;

  final DeviceType deviceType;

  final Brand brand;

  final String? skuCode;

  final String name;

  final List<AttributePresent> attributes;

  final List<AttachmentDto> attachments;

  ShortDevice({
    required this.id,
    required this.deviceType,
    required this.brand,
    this.skuCode,
    required this.name,
    this.attributes = const [],
    this.attachments = const [],
  });

  factory ShortDevice.fromJson(Map<String, dynamic> json) =>
      _$ShortDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$ShortDeviceToJson(this);
}
