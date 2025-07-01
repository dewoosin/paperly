/// 오류 코드 번역 서비스
/// 백엔드의 메시지 코드를 사용자 친화적인 한국어 메시지로 변환합니다.
class ErrorTranslationService {
  static const Map<String, String> _errorMessages = {
    // 인증 관련 에러
    'AUTH.LOGIN_SUCCESS': '로그인 성공',
    'AUTH.LOGIN_FAILED': '이메일 또는 비밀번호가 올바르지 않습니다.',
    'AUTH.USER_NOT_FOUND': '등록되지 않은 이메일입니다.',
    'AUTH.INVALID_PASSWORD': '비밀번호가 올바르지 않습니다.',
    'AUTH.EMAIL_NOT_VERIFIED': '이메일 인증이 필요합니다.',
    'AUTH.ACCOUNT_LOCKED': '계정이 잠겨있습니다. 고객센터에 문의하세요.',
    'AUTH.TOKEN_EXPIRED': '로그인이 만료되었습니다. 다시 로그인해주세요.',
    'AUTH.TOKEN_INVALID': '유효하지 않은 토큰입니다.',
    'AUTH.REFRESH_TOKEN_EXPIRED': '세션이 만료되었습니다. 다시 로그인해주세요.',
    'AUTH.LOGOUT_SUCCESS': '로그아웃되었습니다.',
    
    // 회원가입 관련 에러
    'REGISTER.SUCCESS': '회원가입이 완료되었습니다.',
    'REGISTER.EMAIL_EXISTS': '이미 사용 중인 이메일입니다.',
    'REGISTER.USERNAME_EXISTS': '이미 사용 중인 사용자명입니다.',
    'REGISTER.INVALID_EMAIL': '유효하지 않은 이메일 형식입니다.',
    'REGISTER.WEAK_PASSWORD': '비밀번호가 너무 약합니다. 8자 이상, 대소문자, 숫자, 특수문자를 포함해주세요.',
    'REGISTER.FAILED': '회원가입에 실패했습니다. 다시 시도해주세요.',
    
    // 이메일 인증 관련
    'EMAIL.VERIFICATION_SENT': '인증 메일이 발송되었습니다.',
    'EMAIL.VERIFICATION_SUCCESS': '이메일 인증이 완료되었습니다.',
    'EMAIL.VERIFICATION_FAILED': '이메일 인증에 실패했습니다.',
    'EMAIL.VERIFICATION_EXPIRED': '인증 링크가 만료되었습니다. 다시 요청해주세요.',
    'EMAIL.ALREADY_VERIFIED': '이미 인증된 이메일입니다.',
    
    // 프로필 관련
    'PROFILE.UPDATE_SUCCESS': '프로필이 업데이트되었습니다.',
    'PROFILE.UPDATE_FAILED': '프로필 업데이트에 실패했습니다.',
    'PROFILE.INVALID_DATA': '유효하지 않은 프로필 정보입니다.',
    
    // 글 작성 관련
    'ARTICLE.CREATE_SUCCESS': '글이 작성되었습니다.',
    'ARTICLE.CREATE_FAILED': '글 작성에 실패했습니다.',
    'ARTICLE.UPDATE_SUCCESS': '글이 수정되었습니다.',
    'ARTICLE.UPDATE_FAILED': '글 수정에 실패했습니다.',
    'ARTICLE.DELETE_SUCCESS': '글이 삭제되었습니다.',
    'ARTICLE.DELETE_FAILED': '글 삭제에 실패했습니다.',
    'ARTICLE.NOT_FOUND': '글을 찾을 수 없습니다.',
    'ARTICLE.PERMISSION_DENIED': '글을 수정할 권한이 없습니다.',
    
    // 네트워크 관련
    'NETWORK.CONNECTION_ERROR': '네트워크 연결을 확인해주세요.',
    'NETWORK.TIMEOUT': '요청 시간이 초과되었습니다. 다시 시도해주세요.',
    'NETWORK.SERVER_ERROR': '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
    
    // 일반적인 에러
    'VALIDATION.REQUIRED_FIELD': '필수 입력 항목입니다.',
    'VALIDATION.INVALID_FORMAT': '올바르지 않은 형식입니다.',
    'PERMISSION.DENIED': '권한이 없습니다.',
    'RATE_LIMIT.EXCEEDED': '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
    
    // 기본 메시지
    'UNKNOWN_ERROR': '알 수 없는 오류가 발생했습니다.',
  };

