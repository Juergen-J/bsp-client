import 'package:json_annotation/json_annotation.dart';

part 'attachment_type.g.dart';

@JsonEnum(alwaysCreate: true)
enum AttachmentType {
  @JsonValue('IMAGE')
  IMAGE,
  @JsonValue('VIDEO')
  VIDEO,
  @JsonValue('DOCUMENT')
  DOCUMENT,
}
