#!/bin/bash

echo "Creating Express middlewares..."

# Error middleware
cat > src/infrastructure/web/express/middlewares/error.middleware.ts << 'EOF'
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
EOF

# Not Found middleware
cat > src/infrastructure/web/express/middlewares/notFound.middleware.ts << 'EOF'
/**
 * notFound.middleware.ts
 * 404 처리 미들웨어
 */

import { Request, Response } from 'express';

export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
      timestamp: new Date(),
      requestId: req.id,
    },
  });
}
EOF

# Rate Limit middleware
cat > src/infrastructure/web/express/middlewares/rateLimit.middleware.ts << 'EOF'
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
EOF

# Request ID middleware
cat > src/infrastructure/web/express/middlewares/requestId.middleware.ts << 'EOF'
/**
 * requestId.middleware.ts
 * 요청 추적을 위한 ID 생성 미들웨어
 */

import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';

declare global {
  namespace Express {
    interface Request {
      id: string;
    }
  }
}

export function requestId(req: Request, res: Response, next: NextFunction): void {
  req.id = req.headers['x-request-id'] as string || randomUUID();
  res.setHeader('X-Request-ID', req.id);
  next();
}
EOF

# Auth middleware (placeholder)
cat > src/infrastructure/web/express/middlewares/auth.middleware.ts << 'EOF'
/**
 * auth.middleware.ts
 * JWT 인증 미들웨어
 */

import { Request, Response, NextFunction } from 'express';
import { AuthenticationError } from '../../../../shared/errors/BaseError';

// TODO: Day 3에서 구현
export async function authenticate(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new AuthenticationError('No token provided');
    }

    // TODO: JWT 검증 로직
    
    next();
  } catch (error) {
    next(error);
  }
}

export async function authorize(...roles: string[]) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      // TODO: 권한 검증 로직
      next();
    } catch (error) {
      next(error);
    }
  };
}
EOF

echo "✅ Middlewares created successfully!"
