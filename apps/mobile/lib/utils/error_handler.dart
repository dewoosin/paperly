/// Paperly Mobile App - 통합 에러 핸들링 시스템
/// 
/// 앱 전체에서 일관된 에러 처리와 사용자 경험을 제공하기 위한 통합 시스템입니다.
/// 모든 스크린과 서비스에서 동일한 에러 처리 패턴을 사용할 수 있도록 합니다.

import 'package:flutter/material.dart';
import '../services/error_translation_service.dart';
import '../utils/logger.dart';

/// 에러 유형 정의
/// 
/// 서로 다른 에러 상황에 맞는 적절한 UI와 처리 방식을 결정하는 데 사용됩니다.
enum ErrorType {
  /// 네트워크 관련 에러 (연결 실패, 타임아웃 등)
  network,
  
  /// 인증 관련 에러 (로그인 실패, 토큰 만료 등)
  authentication,
  
  /// 입력 유효성 검증 에러 (잘못된 이메일, 비밀번호 형식 등)
  validation,
  
  /// 서버 에러 (500, 503 등)
  server,
  
  /// 일반적인 에러 (기타 모든 에러)
  general,
}

/// 에러 표시 방식 정의
/// 
/// 상황에 맞는 적절한 에러 표시 방법을 선택할 수 있도록 합니다.
enum ErrorDisplayType {
  /// 하단에서 올라오는 스낵바 (간단한 알림용)
  snackbar,
  
  /// 화면 내 인라인 에러 메시지 (폼 검증 등)
  inline,
  
  /// 모달 다이얼로그 (중요한 에러, 사용자 확인 필요)
  dialog,
  
  /// 전체 화면 에러 (치명적인 에러, 앱 사용 불가)
  fullscreen,
}

/// 통합 에러 상태 클래스
/// 
/// 에러의 모든 정보를 담고 있으며, UI 렌더링과 사용자 액션에 필요한 데이터를 제공합니다.
class ErrorState {
  /// 사용자에게 표시할 에러 메시지
  final String? message;
  
  /// 에러의 유형 (UI 스타일 결정에 사용)
  final ErrorType type;
  
  /// 로딩 중인지 여부 (에러 발생 시에도 재시도 로딩 표시 가능)
  final bool isLoading;
  
  /// 재시도 함수 (사용자가 다시 시도할 수 있는 경우)
  final VoidCallback? retry;
  
  /// 추가 컨텍스트 정보 (디버깅 및 로깅용)
  final Map<String, dynamic>? context;
  
  const ErrorState({
    this.message,
    this.type = ErrorType.general,
    this.isLoading = false,
    this.retry,
    this.context,
  });
  
  /// 에러가 없는 정상 상태
  const ErrorState.none() : this();
  
  /// 네트워크 에러 생성
  ErrorState.network({
    required String message,
    VoidCallback? retry,
    Map<String, dynamic>? context,
  }) : this(
    message: message,
    type: ErrorType.network,
    retry: retry,
    context: context,
  );
  
  /// 인증 에러 생성
  ErrorState.authentication({
    required String message,
    Map<String, dynamic>? context,
  }) : this(
    message: message,
    type: ErrorType.authentication,
    context: context,
  );
  
  /// 유효성 검증 에러 생성
  ErrorState.validation({
    required String message,
    Map<String, dynamic>? context,
  }) : this(
    message: message,
    type: ErrorType.validation,
    context: context,
  );
  
  /// 에러가 있는지 확인
  bool get hasError => message != null && message!.isNotEmpty;
  
  /// 재시도 가능한지 확인
  bool get canRetry => retry != null;
  
  /// 새로운 상태로 복사 (불변성 유지)
  ErrorState copyWith({
    String? message,
    ErrorType? type,
    bool? isLoading,
    VoidCallback? retry,
    Map<String, dynamic>? context,
  }) {
    return ErrorState(
      message: message ?? this.message,
      type: type ?? this.type,
      isLoading: isLoading ?? this.isLoading,
      retry: retry ?? this.retry,
      context: context ?? this.context,
    );
  }
}

