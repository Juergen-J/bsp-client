import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

@JsonSerializable()
class UserInfo {
  final String id;
  final String firstname;
  final String lastname;
  final String email;

  UserInfo({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);
}
