// apps/backend/src/infrastructure/web/middleware/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import { container } from 'tsyringe';
import { ITokenService } from '../../../domain/services/token.service';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';

/**
 * JWT 인증 미들웨어
 * Authorization 헤더에서 Bearer 토큰을 추출하여 검증
 */
export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AppError(
        ErrorCode.UNAUTHORIZED,
        '인증 토큰이 필요합니다'
      );
    }

    const token = authHeader.substring(7);
    const tokenService = container.resolve<ITokenService>('TokenService');
    
    try {
      const payload = await tokenService.verifyAccessToken(token);
      
      // 검증된 사용자 정보를 request에 추가
      (req as any).user = payload;
      
      next();
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError(
        ErrorCode.UNAUTHORIZED,
        '유효하지 않은 토큰입니다'
      );
    }
  } catch (error) {
    next(error);
  }
}

/**
 * 선택적 인증 미들웨어
 * 토큰이 있으면 검증하고, 없어도 통과
 */
export async function optionalAuthMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const tokenService = container.resolve<ITokenService>('TokenService');
      
      try {
        const payload = await tokenService.verifyAccessToken(token);
        (req as any).user = payload;
      } catch (error) {
        // 토큰이 유효하지 않아도 통과
      }
    }
    
    next();
  } catch (error) {
    next(error);
  }
}