/// 스크린에서 사용할 수 있는 에러 핸들링 믹스인
/// 
/// 모든 스크린에서 일관된 에러 처리를 할 수 있도록 공통 기능을 제공합니다.
/// 사용법: `with ErrorHandlerMixin<MyScreenWidget>`
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// 현재 에러 상태
  ErrorState _errorState = const ErrorState.none();
  
  /// 현재 에러 상태 getter
  ErrorState get errorState => _errorState;
  
  /// 에러 표시
  /// 
  /// 다양한 방식으로 에러를 사용자에게 표시할 수 있습니다.
  /// 에러 유형에 따라 적절한 표시 방식이 자동으로 선택됩니다.
  void showError(
    String message, {
    ErrorType type = ErrorType.general,
    ErrorDisplayType? displayType,
    VoidCallback? retry,
    Map<String, dynamic>? context,
  }) {
    setState(() {
      _errorState = ErrorState(
        message: message,
        type: type,
        retry: retry,
        context: context,
      );
    });
    
    // 에러 로깅
    logger.e('Error displayed: $message', error: {
      'type': type.toString(),
      'context': context,
      'screen': widget.runtimeType.toString(),
    });
    
    // 표시 방식 결정 (지정되지 않은 경우 에러 유형에 따라 자동 선택)
    final actualDisplayType = displayType ?? _getDefaultDisplayType(type);
    
    // 에러 표시
    _displayError(_errorState, actualDisplayType);
  }
  
  /// 에러 상태 초기화
  void clearError() {
    setState(() {
      _errorState = const ErrorState.none();
    });
  }
  
  /// 성공 메시지 표시
  void showSuccessMessage(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFF7D8B8C), // MujiTheme.sage
      textColor: Colors.white,
      icon: Icons.check_circle_outline,
    );
  }
  
  /// 로딩 상태 토글
  void toggleLoading(bool isLoading) {
    setState(() {
      _errorState = _errorState.copyWith(isLoading: isLoading);
    });
  }
  
  /// 예외를 ErrorState로 변환
  ErrorState convertExceptionToErrorState(
    dynamic exception, {
    VoidCallback? retry,
    Map<String, dynamic>? context,
  }) {
    String message;
    ErrorType type;
    
    // 예외 유형에 따른 메시지 및 타입 결정
    if (exception.toString().contains('네트워크') || 
        exception.toString().contains('network') ||
        exception.toString().contains('connection')) {
      message = ErrorTranslationService.translate('NETWORK.CONNECTION_ERROR');
      type = ErrorType.network;
    } else if (exception.toString().contains('인증') || 
               exception.toString().contains('authentication') ||
               exception.toString().contains('unauthorized')) {
      message = ErrorTranslationService.translate('AUTH.INVALID_CREDENTIALS');
      type = ErrorType.authentication;
    } else if (exception.toString().contains('유효성') || 
               exception.toString().contains('validation')) {
      message = exception.toString();
      type = ErrorType.validation;
    } else {
      // ErrorTranslationService를 통한 번역 시도
      message = ErrorTranslationService.translateError(exception);
      type = ErrorType.general;
    }
    
    return ErrorState(
      message: message,
      type: type,
      retry: retry,
      context: context,
    );
  }
  
  /// 에러 유형에 따른 기본 표시 방식 결정
  ErrorDisplayType _getDefaultDisplayType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return ErrorDisplayType.snackbar;
      case ErrorType.authentication:
        return ErrorDisplayType.dialog;
      case ErrorType.validation:
        return ErrorDisplayType.inline;
      case ErrorType.server:
        return ErrorDisplayType.dialog;
      case ErrorType.general:
        return ErrorDisplayType.snackbar;
    }
  }
  
  /// 실제 에러 표시 수행
  void _displayError(ErrorState errorState, ErrorDisplayType displayType) {
    switch (displayType) {
      case ErrorDisplayType.snackbar:
        _showSnackBar(
          errorState.message!,
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          action: errorState.canRetry ? SnackBarAction(
            label: '다시 시도',
            textColor: Colors.white,
            onPressed: errorState.retry!,
          ) : null,
        );
        break;
        
      case ErrorDisplayType.dialog:
        _showDialog(errorState);
        break;
        
      case ErrorDisplayType.inline:
      case ErrorDisplayType.fullscreen:
        // 인라인과 전체화면은 위젯으로 처리 (showError 호출 후 UI에서 errorState 확인)
        break;
    }
  }
  
  /// 스낵바 표시
  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    SnackBarAction? action,
  }) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: action,
      ),
    );
  }
  
  /// 다이얼로그 표시
  void _showDialog(ErrorState errorState) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _getErrorIcon(errorState.type),
              color: _getErrorColor(errorState.type),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              '오류',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          errorState.message!,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          if (errorState.canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                errorState.retry!();
              },
              child: const Text('다시 시도'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
  
  /// 에러 유형별 아이콘
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.server:
        return Icons.dns_outlined;
      case ErrorType.general:
        return Icons.error_outline;
    }
  }
  
  /// 에러 유형별 색상
  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.purple;
      case ErrorType.general:
        return Colors.red;
    }
  }
}

/// 인라인 에러 표시 위젯
/// 
/// 폼이나 입력 필드 근처에서 사용할 수 있는 에러 표시 컴포넌트입니다.
class InlineErrorWidget extends StatelessWidget {
  final ErrorState errorState;
  
  const InlineErrorWidget({
    Key? key,
    required this.errorState,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!errorState.hasError) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorState.message!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (errorState.canRetry) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: errorState.retry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 전체 화면 에러 위젯
/// 
/// 치명적인 에러나 앱 전체에 영향을 주는 에러에 사용됩니다.
class FullScreenErrorWidget extends StatelessWidget {
  final ErrorState errorState;
  
  const FullScreenErrorWidget({
    Key? key,
    required this.errorState,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF7), // MujiTheme.bg
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                '오류가 발생했습니다',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                errorState.message ?? '알 수 없는 오류가 발생했습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (errorState.canRetry)
                ElevatedButton.icon(
                  onPressed: errorState.retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7D8B8C), // MujiTheme.sage
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}