// /Users/workspace/paperly/apps/backend/src/shared/errors/index.ts

/**
 * 애플리케이션 전역 에러 클래스들
 * 
 * HTTP 상태 코드와 매핑되는 비즈니스 에러들을 정의합니다.
 */

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
 * 모든 커스텀 에러의 부모 클래스
 */
export abstract class BaseError extends Error {
    public code: string;
    public readonly statusCode: number;
    public readonly timestamp: Date;
    public readonly details?: any;
    public readonly messageCode?: string;
  
    constructor(
      message: string,
      code: string,
      statusCode: number,
      details?: any,
      messageCode?: string
    ) {
      super(message);
      this.name = this.constructor.name;
      this.code = code;
      this.statusCode = statusCode;
      this.timestamp = new Date();
      this.details = details;
      this.messageCode = messageCode;
  
      // Error 클래스를 상속할 때 필요한 처리
      Object.setPrototypeOf(this, new.target.prototype);
      Error.captureStackTrace(this, this.constructor);
    }
  
    toJSON() {
      return {
        name: this.name,
        code: this.code,
        message: this.message,
        statusCode: this.statusCode,
        timestamp: this.timestamp,
        details: this.details,
        messageCode: this.messageCode,
      };
    }
  }
  
/**
 * 400 Bad Request
 * 잘못된 요청 데이터
 */
export class BadRequestError extends BaseError {
  constructor(message: string, details?: any, messageCode?: string) {
    super(message, 'BAD_REQUEST', 400, details, messageCode);
  }
}

/**
 * 401 Unauthorized
 * 인증 실패
 */
export class UnauthorizedError extends BaseError {
  constructor(message: string = '인증이 필요합니다', details?: any, messageCode?: string) {
    super(message, 'UNAUTHORIZED', 401, details, messageCode);
  }
}

/**
 * 403 Forbidden
 * 권한 없음
 */
export class ForbiddenError extends BaseError {
  constructor(message: string = '접근 권한이 없습니다', details?: any, messageCode?: string) {
    super(message, 'FORBIDDEN', 403, details, messageCode);
  }
}

/**
 * 404 Not Found
 * 리소스를 찾을 수 없음
 */
export class NotFoundError extends BaseError {
  constructor(message: string = '요청한 리소스를 찾을 수 없습니다', details?: any, messageCode?: string) {
    super(message, 'NOT_FOUND', 404, details, messageCode);
  }
}

/**
 * 409 Conflict
 * 리소스 충돌 (중복 등)
 */
export class ConflictError extends BaseError {
  constructor(message: string, details?: any, messageCode?: string) {
    super(message, 'CONFLICT', 409, details, messageCode);
  }
}
  
/**
 * 422 Unprocessable Entity
 * 처리할 수 없는 엔티티 (비즈니스 로직 검증 실패)
 */
export class UnprocessableEntityError extends BaseError {
  constructor(message: string, details?: any, messageCode?: string) {
    super(message, 'UNPROCESSABLE_ENTITY', 422, details, messageCode);
  }
}

/**
 * 429 Too Many Requests
 * 요청 제한 초과
 */
export class TooManyRequestsError extends BaseError {
  constructor(message: string = '너무 많은 요청입니다. 잠시 후 다시 시도해주세요', details?: any, messageCode?: string) {
    super(message, 'TOO_MANY_REQUESTS', 429, details, messageCode);
  }
}

/**
 * 500 Internal Server Error
 * 서버 내부 오류
 */
export class InternalServerError extends BaseError {
  constructor(message: string = '서버 오류가 발생했습니다', details?: any, messageCode?: string) {
    super(message, 'INTERNAL_SERVER_ERROR', 500, details, messageCode);
  }
}

/**
 * 503 Service Unavailable
 * 서비스 일시 중단
 */
export class ServiceUnavailableError extends BaseError {
  constructor(message: string = '서비스를 일시적으로 사용할 수 없습니다', details?: any, messageCode?: string) {
    super(message, 'SERVICE_UNAVAILABLE', 503, details, messageCode);
  }
}

/**
 * 데이터베이스 관련 에러
 */
export class DatabaseError extends InternalServerError {
  constructor(message: string = '데이터베이스 오류가 발생했습니다', details?: any, messageCode?: string) {
    super(message, details, messageCode);
    (this as any).code = 'DATABASE_ERROR';
  }
}

/**
 * 외부 서비스 에러
 */
export class ExternalServiceError extends InternalServerError {
  constructor(service: string, message: string, details?: any, messageCode?: string) {
    super(`외부 서비스(${service}) 오류: ${message}`, details, messageCode);
    (this as any).code = 'EXTERNAL_SERVICE_ERROR';
  }
}

/**
 * 검증 에러
 */
export class ValidationError extends BadRequestError {
  constructor(message: string, details?: any, messageCode?: string) {
    super(message, details, messageCode);
    (this as any).code = 'VALIDATION_ERROR';
  }
}

/**
 * 인증 에러
 */
export class AuthenticationError extends UnauthorizedError {
  constructor(message: string = '인증에 실패했습니다', details?: any, messageCode?: string) {
    super(message, details, messageCode);
    (this as any).code = 'AUTHENTICATION_ERROR';
  }
}

/**
 * 토큰 만료 에러
 */
export class TokenExpiredError extends UnauthorizedError {
  constructor(message: string = '토큰이 만료되었습니다', details?: any, messageCode?: string) {
    super(message, details, messageCode);
    (this as any).code = 'TOKEN_EXPIRED';
  }
}

/**
 * 토큰 유효하지 않음 에러
 */
export class InvalidTokenError extends UnauthorizedError {
  constructor(message: string = '유효하지 않은 토큰입니다', details?: any, messageCode?: string) {
    super(message, details, messageCode);
    (this as any).code = 'INVALID_TOKEN';
  }
}