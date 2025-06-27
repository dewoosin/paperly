// lib/models/auth_models.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// 사용자 모델
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    required bool emailVerified,
    DateTime? birthDate,
    Gender? gender,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) {
    // ID가 숫자로 올 수 있으므로 문자열로 변환
    final Map<String, dynamic> modifiedJson = Map.from(json);
    if (modifiedJson['id'] is int) {
      modifiedJson['id'] = modifiedJson['id'].toString();
    }
    return _$UserFromJson(modifiedJson);
  }
}

/// 성별 열거형
enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('other')
  other,
  @JsonValue('prefer_not_to_say')
  preferNotToSay,
}

/// 인증 토큰
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);
}

/// 회원가입 요청
@freezed
class RegisterRequest with _$RegisterRequest {
  const RegisterRequest._();
  const factory RegisterRequest({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
    Gender? gender,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'birthDate': '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      'gender': gender != null ? _$GenderEnumMap[gender] : null,
    };
  }
}

/// 로그인 요청
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

/// 인증 응답
@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required User user,
    required AuthTokens tokens,
    bool? emailVerificationSent,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // 중첩된 객체들도 처리
    final Map<String, dynamic> modifiedJson = Map.from(json);
    
    // user 객체 내의 id 처리
    if (modifiedJson['user'] is Map<String, dynamic>) {
      final userJson = Map<String, dynamic>.from(modifiedJson['user']);
      if (userJson['id'] is int) {
        userJson['id'] = userJson['id'].toString();
      }
      modifiedJson['user'] = userJson;
    }
    
    return _$AuthResponseFromJson(modifiedJson);
  }
}