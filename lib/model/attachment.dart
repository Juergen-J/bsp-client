import 'package:json_annotation/json_annotation.dart';
import 'element_status.dart';

part 'attachment.g.dart';

@JsonSerializable()
class Attachment {
  final String id;

  final bool mainAttachment;

  Attachment({required this.id, required this.mainAttachment});

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$AttachmentToJson(this);
}
