// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthTokensImpl _$$AuthTokensImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokensImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$$AuthTokensImplToJson(_$AuthTokensImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

_$RegisterRequestImpl _$$RegisterRequestImplFromJson(
  Map<String, dynamic> json,
) => _$RegisterRequestImpl(
  email: json['email'] as String,
  password: json['password'] as String,
  name: json['name'] as String,
  birthDate: DateTime.parse(json['birthDate'] as String),
  gender: $enumDecodeNullable(_$GenderEnumMap, json['gender']),
  userType: json['userType'] as String? ?? 'reader',
);

Map<String, dynamic> _$$RegisterRequestImplToJson(
  _$RegisterRequestImpl instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'name': instance.name,
  'birthDate': instance.birthDate.toIso8601String(),
  'gender': _$GenderEnumMap[instance.gender],
  'userType': instance.userType,
};

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.other: 'other',
  Gender.preferNotToSay: 'prefer_not_to_say',
};

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};
