// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      accessToken: json['access_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      refreshExpiresIn: (json['refresh_expires_in'] as num).toInt(),
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String?,
      scope: json['scope'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'expires_in': instance.expiresIn,
      'refresh_expires_in': instance.refreshExpiresIn,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'scope': instance.scope,
    };
