// lib/config/api_config.dart

import 'package:flutter/foundation.dart';

/// API 설정 클래스
/// 
/// 서버 URL, 타임아웃 등 API 관련 설정을 관리합니다.
class ApiConfig {
  /// 개발 서버 URL (모바일 기기에서 접근 가능한 로컬 네트워크 IP 사용)
  /// Note: localhost는 모바일 기기에서 접근할 수 없으므로 실제 머신의 IP를 사용해야 함
  /// 개발 시에는 실제 서버가 실행 중인 머신의 IP 주소로 변경 필요
  static const String _devBaseUrl = 'http://172.30.1.29:3000/api/v1';
  
  /// 웹용 개발 서버 URL (프록시 사용)
  static const String _webDevBaseUrl = '/api/v1';
  
  /// 프로덕션 서버 URL
  static const String _prodBaseUrl = 'https://api.paperly.com/api/v1';
  
  /// 현재 환경에 따른 서버 URL 반환
  static String get baseUrl {
    // 프로덕션 환경 체크
    if (kReleaseMode) {
      return _prodBaseUrl;
    }
    
    // 개발 환경에서는 모바일, 웹 모두 직접 백엔드 서버 연결
    return _devBaseUrl;
    
    // 기존 웹 프록시 코드 주석 처리
    // if (kIsWeb) {
    //   return _webDevBaseUrl;
    // }
  }
  
  /// 연결 타임아웃 (초)
  static const int connectTimeoutSeconds = 10;
  
  /// 수신 타임아웃 (초)
  static const int receiveTimeoutSeconds = 10;
  
  /// 요청 재시도 횟수
  static const int maxRetries = 3;
  
  /// API 버전
  static const String apiVersion = 'v1';
  
  /// 지원되는 언어 코드
  static const List<String> supportedLocales = ['ko', 'en'];
  
  /// 기본 언어 코드
  static const String defaultLocale = 'ko';
  
  /// 디버그 정보 출력
  static void printDebugInfo() {
    if (kDebugMode) {
      print('🌐 API Config:');
      print('   - Base URL: $baseUrl');
      print('   - Is Web: $kIsWeb');
      print('   - Is Release: $kReleaseMode');
      print('   - Connect Timeout: ${connectTimeoutSeconds}s');
      print('   - Receive Timeout: ${receiveTimeoutSeconds}s');
    }
  }
}