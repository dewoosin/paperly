import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../../logging/Logger';

const logger = new Logger('RequestLogger');

/**
 * 상세한 요청 로깅 미들웨어
 * 
 * 모든 HTTP 요청에 대한 상세 정보를 로그로 남깁니다.
 */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const startTime = Date.now();
  
  // 요청 정보 로깅
  logger.info('📥 HTTP Request', {
    requestId: req.id,
    method: req.method,
    url: req.url,
    path: req.path,
    query: req.query,
    headers: {
      'user-agent': req.headers['user-agent'],
      'content-type': req.headers['content-type'],
      'authorization': req.headers.authorization ? 'Bearer ***' : undefined,
      'x-device-id': req.headers['x-device-id'],
      'origin': req.headers.origin,
      'referer': req.headers.referer,
    },
    body: sanitizeBody(req.body),
    ip: req.ip,
    timestamp: new Date().toISOString(),
  });

  // 응답 완료 시 로깅
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const statusCode = res.statusCode;
    
    // 상태 코드에 따른 로그 레벨 결정
    const logLevel = getLogLevel(statusCode);
    const emoji = getStatusEmoji(statusCode);
    
    logger[logLevel](`${emoji} HTTP Response`, {
      requestId: req.id,
      method: req.method,
      url: req.url,
      statusCode,
      duration: `${duration}ms`,
      contentLength: res.get('content-length'),
      timestamp: new Date().toISOString(),
    });
  });

  next();
}

/**
 * 요청 본문에서 민감한 정보를 제거
 */
function sanitizeBody(body: any): any {
  if (!body || typeof body !== 'object') {
    return body;
  }

  const sanitized = { ...body };
  
  // 비밀번호 필드들을 마스킹
  const sensitiveFields = ['password', 'currentPassword', 'newPassword', 'confirmPassword', 'token', 'refreshToken'];
  
  for (const field of sensitiveFields) {
    if (sanitized[field]) {
      sanitized[field] = '***';
    }
  }

  return sanitized;
}

/**
 * 상태 코드에 따른 로그 레벨 결정
 */
function getLogLevel(statusCode: number): 'info' | 'warn' | 'error' {
  if (statusCode >= 500) {
    return 'error';
  } else if (statusCode >= 400) {
    return 'warn';
  } else {
    return 'info';
  }
}

/**
 * 상태 코드에 따른 이모지 반환
 */
function getStatusEmoji(statusCode: number): string {
  if (statusCode >= 500) {
    return '🔥'; // 서버 에러
  } else if (statusCode >= 400) {
    return '⚠️'; // 클라이언트 에러
  } else if (statusCode >= 300) {
    return '↩️'; // 리다이렉트
  } else {
    return '✅'; // 성공
  }
}