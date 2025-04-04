import 'package:json_annotation/json_annotation.dart';

part 'element_status.g.dart';

@JsonEnum(alwaysCreate: true)
enum ElementStatus {
  @JsonValue("ENABLED")
  ENABLED,

  @JsonValue("DISABLED")
  DISABLED
}
