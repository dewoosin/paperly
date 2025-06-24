// /Users/workspace/paperly/apps/backend/src/infrastructure/web/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import { JwtService } from '../../auth/jwt.service';
import { UnauthorizedError, ForbiddenError } from '../../../shared/errors';
import { Logger } from '../../logging/Logger';

/**
 * Express Request 확장
 */
declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        email: string;
        emailVerified?: boolean;
      };
    }
  }
}

const logger = new Logger('AuthMiddleware');

/**
 * JWT 인증 미들웨어
 * 
 * Authorization 헤더에서 Bearer 토큰을 추출하여 검증합니다.
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    // 1. Authorization 헤더 확인
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      throw new UnauthorizedError('인증 토큰이 필요합니다');
    }

    // 2. Bearer 토큰 추출
    const parts = authHeader.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      throw new UnauthorizedError('잘못된 인증 토큰 형식입니다');
    }

    const token = parts[1];

    // 3. 토큰 검증
    try {
      const decoded = JwtService.verifyAccessToken(token);
      
      // 4. 요청 객체에 사용자 정보 추가
      req.user = {
        userId: decoded.userId,
        email: decoded.email,
        emailVerified: true // JWT가 발급되었다면 이메일 인증됨
      };

      logger.debug('인증 성공', { userId: decoded.userId });
      
      next();
    } catch (error) {
      logger.warn('토큰 검증 실패', error);
      throw new UnauthorizedError('유효하지 않은 토큰입니다');
    }
  } catch (error) {
    next(error);
  }
}

/**
 * 선택적 인증 미들웨어
 * 
 * 토큰이 있으면 검증하고, 없어도 통과합니다.
 */
export async function optionalAuthMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      try {
        const decoded = JwtService.verifyAccessToken(token);
        req.user = {
          userId: decoded.userId,
          email: decoded.email,
          emailVerified: true
        };
        
        logger.debug('선택적 인증 성공', { userId: decoded.userId });
      } catch (error) {
        // 토큰이 유효하지 않아도 통과
        logger.debug('선택적 인증 - 토큰 무효', error);
      }
    }
    
    next();
  } catch (error) {
    next(error);
  }
}

/**
 * 이메일 인증 확인 미들웨어
 * 
 * authMiddleware 이후에 사용하여 이메일 인증 여부를 확인합니다.
 */
export async function verifiedEmailMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!req.user) {
      throw new UnauthorizedError('인증이 필요합니다');
    }

    if (!req.user.emailVerified) {
      throw new ForbiddenError('이메일 인증이 필요합니다');
    }

    next();
  } catch (error) {
    next(error);
  }
}

/**
 * 권한 확인 미들웨어 팩토리
 * 
 * 특정 권한이 필요한 라우트를 보호합니다.
 * 
 * @param roles - 필요한 권한 목록
 * @returns Express 미들웨어
 */
export function requireRoles(...roles: string[]) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      // TODO: 사용자 권한 확인 로직 구현
      // 현재는 관리자 권한만 간단히 체크
      const userRoles = ['user']; // 기본 사용자 권한
      
      const hasRequiredRole = roles.some(role => userRoles.includes(role));
      
      if (!hasRequiredRole) {
        throw new ForbiddenError('접근 권한이 없습니다');
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}

/**
 * API 키 인증 미들웨어
 * 
 * 외부 서비스 연동용 API 키 인증
 */
export async function apiKeyMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const apiKey = req.headers['x-api-key'] as string;
    
    if (!apiKey) {
      throw new UnauthorizedError('API 키가 필요합니다');
    }

    // TODO: API 키 검증 로직 구현
    const validApiKey = process.env.API_KEY || 'test-api-key';
    
    if (apiKey !== validApiKey) {
      throw new UnauthorizedError('유효하지 않은 API 키입니다');
    }

    next();
  } catch (error) {
    next(error);
  }
}

/**
 * 사용자 본인 확인 미들웨어
 * 
 * 요청한 사용자가 리소스의 소유자인지 확인합니다.
 */
export async function requireOwnership(userIdParam: string = 'userId') {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      const resourceUserId = req.params[userIdParam] || req.body[userIdParam];
      
      if (!resourceUserId) {
        throw new BadRequestError('사용자 ID가 필요합니다');
      }

      if (req.user.userId !== resourceUserId) {
        throw new ForbiddenError('본인의 리소스만 접근할 수 있습니다');
      }

      next();
    } catch (error) {
      next(error);
    }
  };
}

// Error import
import { BadRequestError } from '../../../shared/errors';