  /// 백엔드 메시지 코드를 사용자 친화적인 메시지로 변환
  /// 
  /// [code] 백엔드에서 전달받은 메시지 코드
  /// [fallbackMessage] 코드가 없을 때 사용할 기본 메시지
  static String translate(String? code, [String? fallbackMessage]) {
    if (code == null || code.isEmpty) {
      return fallbackMessage ?? _errorMessages['UNKNOWN_ERROR']!;
    }

    return _errorMessages[code] ?? fallbackMessage ?? _errorMessages['UNKNOWN_ERROR']!;
  }

  /// API 응답에서 에러 메시지 추출 및 번역
  /// 
  /// [response] API 응답 데이터
  /// [fallbackMessage] 기본 메시지
  static String translateFromResponse(Map<String, dynamic>? response, [String? fallbackMessage]) {
    if (response == null) {
      return fallbackMessage ?? _errorMessages['UNKNOWN_ERROR']!;
    }

    // 백엔드 응답 구조: { "success": false, "code": "ERROR_CODE", "message": "..." }
    final code = response['code'] as String?;
    final message = response['message'] as String?;
    
    // 1. 메시지 코드로 번역 시도
    if (code != null) {
      final translatedMessage = _errorMessages[code];
      if (translatedMessage != null) {
        return translatedMessage;
      }
    }
    
    // 2. 백엔드 메시지 사용
    if (message != null && message.isNotEmpty) {
      return message;
    }
    
    // 3. 기본 메시지 사용
    return fallbackMessage ?? _errorMessages['UNKNOWN_ERROR']!;
  }

  /// HTTP 상태 코드에 따른 기본 메시지 제공
  /// 
  /// [statusCode] HTTP 상태 코드
  static String getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case 403:
        return '권한이 없습니다.';
      case 404:
        return '요청한 정보를 찾을 수 없습니다.';
      case 409:
        return '이미 존재하는 데이터입니다.';
      case 422:
        return '입력 정보를 확인해주세요.';
      case 429:
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 500:
        return '서버 오류가 발생했습니다.';
      case 502:
        return '서버에 연결할 수 없습니다.';
      case 503:
        return '서비스가 일시적으로 이용할 수 없습니다.';
      default:
        return '오류가 발생했습니다. (${statusCode})';
    }
  }

  /// 일반 에러에서 메시지 추출 및 번역
  /// 
  /// [error] Exception 또는 기타 에러
  static String translateFromError(dynamic error) {
    if (error == null) {
      return _errorMessages['UNKNOWN_ERROR']!;
    }

    // 일반 예외의 경우 문자열에서 메시지 추출
    final errorString = error.toString();
    
    // "Exception: " 접두사 제거
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring(11);
    }
    
    // "ApiException" 형태의 에러인 경우
    if (errorString.contains('ApiException')) {
      // 상태 코드 추출 시도
      final match = RegExp(r'ApiException\((\d+)\)').firstMatch(errorString);
      if (match != null) {
        final statusCode = int.tryParse(match.group(1) ?? '');
        if (statusCode != null) {
          return getHttpErrorMessage(statusCode);
        }
      }
    }
    
    return errorString.isNotEmpty ? errorString : _errorMessages['UNKNOWN_ERROR']!;
  }

  /// 성공 메시지 번역
  /// 
  /// [code] 성공 코드
  static String translateSuccess(String? code) {
    if (code == null) return '작업이 완료되었습니다.';
    
    return _errorMessages[code] ?? '작업이 완료되었습니다.';
  }
}