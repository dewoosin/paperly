/**
 * BaseError.ts
 * 
 * 애플리케이션 전체에서 사용되는 기본 에러 클래스
 * 모든 커스텀 에러는 이 클래스를 상속받아 구현
 */

export enum ErrorCode {
  // 인증 관련 (1000번대)
  UNAUTHORIZED = 'AUTH_001',
  INVALID_CREDENTIALS = 'AUTH_002',
  TOKEN_EXPIRED = 'AUTH_003',
  TOKEN_INVALID = 'AUTH_004',
  
  // 유효성 검사 (2000번대)
  VALIDATION_ERROR = 'VAL_001',
  INVALID_INPUT = 'VAL_002',
  MISSING_REQUIRED_FIELD = 'VAL_003',
  
  // 비즈니스 로직 (3000번대)
  BUSINESS_RULE_VIOLATION = 'BIZ_001',
  RESOURCE_NOT_FOUND = 'BIZ_002',
  DUPLICATE_RESOURCE = 'BIZ_003',
  OPERATION_NOT_ALLOWED = 'BIZ_004',
  
  // 외부 서비스 (4000번대)
  EXTERNAL_SERVICE_ERROR = 'EXT_001',
  DATABASE_ERROR = 'EXT_002',
  OPENAI_API_ERROR = 'EXT_003',
  STORAGE_ERROR = 'EXT_004',
  
  // 시스템 (5000번대)
  INTERNAL_SERVER_ERROR = 'SYS_001',
  SERVICE_UNAVAILABLE = 'SYS_002',
  
  // 사용자 관련 (6000번대)
  USER_NOT_FOUND = 'USER_001',
  USER_ALREADY_EXISTS = 'USER_002',
  INVALID_USER_STATUS = 'USER_003',
  
  // 기사 관련 (7000번대)
  ARTICLE_NOT_FOUND = 'ART_001',
  ARTICLE_ACCESS_DENIED = 'ART_002',
  INVALID_ARTICLE_STATUS = 'ART_003',
}

/**
 * HTTP 상태 코드 매핑
 */
const ErrorStatusMap: Record<ErrorCode, number> = {
  // 401 Unauthorized
  [ErrorCode.UNAUTHORIZED]: 401,
  [ErrorCode.INVALID_CREDENTIALS]: 401,
  [ErrorCode.TOKEN_EXPIRED]: 401,
  [ErrorCode.TOKEN_INVALID]: 401,
  
  // 400 Bad Request
  [ErrorCode.VALIDATION_ERROR]: 400,
  [ErrorCode.INVALID_INPUT]: 400,
  [ErrorCode.MISSING_REQUIRED_FIELD]: 400,
  [ErrorCode.BUSINESS_RULE_VIOLATION]: 400,
  
  // 404 Not Found
  [ErrorCode.RESOURCE_NOT_FOUND]: 404,
  [ErrorCode.USER_NOT_FOUND]: 404,
  [ErrorCode.ARTICLE_NOT_FOUND]: 404,
  
  // 409 Conflict
  [ErrorCode.DUPLICATE_RESOURCE]: 409,
  [ErrorCode.USER_ALREADY_EXISTS]: 409,
  
  // 403 Forbidden
  [ErrorCode.OPERATION_NOT_ALLOWED]: 403,
  [ErrorCode.ARTICLE_ACCESS_DENIED]: 403,
  
  // 503 Service Unavailable
  [ErrorCode.EXTERNAL_SERVICE_ERROR]: 503,
  [ErrorCode.SERVICE_UNAVAILABLE]: 503,
  
  // 500 Internal Server Error
  [ErrorCode.INTERNAL_SERVER_ERROR]: 500,
  [ErrorCode.DATABASE_ERROR]: 500,
  [ErrorCode.OPENAI_API_ERROR]: 500,
  [ErrorCode.STORAGE_ERROR]: 500,
  [ErrorCode.INVALID_USER_STATUS]: 500,
  [ErrorCode.INVALID_ARTICLE_STATUS]: 500,
};

/**
 * 기본 에러 클래스
 * 
 * @example
 * throw new BaseError(
 *   'User not found',
 *   ErrorCode.USER_NOT_FOUND,
 *   { userId: 123 }
 * );
 */
export class BaseError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly timestamp: Date;
  public readonly details?: any;

  constructor(
    message: string,
    code: ErrorCode,
    details?: any,
    isOperational: boolean = true
  ) {
    super(message);
    
    // Error 클래스를 상속받을 때 필요한 설정
    Object.setPrototypeOf(this, BaseError.prototype);
    
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = ErrorStatusMap[code] || 500;
    this.isOperational = isOperational;
    this.timestamp = new Date();
    this.details = details;
    
    // 스택 트레이스 캡처 (프로덕션에서는 제거 가능)
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * 에러 객체를 JSON으로 변환
   */
  public toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      timestamp: this.timestamp,
      details: this.details,
      // 개발 환경에서만 스택 포함
      ...(process.env.NODE_ENV === 'development' && { stack: this.stack }),
    };
  }
}

/**
 * 특정 도메인 에러들
 */

// 인증 에러
export class AuthenticationError extends BaseError {
  constructor(message: string = 'Authentication failed', details?: any) {
    super(message, ErrorCode.UNAUTHORIZED, details);
  }
}

// 유효성 검사 에러
export class ValidationError extends BaseError {
  constructor(message: string, details?: any) {
    super(message, ErrorCode.VALIDATION_ERROR, details);
  }
}

// 리소스 찾을 수 없음 에러
export class NotFoundError extends BaseError {
  constructor(resource: string, details?: any) {
    super(`${resource} not found`, ErrorCode.RESOURCE_NOT_FOUND, details);
  }
}

// 중복 리소스 에러
export class DuplicateError extends BaseError {
  constructor(resource: string, details?: any) {
    super(`${resource} already exists`, ErrorCode.DUPLICATE_RESOURCE, details);
  }
}

// 비즈니스 규칙 위반 에러
export class BusinessRuleError extends BaseError {
  constructor(message: string, details?: any) {
    super(message, ErrorCode.BUSINESS_RULE_VIOLATION, details);
  }
}

// 외부 서비스 에러
export class ExternalServiceError extends BaseError {
  constructor(service: string, message: string, details?: any) {
    super(`External service error (${service}): ${message}`, ErrorCode.EXTERNAL_SERVICE_ERROR, details);
  }
}
