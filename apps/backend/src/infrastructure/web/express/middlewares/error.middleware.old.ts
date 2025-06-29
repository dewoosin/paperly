// /Users/workspace/paperly/apps/backend/src/infrastructure/web/express/middlewares/error.middleware.ts

import { Request, Response, NextFunction } from 'express';
import { BaseError } from '../../../../shared/errors/index';
import { Logger } from '../../../logging/Logger';
import { ZodError } from 'zod';
import { JsonWebTokenError, TokenExpiredError as JWTTokenExpiredError } from 'jsonwebtoken';

const logger = new Logger('ErrorHandler');

/**
 * 에러 응답 인터페이스
 */
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: any;
    timestamp: Date;
    requestId: string;
    path?: string;
    method?: string;
  };
}

/**
 * 글로벌 에러 핸들링 미들웨어
 * 
 * 모든 에러를 catch하여 일관된 형식으로 응답합니다.
 */
export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // 이미 응답이 전송된 경우
  if (res.headersSent) {
    return next(error);
  }

  // 요청 정보
  const requestInfo = {
    path: req.path,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    userId: (req as any).user?.userId
  };

  // BaseError 인스턴스인 경우 (비즈니스 에러)
  if (error instanceof BaseError) {
    logger.error('Business error', {
      ...error.toJSON(),
      request: requestInfo
    });
    
    const response: ErrorResponse = {
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
        timestamp: error.timestamp,
        requestId: (req as any).id || 'unknown',
        path: req.path,
        method: req.method
      }
    };

    res.status(error.statusCode).json(response);
    return;
  }

  // Zod 검증 에러
  if (error instanceof ZodError) {
    logger.warn('Validation error', {
      errors: error.errors,
      request: requestInfo
    });

    const response: ErrorResponse = {
      error: {
        code: 'VALIDATION_ERROR',
        message: '입력값이 올바르지 않습니다',
        details: error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message,
          code: err.code
        })),
        timestamp: new Date(),
        requestId: (req as any).id || 'unknown',
        path: req.path,
        method: req.method
      }
    };

    res.status(400).json(response);
    return;
  }

  // JWT 에러
  if (error instanceof JsonWebTokenError) {
    logger.warn('JWT error', {
      error: error.message,
      request: requestInfo
    });

    let statusCode = 401;
    let code = 'INVALID_TOKEN';
    let message = '유효하지 않은 토큰입니다';

    if (error instanceof JWTTokenExpiredError) {
      code = 'TOKEN_EXPIRED';
      message = '토큰이 만료되었습니다';
    }

    const response: ErrorResponse = {
      error: {
        code,
        message,
        timestamp: new Date(),
        requestId: (req as any).id || 'unknown',
        path: req.path,
        method: req.method
      }
    };

    res.status(statusCode).json(response);
    return;
  }

  // MongoDB/Mongoose 에러 (예시)
  if (error.name === 'MongoError' || error.name === 'ValidationError') {
    logger.error('Database error', {
      error: error.message,
      request: requestInfo
    });

    const response: ErrorResponse = {
      error: {
        code: 'DATABASE_ERROR',
        message: '데이터 처리 중 오류가 발생했습니다',
        timestamp: new Date(),
        requestId: (req as any).id || 'unknown',
        path: req.path,
        method: req.method
      }
    };

    res.status(500).json(response);
    return;
  }

  // 예상치 못한 에러
  logger.error('Unexpected error', {
    error: {
      name: error.name,
      message: error.message,
      stack: error.stack
    },
    request: requestInfo
  });
  
  // 개발 환경에서는 스택 트레이스 포함
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  const response: ErrorResponse = {
    error: {
      code: 'INTERNAL_ERROR',
      message: isDevelopment ? error.message : '서버 오류가 발생했습니다',
      details: isDevelopment ? { stack: error.stack } : undefined,
      timestamp: new Date(),
      requestId: (req as any).id || 'unknown',
      path: req.path,
      method: req.method
    }
  };

  res.status(500).json(response);
}

/**
 * 404 Not Found 핸들러
 * 
 * 매칭되는 라우트가 없을 때 사용됩니다.
 */
export function notFoundHandler(req: Request, res: Response): void {
  const response: ErrorResponse = {
    error: {
      code: 'NOT_FOUND',
      message: `요청하신 경로를 찾을 수 없습니다: ${req.method} ${req.path}`,
      timestamp: new Date(),
      requestId: (req as any).id || 'unknown',
      path: req.path,
      method: req.method
    }
  };

  res.status(404).json(response);
}

/**
 * 비동기 에러 핸들러 래퍼
 * 
 * 비동기 라우트 핸들러의 에러를 자동으로 catch합니다.
 */
export function asyncHandler(fn: Function) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}