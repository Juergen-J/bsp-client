import 'package:berlin_service_portal/model/brand.dart';
import 'package:berlin_service_portal/model/device_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'attribute_present.dart';
import 'element_status.dart';

part 'short_device.g.dart';

@JsonSerializable()
class ShortDevice {
  final String id;

  final DeviceType deviceType;

  final Brand brand;

  final String? skuCode;

  final String name;

  final List<AttributePresent> attributes;

  final String? imagePath;

  ShortDevice({
    required this.id,
    required this.deviceType,
    required this.brand,
    this.skuCode,
    required this.name,
    this.attributes = const [],
    this.imagePath,
  });

  factory ShortDevice.fromJson(Map<String, dynamic> json) =>
      _$ShortDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$ShortDeviceToJson(this);
}
