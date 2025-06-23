/**
 * rateLimit.middleware.ts
 * API Rate Limiting 미들웨어
 */

import rateLimit from 'express-rate-limit';
import { config } from '../../../config/env.config';

export const rateLimiter = rateLimit({
  windowMs: config.RATE_LIMIT_WINDOW_MS,
  max: config.RATE_LIMIT_MAX_REQUESTS,
  message: 'Too many requests from this IP, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // 헬스체크는 제외
    return req.path === '/health';
  },
});

// 로그인 시도용 더 엄격한 제한
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 5, // 5회 시도
  message: 'Too many login attempts, please try again later',
  skipSuccessfulRequests: true,
});
