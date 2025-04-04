import 'package:json_annotation/json_annotation.dart';
import 'element_status.dart';

part 'attribute_present.g.dart';

@JsonSerializable()
class AttributePresent {
  final String propertyId;

  final String propertySystemName;

  final String propertyName;

  final String value;

  AttributePresent({
    required this.propertyId,
    required this.propertySystemName,
    required this.propertyName,
    required this.value,
  });

  factory AttributePresent.fromJson(Map<String, dynamic> json) =>
      _$AttributePresentFromJson(json);

  Map<String, dynamic> toJson() => _$AttributePresentToJson(this);
}
