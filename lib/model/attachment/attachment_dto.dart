import 'package:json_annotation/json_annotation.dart';
import 'attachment_dto_details.dart';
import 'attachment_type.dart';
import 'image_attachment_dto.dart';

part 'attachment_dto.g.dart';

@JsonSerializable()
class AttachmentDto {
  final String id;
  final bool mainAttachment;
  final AttachmentType type;

  @JsonKey(ignore: true)
  AttachmentDtoDetails? details;

  AttachmentDto({
    required this.id,
    required this.mainAttachment,
    required this.type,
    this.details,
  });

  factory AttachmentDto.fromJson(Map<String, dynamic> json) {
    final type = $enumDecode<AttachmentType, String>(
        _$AttachmentTypeEnumMap, json['type']);

    final dto = AttachmentDto(
      id: json['id'] as String,
      mainAttachment: json['mainAttachment'] as bool,
      type: type,
    );

    if (json['details'] != null) {
      dto.details = _parseDetails(json['details'], type);
    }

    return dto;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mainAttachment': mainAttachment,
        'type': _$AttachmentTypeEnumMap[type]!,
        if (details != null) 'details': details!.toJson(),
      };

  static AttachmentDtoDetails _parseDetails(dynamic json, AttachmentType type) {
    switch (type) {
      case AttachmentType.IMAGE:
        return ImageAttachmentDto.fromJson(json as Map<String, dynamic>);
      case AttachmentType.VIDEO:
        throw UnsupportedError('Video attachments are not supported.');
      case AttachmentType.DOCUMENT:
        throw UnsupportedError('Document attachments are not supported.');
    }
  }
}
