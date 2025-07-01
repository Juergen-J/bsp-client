import 'package:json_annotation/json_annotation.dart';
import '../element_status.dart';

part 'brand.g.dart';

@JsonSerializable()
class Brand {
  final String id;

  final String name;

  final ElementStatus? status;

  Brand({required this.id, required this.name, this.status});

  factory Brand.fromJson(Map<String, dynamic> json) => _$BrandFromJson(json);

  Map<String, dynamic> toJson() => _$BrandToJson(this);
}
