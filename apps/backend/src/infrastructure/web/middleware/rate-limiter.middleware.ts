// /Users/workspace/paperly/apps/backend/src/infrastructure/web/middleware/rate-limiter.middleware.ts

import rateLimit, { RateLimitRequestHandler } from 'express-rate-limit';
import { TooManyRequestsError } from '../../../shared/errors';
import { Request } from 'express';

/**
 * Rate Limiting 설정 인터페이스
 */
interface RateLimiterConfig {
  windowMs?: number;      // 시간 윈도우 (밀리초)
  max?: number;           // 최대 요청 수
  message?: string;       // 에러 메시지
  keyGenerator?: (req: Request) => string;  // 키 생성 함수
  skipSuccessfulRequests?: boolean;         // 성공 요청 제외 여부
  skipFailedRequests?: boolean;             // 실패 요청 제외 여부
}

/**
 * Rate Limiter 생성 함수
 * 
 * @param config - Rate limiting 설정
 * @returns Express rate limiter 미들웨어
 */
export function rateLimiter(config: RateLimiterConfig = {}): RateLimitRequestHandler {
  const {
    windowMs = 15 * 60 * 1000,  // 기본값: 15분
    max = 100,                   // 기본값: 100회
    message = '너무 많은 요청이 있었습니다. 잠시 후 다시 시도해주세요.',
    keyGenerator,
    skipSuccessfulRequests = false,
    skipFailedRequests = false
  } = config;

  return rateLimit({
    windowMs,
    max,
    message,
    standardHeaders: true,      // `RateLimit-*` 헤더 추가
    legacyHeaders: false,       // `X-RateLimit-*` 헤더 비활성화
    keyGenerator: keyGenerator || ((req) => {
      // 기본 키 생성: IP + User ID 조합
      const userId = (req as any).user?.userId;
      const ip = req.ip || req.connection.remoteAddress || 'unknown';
      return userId ? `${ip}:${userId}` : ip;
    }),
    handler: (req, res) => {
      throw new TooManyRequestsError(message);
    },
    skipSuccessfulRequests,
    skipFailedRequests,
    skip: (req) => {
      // 특정 경로는 rate limiting 제외
      const excludedPaths = ['/health', '/metrics'];
      return excludedPaths.includes(req.path);
    }
  });
}

/**
 * 사전 정의된 Rate Limiters
 */

// 기본 Rate Limiter
export const defaultRateLimiter = rateLimiter();

// 엄격한 Rate Limiter (로그인, 회원가입 등)
export const strictRateLimiter = rateLimiter({
  windowMs: 15 * 60 * 1000,  // 15분
  max: 5,                     // 5회
  message: '너무 많은 시도가 있었습니다. 15분 후에 다시 시도해주세요.'
});

// API Rate Limiter
export const apiRateLimiter = rateLimiter({
  windowMs: 1 * 60 * 1000,    // 1분
  max: 60,                    // 60회
  message: 'API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.'
});

// 이메일 발송 Rate Limiter
export const emailRateLimiter = rateLimiter({
  windowMs: 60 * 60 * 1000,  // 1시간
  max: 3,                     // 3회
  message: '이메일 발송 한도를 초과했습니다. 1시간 후에 다시 시도해주세요.'
});

// 파일 업로드 Rate Limiter
export const uploadRateLimiter = rateLimiter({
  windowMs: 60 * 60 * 1000,  // 1시간
  max: 10,                    // 10회
  message: '파일 업로드 한도를 초과했습니다. 1시간 후에 다시 시도해주세요.'
});

// IP 기반 Rate Limiter (로그인하지 않은 사용자용)
export const ipRateLimiter = rateLimiter({
  windowMs: 15 * 60 * 1000,  // 15분
  max: 30,                    // 30회
  keyGenerator: (req) => req.ip || req.connection.remoteAddress || 'unknown',
  message: 'IP당 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.'
});

// 동적 Rate Limiter 생성 함수
export function createDynamicRateLimiter(
  endpoint: string,
  maxRequests: number = 100,
  windowMinutes: number = 15
): RateLimitRequestHandler {
  return rateLimiter({
    windowMs: windowMinutes * 60 * 1000,
    max: maxRequests,
    message: `${endpoint} 엔드포인트의 요청 한도를 초과했습니다. ${windowMinutes}분 후에 다시 시도해주세요.`
  });
}