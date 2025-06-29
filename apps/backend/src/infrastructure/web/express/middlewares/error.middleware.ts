import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../../logging/Logger';
import { ResponseUtil } from '../../../../shared/utils/response.util';
import { MessageService } from '../../../services/message.service';
import { MESSAGE_CODES } from '../../../../shared/constants/message-codes';
import { container } from 'tsyringe';

const logger = new Logger('ErrorMiddleware');

/**
 * Express 에러 처리 미들웨어
 * 
 * 모든 에러를 캡처하여 일관된 형식으로 응답합니다.
 * 메시지 코드 시스템을 사용하여 다국어 지원이 가능합니다.
 */
export function errorMiddleware(
  err: any, 
  req: Request, 
  res: Response, 
  next: NextFunction
): void {
  // ResponseUtil 인스턴스 가져오기
  const responseUtil = container.resolve<ResponseUtil>('ResponseUtil');
  
  // 이미 응답이 전송된 경우 처리하지 않음
  if (res.headersSent) {
    return next(err);
  }

  // 에러 로깅
  logger.error('Unhandled error:', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    body: req.body,
    ip: req.ip
  });

  // 에러 타입별 처리
  handleError(err, req, res, responseUtil);
}

/**
 * 에러 타입별 처리 함수
 */
async function handleError(
  err: any, 
  req: Request, 
  res: Response, 
  responseUtil: ResponseUtil
): Promise<void> {
  // 유효성 검사 에러
  if (err.name === 'ValidationError' || err.type === 'validation') {
    await responseUtil.validationError(res, err.errors || {
      validation: err.message
    });
    return;
  }

  // JWT 에러
  if (err.name === 'JsonWebTokenError') {
    await responseUtil.authError(res, MESSAGE_CODES.AUTH.INVALID_TOKEN);
    return;
  }

  // JWT 만료 에러
  if (err.name === 'TokenExpiredError') {
    await responseUtil.authError(res, MESSAGE_CODES.AUTH.TOKEN_EXPIRED);
    return;
  }

  // 권한 없음 에러
  if (err.name === 'UnauthorizedError' || err.status === 401) {
    await responseUtil.authError(res);
    return;
  }

  // 접근 거부 에러
  if (err.name === 'ForbiddenError' || err.status === 403) {
    await responseUtil.forbiddenError(res);
    return;
  }

  // Not Found 에러
  if (err.name === 'NotFoundError' || err.status === 404) {
    await responseUtil.notFoundError(res);
    return;
  }

  // 데이터베이스 에러
  if (err.code && err.code.startsWith('23')) {
    // PostgreSQL 에러 코드
    if (err.code === '23505') {
      // Unique constraint violation
      await responseUtil.error(res, MESSAGE_CODES.SYSTEM.BAD_REQUEST, {
        constraint: err.constraint,
        detail: err.detail
      });
    } else {
      await responseUtil.error(res, MESSAGE_CODES.SYSTEM.CANNOT_PROCESS_REQUEST);
    }
    return;
  }

  // 비즈니스 로직 에러 (메시지 코드가 포함된 경우)
  if (err.messageCode) {
    await responseUtil.error(res, err.messageCode, err.details);
    return;
  }

  // 알려진 에러 메시지 매핑
  const errorMessageMap: Record<string, string> = {
    '이미 사용 중인 이메일입니다': MESSAGE_CODES.AUTH.EMAIL_EXISTS,
    '이메일 또는 비밀번호가 올바르지 않습니다': MESSAGE_CODES.AUTH.INVALID_CREDENTIALS,
    '유효하지 않은 토큰입니다': MESSAGE_CODES.AUTH.INVALID_TOKEN,
    '토큰이 만료되었습니다': MESSAGE_CODES.AUTH.TOKEN_EXPIRED,
    '권한이 없습니다': MESSAGE_CODES.AUTH.ACCESS_DENIED,
    '사용자를 찾을 수 없습니다': MESSAGE_CODES.USER.NOT_FOUND,
    '글을 찾을 수 없습니다': MESSAGE_CODES.ARTICLE.NOT_FOUND,
    '카테고리를 찾을 수 없습니다': MESSAGE_CODES.CATEGORY.NOT_FOUND,
    '파일 크기가 너무 큽니다': MESSAGE_CODES.VALIDATION.FILE_TOO_LARGE,
    '지원하지 않는 파일 형식입니다': MESSAGE_CODES.VALIDATION.UNSUPPORTED_FILE_FORMAT,
  };

  // 에러 메시지로 메시지 코드 찾기
  for (const [message, code] of Object.entries(errorMessageMap)) {
    if (err.message && err.message.includes(message)) {
      await responseUtil.error(res, code);
      return;
    }
  }

  // 기본 서버 에러
  await responseUtil.serverError(res, err);
}

/**
 * 404 Not Found 미들웨어
 * 
 * 라우트를 찾을 수 없을 때 사용됩니다.
 */
export function notFoundMiddleware(
  req: Request, 
  res: Response, 
  next: NextFunction
): void {
  const responseUtil = container.resolve<ResponseUtil>('ResponseUtil');
  
  logger.warn('Route not found:', {
    path: req.path,
    method: req.method,
    ip: req.ip
  });

  responseUtil.notFoundError(res).catch(err => {
    logger.error('Error in notFoundMiddleware:', err);
    res.status(404).json({
      success: false,
      code: MESSAGE_CODES.SYSTEM.RESOURCE_NOT_FOUND,
      message: `Route ${req.method} ${req.path} not found`
    });
  });
}