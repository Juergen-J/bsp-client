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
  late final AttachmentDtoDetails details;

  AttachmentDto(
      {required this.id, required this.mainAttachment, required this.type});

  factory AttachmentDto.fromJson(Map<String, dynamic> json) {
    final type = $enumDecode<AttachmentType, String>(
        _$AttachmentTypeEnumMap, json['type']);
    final dto = AttachmentDto(
      id: json['id'] as String,
      mainAttachment: json['mainAttachment'] as bool,
      type: type,
    );
    dto.details = _parseDetails(json['details'], type);
    return dto;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mainAttachment': mainAttachment,
        'type': _$AttachmentTypeEnumMap[type]!,
        'details': details.toJson(),
      };

  static AttachmentDtoDetails _parseDetails(dynamic json, AttachmentType type) {
    switch (type) {
      case AttachmentType.IMAGE:
        return ImageAttachmentDto.fromJson(json);
      case AttachmentType.VIDEO:
        throw UnsupportedError('Video attachments are not supported.');
      case AttachmentType.DOCUMENT:
        throw UnsupportedError('Document attachments are not supported.');
    }
  }
}
