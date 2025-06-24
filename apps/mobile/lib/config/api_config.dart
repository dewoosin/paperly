// lib/config/api_config.dart

/// API 설정 클래스
/// 
/// 서버 URL, 타임아웃 등 API 관련 설정을 관리합니다.
class ApiConfig {
  /// 기본 서버 URL
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  /// 개발 서버 URL
  static const String devBaseUrl = 'http://localhost:3000/api/v1';
  
  /// 프로덕션 서버 URL
  static const String prodBaseUrl = 'https://api.paperly.com/api/v1';
  
  /// 현재 환경에 따른 서버 URL 반환
  static String get currentBaseUrl {
    // TODO: 환경에 따라 분기 처리
    // const bool isProduction = bool.fromEnvironment('dart.vm.product');
    // return isProduction ? prodBaseUrl : devBaseUrl;
    return devBaseUrl;
  }
  
  /// 연결 타임아웃 (초)
  static const int connectTimeoutSeconds = 5;
  
  /// 수신 타임아웃 (초)
  static const int receiveTimeoutSeconds = 3;
  
  /// 요청 재시도 횟수
  static const int maxRetries = 3;
  
  /// API 버전
  static const String apiVersion = 'v1';
  
  /// 지원되는 언어 코드
  static const List<String> supportedLocales = ['ko', 'en'];
  
  /// 기본 언어 코드
  static const String defaultLocale = 'ko';
}