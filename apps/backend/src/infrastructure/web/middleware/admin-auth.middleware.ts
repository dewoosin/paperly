// /Users/workspace/paperly/apps/backend/src/infrastructure/web/middleware/admin-auth.middleware.ts

import { Request, Response, NextFunction } from 'express';
import { ForbiddenError, UnauthorizedError } from '../../../shared/errors';
import { Logger } from '../../logging/Logger';

/**
 * 관리자 인증 미들웨어
 * 
 * JWT 토큰에서 추출된 사용자 역할을 확인하여 관리자 권한을 검증합니다.
 * authMiddleware 이후에 실행되어야 하며, req.user에 사용자 정보가 있어야 합니다.
 */

interface AuthenticatedUser {
  userId: string;
  email: string;
  emailVerified: boolean;
  role?: string;
  permissions?: string[];
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

const logger = new Logger('AdminAuthMiddleware');

/**
 * 관리자 역할 확인 미들웨어
 * 
 * 관리자 권한이 필요한 API 엔드포인트에 사용됩니다.
 * 'admin' 또는 'super_admin' 역할을 가진 사용자만 접근을 허용합니다.
 * 
 * @param req Express Request 객체
 * @param res Express Response 객체
 * @param next NextFunction
 * @throws UnauthorizedError 인증되지 않은 사용자
 * @throws ForbiddenError 관리자 권한이 없는 사용자
 */
export function requireAdminRole(req: Request, res: Response, next: NextFunction): void {
  try {
    // 인증 확인
    if (!req.user) {
      logger.warn('관리자 API 접근 시도 - 인증되지 않은 사용자', {
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        endpoint: req.originalUrl
      });
      throw new UnauthorizedError('인증이 필요합니다');
    }

    // 관리자 역할 확인
    const { role, userId, email } = req.user;
    const adminRoles = ['admin', 'super_admin'];
    
    if (!role || !adminRoles.includes(role)) {
      logger.warn('관리자 API 접근 거부 - 권한 부족', {
        userId,
        email,
        role: role || 'none',
        ip: req.ip,
        endpoint: req.originalUrl
      });
      throw new ForbiddenError('관리자 권한이 필요합니다');
    }

    logger.info('관리자 API 접근 허용', {
      userId,
      email,
      role,
      endpoint: req.originalUrl
    });

    next();
  } catch (error) {
    next(error);
  }
}

/**
 * 최고 관리자 역할 확인 미들웨어
 * 
 * 최고 관리자 권한이 필요한 민감한 작업에 사용됩니다.
 * 'super_admin' 역할을 가진 사용자만 접근을 허용합니다.
 * 
 * @param req Express Request 객체
 * @param res Express Response 객체
 * @param next NextFunction
 * @throws UnauthorizedError 인증되지 않은 사용자
 * @throws ForbiddenError 최고 관리자 권한이 없는 사용자
 */
export function requireSuperAdminRole(req: Request, res: Response, next: NextFunction): void {
  try {
    // 인증 확인
    if (!req.user) {
      logger.warn('최고 관리자 API 접근 시도 - 인증되지 않은 사용자', {
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        endpoint: req.originalUrl
      });
      throw new UnauthorizedError('인증이 필요합니다');
    }

    // 최고 관리자 역할 확인
    const { role, userId, email } = req.user;
    
    if (role !== 'super_admin') {
      logger.warn('최고 관리자 API 접근 거부 - 권한 부족', {
        userId,
        email,
        role: role || 'none',
        ip: req.ip,
        endpoint: req.originalUrl
      });
      throw new ForbiddenError('최고 관리자 권한이 필요합니다');
    }

    logger.info('최고 관리자 API 접근 허용', {
      userId,
      email,
      role,
      endpoint: req.originalUrl
    });

    next();
  } catch (error) {
    next(error);
  }
}

/**
 * 특정 권한 확인 미들웨어 팩토리
 * 
 * 특정 권한을 가진 사용자만 접근할 수 있는 미들웨어를 생성합니다.
 * 세밀한 권한 제어가 필요한 경우 사용됩니다.
 * 
 * @param requiredPermissions 필요한 권한 목록
 * @returns Express 미들웨어 함수
 */
export function requirePermissions(...requiredPermissions: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      // 인증 확인
      if (!req.user) {
        logger.warn('권한 API 접근 시도 - 인증되지 않은 사용자', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          endpoint: req.originalUrl,
          requiredPermissions
        });
        throw new UnauthorizedError('인증이 필요합니다');
      }

      const { permissions, userId, email, role } = req.user;
      
      // 최고 관리자는 모든 권한을 가진 것으로 간주
      if (role === 'super_admin') {
        next();
        return;
      }

      // 필요한 권한이 있는지 확인
      if (!permissions || !requiredPermissions.every(perm => permissions.includes(perm))) {
        logger.warn('권한 API 접근 거부 - 필요한 권한 부족', {
          userId,
          email,
          role: role || 'none',
          userPermissions: permissions || [],
          requiredPermissions,
          ip: req.ip,
          endpoint: req.originalUrl
        });
        throw new ForbiddenError(`다음 권한이 필요합니다: ${requiredPermissions.join(', ')}`);
      }

      logger.info('권한 API 접근 허용', {
        userId,
        email,
        role,
        endpoint: req.originalUrl,
        checkedPermissions: requiredPermissions
      });

      next();
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 역할 또는 권한 확인 미들웨어 팩토리
 * 
 * 특정 역할이거나 특정 권한을 가진 사용자의 접근을 허용합니다.
 * 유연한 접근 제어가 필요한 경우 사용됩니다.
 * 
 * @param options 역할 및 권한 옵션
 * @returns Express 미들웨어 함수
 */
export function requireRoleOrPermissions(options: {
  roles?: string[];
  permissions?: string[];
  requireAll?: boolean; // true: 모든 권한 필요, false: 하나라도 있으면 됨
}) {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      // 인증 확인
      if (!req.user) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      const { role, permissions, userId, email } = req.user;
      
      // 역할 확인
      if (options.roles && role && options.roles.includes(role)) {
        next();
        return;
      }

      // 권한 확인
      if (options.permissions && permissions) {
        const hasPermission = options.requireAll
          ? options.permissions.every(perm => permissions.includes(perm))
          : options.permissions.some(perm => permissions.includes(perm));
        
        if (hasPermission) {
          next();
          return;
        }
      }

      logger.warn('역할/권한 API 접근 거부', {
        userId,
        email,
        userRole: role || 'none',
        userPermissions: permissions || [],
        requiredRoles: options.roles || [],
        requiredPermissions: options.permissions || [],
        requireAll: options.requireAll || false,
        ip: req.ip,
        endpoint: req.originalUrl
      });

      throw new ForbiddenError('접근 권한이 없습니다');
    } catch (error) {
      next(error);
    }
  };
}

/**
 * 간단한 관리자 인증 미들웨어 (alias)
 * AdminArticleController에서 사용하기 위한 별칭
 */
export const adminAuthMiddleware = requireAdminRole;