/**
 * error.middleware.ts
 * 글로벌 에러 핸들링 미들웨어
 */

import { Request, Response, NextFunction } from 'express';
import { BaseError } from '../../../../shared/errors/BaseError';
import { Logger } from '../../../logging/Logger';

const logger = new Logger('ErrorHandler');

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

  // BaseError 인스턴스인 경우
  if (error instanceof BaseError) {
    logger.error(`Business error: ${error.message}`, error);
    
    res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        details: error.details,
        timestamp: error.timestamp,
        requestId: req.id,
      },
    });
    return;
  }

  // 예상치 못한 에러
  logger.error('Unexpected error', error);
  
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      timestamp: new Date(),
      requestId: req.id,
    },
  });
}
