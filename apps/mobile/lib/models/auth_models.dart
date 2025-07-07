/// Paperly Mobile App - 인증 관련 데이터 모델
/// 
/// 이 파일은 인증 시스템에서 사용되는 모든 데이터 모델을 정의합니다.
/// Freezed 패키지를 사용하여 불변객체와 직렬화 기능을 제공합니다.
/// 
/// 주요 모델들:
/// - User: 사용자 정보 (이메일, 이름, 인증 상태 등)
/// - AuthTokens: JWT 액세스/리프레시 토큰
/// - RegisterRequest: 회원가입 요청 데이터
/// - LoginRequest: 로그인 요청 데이터
/// - AuthResponse: 인증 API 응답 데이터
/// 
/// 기술적 특징:
/// - Freezed로 생성된 불변객체 (immutable)
/// - JSON 직렬화/역직렬화 자동 생성
/// - copyWith 메서드로 부분 업데이트 가능
/// - 패턴 매칭과 동등성 비교 자동 지원

import 'package:freezed_annotation/freezed_annotation.dart'; // Freezed 애노테이션

// Freezed에 의해 자동 생성되는 파일들
part 'auth_models.freezed.dart';  // 클래스 구현과 유틸리티 메서드들
part 'auth_models.g.dart';        // JSON 직렬화 메서드들

/// 사용자 정보 모델
/// 
/// 앱에 로그인한 사용자의 기본 정보를 담는 불변객체입니다.
/// 서버에서 받은 사용자 데이터를 클라이언트에서 사용하기 위한 형태로 변환합니다.
/// 
/// 필드 설명:
/// - id: 사용자 고유 식별자 (서버에서 숫자로 오더라도 문자열로 변환)
/// - email: 사용자 이메일 주소 (로그인 ID 겨남)
/// - name: 사용자 이름 (얁 내에서 표시되는 닉네임)
/// - emailVerified: 이메일 인증 완료 여부
/// - birthDate: 사용자 생년월일 (선택사항)
/// - gender: 성별 정보 (선택사항)
@freezed
class User with _$User {
  const User._();
  const factory User({
    required String id,              // 사용자 고유 ID
    required String email,           // 이메일 주소
    required String name,            // 사용자 이름
    required bool emailVerified,     // 이메일 인증 여부
    DateTime? birthDate,             // 생년월일 (선택)
    Gender? gender,                  // 성별 (선택)
  }) = _User;

  /// JSON에서 User 객체로 변환
  /// 
  /// 서버에서 ID를 숫자형으로 보내는 경우가 있어 문자열로 변환합니다.
  /// 이는 다른 플랫폼과의 호환성을 위해 필요한 처리입니다.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate']) : null,
      gender: json['gender'] != null ? Gender.values.firstWhere(
        (e) => e.toString().split('.').last == json['gender'],
        orElse: () => Gender.unknown,
      ) : null,
    );
  }

}

/// 성별 선택 열거형
/// 
/// 사용자가 선택할 수 있는 성별 옵션들을 정의합니다.
/// JSON 직렬화 시 영어 문자열로 변환되어 서버와 통신합니다.
enum Gender {
  @JsonValue('male')               // 남성
  male,
  @JsonValue('female')             // 여성
  female,
  @JsonValue('other')              // 기타
  other,
  @JsonValue('prefer_not_to_say')  // 응답 안함
  preferNotToSay,
  @JsonValue('unknown')            // 알 수 없음
  unknown,
}

/// JWT 인증 토큰 모델
/// 
/// 서버에서 발급한 JWT 토큰들을 저장하는 모델입니다.
/// Access Token은 API 요청 시 인증에 사용되고,
/// Refresh Token은 Access Token 만료 시 새로운 토큰 발급에 사용됩니다.
/// 
/// 필드 설명:
/// - accessToken: API 요청 시 인증에 사용하는 단기 토큰 (보통 15-30분)
/// - refreshToken: Access Token 갱신에 사용하는 장기 토큰 (보통 30일)
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,     // 단기 인증 토큰
    required String refreshToken,    // 장기 갱신 토큰
  }) = _AuthTokens;

  /// JSON에서 AuthTokens 객체로 변환
  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);
}

/// 회원가입 요청 데이터 모델
/// 
/// 새로운 사용자가 계정을 생성할 때 서버로 전송하는 데이터를 담습니다.
/// 서버 API 명세에 맞춰 날짜 형식을 자동으로 변환합니다.
/// 
/// 필드 설명:
/// - email: 사용자 이메일 (로그인 ID로 사용)
/// - password: 비밀번호 (평문 전송, 서버에서 해시 처리)
/// - name: 사용자 이름 (닉네임)
/// - birthDate: 생년월일 (YYYY-MM-DD 형식으로 자동 변환)
/// - gender: 성별 선택사항
/// - userType: 사용자 타입 (독자/작가, 기본값: reader)
/// - deviceInfo: 디바이스 식별 정보
@freezed
class RegisterRequest with _$RegisterRequest {
  const RegisterRequest._();         // private 생성자 (커스텀 메서드 추가용)
  
