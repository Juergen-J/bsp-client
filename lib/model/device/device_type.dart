import 'package:json_annotation/json_annotation.dart';
import '../element_status.dart';

part 'device_type.g.dart';

@JsonSerializable()
class DeviceType {
  final String id;
  final String? parentId;
  final String systemName;
  final String displayName;
  final ElementStatus? status;

  DeviceType(
      {required this.id,
      this.parentId,
      required this.systemName,
      required this.displayName,
      this.status});

  factory DeviceType.fromJson(Map<String, dynamic> json) =>
      _$DeviceTypeFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTypeToJson(this);
}
