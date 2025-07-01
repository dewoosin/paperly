// apps/backend/src/infrastructure/web/middlewares/auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env.config';
import { Logger } from '../../logging/Logger';

const logger = new Logger('AuthMiddleware');

interface AuthenticatedUser {
  userId: string;
  email: string;
  emailVerified: boolean;
  roles?: string[];
}

interface AuthRequest extends Request {
  user?: AuthenticatedUser;
}

export const authMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return res.status(401).json({
        error: {
          code: 'UNAUTHORIZED',
          message: 'Authorization header is required',
          timestamp: new Date().toISOString(),
        }
      });
    }

    const token = authHeader.split(' ')[1]; // Bearer <token>
    
    if (!token) {
      return res.status(401).json({
        error: {
          code: 'UNAUTHORIZED',
          message: 'Token is required',
          timestamp: new Date().toISOString(),
        }
      });
    }

    try {
      const decoded = jwt.verify(token, config.JWT_SECRET) as any;
      req.user = {
        id: decoded.sub || decoded.id,
        email: decoded.email,
        roles: decoded.roles || []
      };
      next();
    } catch (jwtError) {
      logger.warn('Invalid JWT token:', jwtError);
      return res.status(401).json({
        error: {
          code: 'UNAUTHORIZED',
          message: 'Invalid or expired token',
          timestamp: new Date().toISOString(),
        }
      });
    }
  } catch (error) {
    logger.error('Auth middleware error:', error);
    return res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Authentication failed',
        timestamp: new Date().toISOString(),
      }
    });
  }
};