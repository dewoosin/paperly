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
