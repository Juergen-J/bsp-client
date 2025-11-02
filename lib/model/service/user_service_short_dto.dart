import 'package:berlin_service_portal/model/service/price_dto.dart';
import 'package:berlin_service_portal/model/service/service_attribute_dto.dart';
import 'package:berlin_service_portal/model/service/short_service_type_dto.dart';
import 'package:json_annotation/json_annotation.dart';

import '../attachment/attachment_dto.dart';

part 'user_service_short_dto.g.dart';

@JsonSerializable()
class UserServiceShortDto {
  final String id;

  final String userId;

  final ShortServiceTypeDto serviceType;

  final String name;

  final String description;

  final PriceDto price;

  final List<AttachmentDto> attachments;

  final List<ServiceAttributeDto> attributes;

  final bool favorite;

  const UserServiceShortDto({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.name,
    required this.description,
    required this.price,
    this.attachments = const [],
    this.attributes = const [],
    this.favorite = false,
  });

  UserServiceShortDto copyWith({
    String? id,
    String? userId,
    ShortServiceTypeDto? serviceType,
    String? name,
    String? description,
    PriceDto? price,
    List<AttachmentDto>? attachments,
    List<ServiceAttributeDto>? attributes,
    bool? favorite,
  }) {
    return UserServiceShortDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      attachments: attachments ?? this.attachments,
      attributes: attributes ?? this.attributes,
      favorite: favorite ?? this.favorite,
    );
  }

  factory UserServiceShortDto.fromJson(Map<String, dynamic> json) =>
      _$UserServiceShortDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserServiceShortDtoToJson(this);
}
