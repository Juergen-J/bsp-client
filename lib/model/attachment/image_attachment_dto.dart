import 'package:json_annotation/json_annotation.dart';
import 'attachment_dto_details.dart';

part 'image_attachment_dto.g.dart';

@JsonSerializable()
class ImageAttachmentDto implements AttachmentDtoDetails {
  final String smallId;
  final String normalId;

  ImageAttachmentDto({
    required this.smallId,
    required this.normalId,
  });

  factory ImageAttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$ImageAttachmentDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ImageAttachmentDtoToJson(this);
}
