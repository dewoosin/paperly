// /Users/workspace/paperly/apps/backend/src/shared/errors/BaseError.ts

/**
 * 에러 코드 enum
 * 
 * 애플리케이션 전체에서 사용되는 에러 코드를 정의합니다.
 */
export enum ErrorCode {
  // 인증 관련
  UNAUTHORIZED = 'UNAUTHORIZED',
  AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  INVALID_TOKEN = 'INVALID_TOKEN',
  
  // 권한 관련
  FORBIDDEN = 'FORBIDDEN',
  INSUFFICIENT_PERMISSIONS = 'INSUFFICIENT_PERMISSIONS',
  
  // 요청 관련
  BAD_REQUEST = 'BAD_REQUEST',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  MISSING_PARAMETER = 'MISSING_PARAMETER',
  INVALID_PARAMETER = 'INVALID_PARAMETER',
  
  // 리소스 관련
  NOT_FOUND = 'NOT_FOUND',
  CONFLICT = 'CONFLICT',
  ALREADY_EXISTS = 'ALREADY_EXISTS',
  
  // 비즈니스 로직
  UNPROCESSABLE_ENTITY = 'UNPROCESSABLE_ENTITY',
  BUSINESS_RULE_VIOLATION = 'BUSINESS_RULE_VIOLATION',
  
  // 외부 서비스
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR',
  TIMEOUT_ERROR = 'TIMEOUT_ERROR',
  
  // 시스템
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  DATABASE_ERROR = 'DATABASE_ERROR',
  SERVICE_UNAVAILABLE = 'SERVICE_UNAVAILABLE',
  
  // Rate Limiting
  TOO_MANY_REQUESTS = 'TOO_MANY_REQUESTS',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED'
}

/**
 * 기본 에러 클래스
 * 
 * 모든 커스텀 에러의 부모 클래스입니다.
 * Error 클래스를 확장하여 추가적인 정보를 포함합니다.
 */
export abstract class BaseError extends Error {
  public readonly code: ErrorCode | string;
  public readonly statusCode: number;
  public readonly timestamp: Date;
  public readonly details?: any;
  public readonly isOperational: boolean;

  /**
   * BaseError 생성자
   * 
   * @param message - 에러 메시지
   * @param code - 에러 코드
   * @param statusCode - HTTP 상태 코드
   * @param details - 추가 상세 정보
   * @param isOperational - 운영상 에러 여부 (예상된 에러인지)
   */
  constructor(
    message: string,
    code: ErrorCode | string = ErrorCode.INTERNAL_ERROR,
    statusCode: number = 500,
    details?: any,
    isOperational: boolean = true
  ) {
    super(message);
    
    // Error 클래스를 상속할 때 필요한 처리
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
    
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
    this.timestamp = new Date();
    this.details = details;
    this.isOperational = isOperational;
  }

  /**
   * JSON 직렬화
   * 
   * 에러 객체를 JSON으로 변환할 때 사용됩니다.
   */
  toJSON() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      statusCode: this.statusCode,
      timestamp: this.timestamp,
      details: this.details,
      stack: this.stack // 개발 환경에서만 포함하도록 수정 가능
    };
  }

  /**
   * 클라이언트에게 전송할 응답 생성
   * 
   * 민감한 정보를 제외한 에러 정보를 반환합니다.
   */
  toClientResponse() {
    return {
      code: this.code,
      message: this.message,
      details: this.details,
      timestamp: this.timestamp
    };
  }

  /**
   * 로깅용 정보 생성
   * 
   * 로그에 기록할 상세 정보를 반환합니다.
   */
  toLogContext() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      statusCode: this.statusCode,
      details: this.details,
      stack: this.stack,
      timestamp: this.timestamp,
      isOperational: this.isOperational
    };
  }

  /**
   * 에러가 재시도 가능한지 확인
   * 
   * 일시적인 에러인 경우 재시도 가능합니다.
   */
  isRetryable(): boolean {
    const retryableCodes = [
      ErrorCode.SERVICE_UNAVAILABLE,
      ErrorCode.TIMEOUT_ERROR,
      ErrorCode.TOO_MANY_REQUESTS
    ];
    
    return retryableCodes.includes(this.code as ErrorCode);
  }

  /**
   * 에러 심각도 레벨
   * 
   * 로깅 및 알림에 사용됩니다.
   */
  getSeverity(): 'low' | 'medium' | 'high' | 'critical' {
    // 운영상 에러가 아닌 경우 높은 심각도
    if (!this.isOperational) {
      return 'critical';
    }

    // 상태 코드별 심각도
    if (this.statusCode >= 500) {
      return 'high';
    } else if (this.statusCode >= 400) {
      return 'medium';
    }
    
    return 'low';
  }
}

/**
 * 에러가 BaseError 인스턴스인지 확인
 */
export function isBaseError(error: any): error is BaseError {
  return error instanceof BaseError;
}

/**
 * 에러가 운영상 에러인지 확인
 */
export function isOperationalError(error: any): boolean {
  if (isBaseError(error)) {
    return error.isOperational;
  }
  return false;
}