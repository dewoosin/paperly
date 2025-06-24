// lib/utils/logger.dart

import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// 앱 전역에서 사용할 로거 인스턴스
final logger = _createLogger();

/// 로거 생성 함수
/// 
/// 개발/프로덕션 환경에 따라 다른 로그 레벨과 출력 방식을 설정합니다.
Logger _createLogger() {
  return Logger(
    printer: _CustomPrinter(),
    level: kDebugMode ? Level.debug : Level.warning,
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
  );
}

/// 커스텀 로그 프린터
/// 
/// 무지 스타일에 맞는 깔끔한 로그 출력 형식을 제공합니다.
class _CustomPrinter extends LogPrinter {
  static const String _topBorder = '┌─────────────────────────────────────────────────────────';
  static const String _middleBorder = '├─────────────────────────────────────────────────────────';
  static const String _bottomBorder = '└─────────────────────────────────────────────────────────';
  
  static final Map<Level, String> _levelEmojis = {
    Level.trace: '🔍',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.fatal: '💥',
  };
  
  static final Map<Level, String> _levelLabels = {
    Level.trace: 'TRACE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARNING',
    Level.error: 'ERROR',
    Level.fatal: 'FATAL',
  };

  @override
  List<String> log(LogEvent event) {
    final emoji = _levelEmojis[event.level] ?? '';
    final label = _levelLabels[event.level] ?? '';
    final message = event.message;
    final error = event.error;
    final stackTrace = event.stackTrace;
    
    final buffer = <String>[];
    
    // 상단 테두리
    buffer.add(_topBorder);
    
    // 로그 레벨과 시간
    final time = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    buffer.add('│ $emoji $label [$time]');
    
    // 메시지
    buffer.add(_middleBorder);
    final messageLines = message.toString().split('\n');
    for (final line in messageLines) {
      buffer.add('│ $line');
    }
    
    // 에러 정보
    if (error != null) {
      buffer.add(_middleBorder);
      buffer.add('│ 🚨 Error: $error');
    }
    
    // 스택 트레이스 (개발 모드에서만)
    if (stackTrace != null && kDebugMode) {
      buffer.add(_middleBorder);
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        buffer.add('│ $line');
      }
      buffer.add('│ ...');
    }
    
    // 하단 테두리
    buffer.add(_bottomBorder);
    
    return buffer;
  }
}

/// 로그 확장 함수들
/// 
/// 특정 도메인이나 기능에 대한 로그를 쉽게 남길 수 있도록 합니다.
extension LoggerExtensions on Logger {
  /// API 요청 로그
  void api(String method, String path, {dynamic data}) {
    d('🌐 API Request: $method $path', error: data);
  }
  
  /// API 응답 로그
  void apiResponse(String method, String path, int statusCode, {dynamic data}) {
    if (statusCode >= 200 && statusCode < 300) {
      d('✅ API Response: $method $path - $statusCode', error: data);
    } else {
      w('⚠️ API Response: $method $path - $statusCode', error: data);
    }
  }
  
  /// 네비게이션 로그
  void navigation(String route, {Map<String, dynamic>? arguments}) {
    i('📱 Navigation: $route', error: arguments);
  }
  
  /// 인증 로그
  void auth(String action, {Map<String, dynamic>? data}) {
    i('🔐 Auth: $action', error: data);
  }
  
  /// 비즈니스 로직 로그
  void business(String action, {dynamic data}) {
    i('💼 Business: $action', error: data);
  }
}