  const factory RegisterRequest({
    required String email,           // 사용자 이메일
    required String password,        // 비밀번호
    required String name,            // 사용자 이름
    required DateTime birthDate,     // 생년월일
    Gender? gender,                  // 성별 (선택)
    @Default('reader') String userType, // 사용자 타입 (기본값: reader)
    required DeviceInfo deviceInfo,  // 디바이스 정보
  }) = _RegisterRequest;

  /// JSON에서 RegisterRequest 객체로 변환
  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  
  /// RegisterRequest 객체를 JSON으로 변환
  /// 
  /// 서버 API에서 요구하는 형식에 맞춰 날짜를 YYYY-MM-DD 문자열로 변환합니다.
  /// 성별은 선택사항이므로 null일 수 있습니다.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      // DateTime을 YYYY-MM-DD 형식의 문자열로 변환
      'birthDate': '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      // 성별이 선택된 경우만 JSON에 포함
      'gender': gender != null ? _$GenderEnumMap[gender] : null,
      // 사용자 타입 포함
      'userType': userType,
      // 디바이스 정보 포함
      'deviceInfo': deviceInfo.toJson(),
    };
  }
}

/// 디바이스 정보 모델
/// 
/// 로그인/회원가입 시 디바이스 식별을 위해 전송하는 정보입니다.
/// 보안 및 세션 관리를 위해 사용됩니다.
@freezed
class DeviceInfo with _$DeviceInfo {
  const factory DeviceInfo({
    required String deviceId,        // 디바이스 고유 식별자
    required String userAgent,       // 사용자 에이전트 문자열
    String? ipAddress,              // IP 주소 (선택사항)
  }) = _DeviceInfo;

  /// JSON에서 DeviceInfo 객체로 변환
  factory DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);
}

/// 로그인 요청 데이터 모델
/// 
/// 기존 사용자가 로그인할 때 서버로 전송하는 인증 정보를 담습니다.
/// 사용자의 이메일과 비밀번호, 그리고 디바이스 정보로 구성됩니다.
/// 
/// 필드 설명:
/// - email: 로그인 ID로 사용할 이메일 주소
/// - password: 사용자가 입력한 비밀번호 (평문)
/// - deviceInfo: 디바이스 식별 정보
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,           // 사용자 이메일
    required String password,        // 비밀번호
    required DeviceInfo deviceInfo,  // 디바이스 정보
  }) = _LoginRequest;

  /// JSON에서 LoginRequest 객체로 변환
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

/// 인증 API 응답 데이터 모델
/// 
/// 로그인 또는 회원가입 성공 시 서버에서 반환하는 데이터를 담습니다.
/// 사용자 정보와 인증 토큰을 포함하여 클라이언트에서 바로 사용할 수 있습니다.
/// 
/// 필드 설명:
/// - user: 로그인한 사용자의 정보
/// - tokens: 인증에 사용할 JWT 토큰들
/// - emailVerificationSent: 이메일 인증 메일 전송 여부 (선택사항)
@freezed
class AuthResponse with _$AuthResponse {
  const AuthResponse._();
  const factory AuthResponse({
    required User user,              // 사용자 정보
    required AuthTokens tokens,      // 인증 토큰들
    bool? emailVerificationSent,     // 이메일 인증 메일 전송 여부
  }) = _AuthResponse;

  /// JSON에서 AuthResponse 객체로 변환
  /// 
  /// 서버에서 중첩된 객체 내에 숫자 ID가 포함된 경우를 처리합니다.
  /// user 객체 내의 id 필드가 숫자로 온 경우 문자열로 변환합니다.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // 중첩된 객체들의 타입 변환 처리
    final Map<String, dynamic> modifiedJson = Map.from(json);
    
    // user 객체 내의 id 필드 타입 보정
    if (modifiedJson['user'] is Map<String, dynamic>) {
      final userJson = Map<String, dynamic>.from(modifiedJson['user']);
      if (userJson['id'] is int) {
        userJson['id'] = userJson['id'].toString();
      }
      modifiedJson['user'] = userJson;
    }
    
    return AuthResponse(
      user: User.fromJson(modifiedJson['user']),
      tokens: AuthTokens.fromJson(modifiedJson['tokens']),
      emailVerificationSent: modifiedJson['emailVerificationSent'],
    );
  }

}