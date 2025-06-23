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
    level: kDebugMode ? Level.verbose : Level.warning,
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
    Level.verbose: '💬',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.wtf: '💥',
  };
  
  static final Map<Level, String> _levelLabels = {
    Level.verbose: 'VERBOSE',
    Level.debug: 'DEBUG',
    Level.info: 'INFO',
    Level.warning: 'WARNING',
    Level.error: 'ERROR',
    Level.wtf: 'WTF',
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
    d('🌐 API Request: $method $path', data);
  }
  
  /// API 응답 로그
  void apiResponse(String method, String path, int statusCode, {dynamic data}) {
    if (statusCode >= 200 && statusCode < 300) {
      d('✅ API Response: $method $path - $statusCode', data);
    } else {
      w('⚠️ API Response: $method $path - $statusCode', data);
    }
  }
  
  /// 네비게이션 로그
  void navigation(String route, {Map<String, dynamic>? params}) {
    d('🧭 Navigation: $route', params);
  }
  
  /// 사용자 액션 로그
  void userAction(String action, {Map<String, dynamic>? details}) {
    i('👆 User Action: $action', details);
  }
  
  /// 성능 측정 로그
  void performance(String operation, Duration duration, {Map<String, dynamic>? extra}) {
    d('⏱️ Performance: $operation took ${duration.inMilliseconds}ms', extra);
  }
  
  /// 분석 이벤트 로그
  void analytics(String event, {Map<String, dynamic>? properties}) {
    v('📊 Analytics: $event', properties);
  }
}