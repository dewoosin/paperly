// /Users/workspace/paperly/apps/backend/src/infrastructure/web/controllers/admin-auth.controller.ts

import { Request, Response } from 'express';
import { injectable, inject } from 'tsyringe';
import { AdminAuthService } from '../../../application/services/admin-auth.service';
import { ValidationError, UnauthorizedError, ForbiddenError } from '../../../shared/errors';
import { Logger } from '../../logging/Logger';
import { JwtService } from '../../auth/jwt.service';

/**
 * 관리자 인증 컨트롤러
 * 
 * 관리자 인증과 관련된 HTTP 요청을 처리합니다.
 * 일반 사용자 인증과 분리된 관리자 전용 엔드포인트를 제공합니다.
 */

@injectable()
export class AdminAuthController {
  private readonly logger = new Logger('AdminAuthController');

  constructor(
    @inject('AdminAuthService') private readonly adminAuthService: AdminAuthService
  ) {}

  /**
   * 관리자 로그인 엔드포인트
   * 
   * POST /admin/auth/login
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      // 입력값 검증
      if (!email || !password) {
        throw new ValidationError('이메일과 비밀번호는 필수입니다');
      }

      // 추가 보안 정보 수집
      const deviceId = req.headers['x-device-id'] as string;
      const userAgent = req.headers['user-agent'];
      const ip = req.ip;

      // 관리자 로그인 처리
      const loginResult = await this.adminAuthService.login({
        email,
        password,
        deviceId,
        userAgent,
        ip
      });

      // 성공 응답
      res.status(200).json({
        success: true,
        data: {
          user: loginResult.user,
          accessToken: loginResult.tokens.accessToken
        },
        message: '관리자 로그인이 성공했습니다'
      });

      // Refresh 토큰은 HttpOnly 쿠키로 설정
      res.cookie('admin_refresh_token', loginResult.tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000 // 7일
      });

      this.logger.info('관리자 로그인 응답 완료', {
        userId: loginResult.user.id,
        role: loginResult.user.role
      });
    } catch (error) {
      this.logger.error('관리자 로그인 오류', { error });
      
      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else if (error instanceof ForbiddenError) {
        res.status(403).json({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 관리자 토큰 새로고침 엔드포인트
   * 
   * POST /admin/auth/refresh
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const refreshToken = req.cookies.admin_refresh_token;

      if (!refreshToken) {
        throw new UnauthorizedError('Refresh 토큰이 없습니다');
      }

      // 토큰 새로고침 처리
      const tokens = await this.adminAuthService.refreshToken(refreshToken);

      // 성공 응답
      res.status(200).json({
        success: true,
        data: {
          accessToken: tokens.accessToken
        },
        message: '토큰이 새로고침되었습니다'
      });

      // 새로운 Refresh 토큰 쿠키 설정
      res.cookie('admin_refresh_token', tokens.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 7 * 24 * 60 * 60 * 1000 // 7일
      });

      this.logger.info('관리자 토큰 새로고침 완료');
    } catch (error) {
      this.logger.error('관리자 토큰 새로고침 오류', { error });

      if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 관리자 로그아웃 엔드포인트
   * 
   * POST /admin/auth/logout
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async logout(req: Request, res: Response): Promise<void> {
    try {
      // Refresh 토큰 쿠키 제거
      res.clearCookie('admin_refresh_token');

      res.status(200).json({
        success: true,
        message: '로그아웃되었습니다'
      });

      this.logger.info('관리자 로그아웃 완료', {
        userId: req.user?.userId
      });
    } catch (error) {
      this.logger.error('관리자 로그아웃 오류', { error });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다'
        }
      });
    }
  }

  /**
   * 현재 관리자 정보 조회 엔드포인트
   * 
   * GET /admin/auth/me
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getCurrentUser(req: Request, res: Response): Promise<void> {
    try {
      if (!req.user?.userId) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      const adminUser = await this.adminAuthService.getAdminUser(req.user.userId);
      
      if (!adminUser) {
        throw new UnauthorizedError('관리자 정보를 찾을 수 없습니다');
      }

      res.status(200).json({
        success: true,
        data: adminUser,
        message: '관리자 정보 조회가 완료되었습니다'
      });
    } catch (error) {
      this.logger.error('관리자 정보 조회 오류', { error });

      if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 관리자 권한 확인 엔드포인트
   * 
   * GET /admin/auth/verify
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async verifyAdmin(req: Request, res: Response): Promise<void> {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new UnauthorizedError('Access 토큰이 필요합니다');
      }

      const token = authHeader.substring(7);
      const decoded = JwtService.verifyAccessToken(token);
      
      // 관리자 역할 확인
      const adminRoles = ['admin', 'super_admin', 'editor', 'reviewer'];
      if (!decoded.role || !adminRoles.includes(decoded.role)) {
        throw new ForbiddenError('관리자 권한이 없습니다');
      }

      res.status(200).json({
        success: true,
        data: {
          userId: decoded.userId,
          email: decoded.email,
          role: decoded.role,
          permissions: decoded.permissions || []
        },
        message: '관리자 권한이 확인되었습니다'
      });
    } catch (error) {
      this.logger.error('관리자 권한 확인 오류', { error });

      if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else if (error instanceof ForbiddenError) {
        res.status(403).json({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 모든 관리자 사용자 목록 조회 엔드포인트
   * 
   * GET /admin/users/admins
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async getAdminUsers(req: Request, res: Response): Promise<void> {
    try {
      const adminUsers = await this.adminAuthService.getAllAdminUsers();

      res.status(200).json({
        success: true,
        data: adminUsers,
        message: '관리자 사용자 목록 조회가 완료되었습니다'
      });
    } catch (error) {
      this.logger.error('관리자 사용자 목록 조회 오류', { error });
      
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_SERVER_ERROR',
          message: '서버 오류가 발생했습니다'
        }
      });
    }
  }

  /**
   * 사용자에게 관리자 역할 할당 엔드포인트
   * 
   * POST /admin/users/:userId/assign-role
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async assignRole(req: Request, res: Response): Promise<void> {
    try {
      const { userId } = req.params;
      const { roleId, expiresAt } = req.body;
      const assignedBy = req.user?.userId;

      if (!userId || !roleId) {
        throw new ValidationError('사용자 ID와 역할 ID는 필수입니다');
      }

      if (!assignedBy) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      const expiresAtDate = expiresAt ? new Date(expiresAt) : undefined;

      await this.adminAuthService.assignAdminRole(
        userId, 
        roleId, 
        assignedBy, 
        expiresAtDate
      );

      res.status(200).json({
        success: true,
        message: '역할이 성공적으로 할당되었습니다'
      });
    } catch (error) {
      this.logger.error('역할 할당 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }

  /**
   * 사용자의 관리자 역할 제거 엔드포인트
   * 
   * DELETE /admin/users/:userId/remove-role
   * 
   * @param req Express Request
   * @param res Express Response
   */
  async removeRole(req: Request, res: Response): Promise<void> {
    try {
      const { userId } = req.params;
      const removedBy = req.user?.userId;

      if (!userId) {
        throw new ValidationError('사용자 ID는 필수입니다');
      }

      if (!removedBy) {
        throw new UnauthorizedError('인증이 필요합니다');
      }

      await this.adminAuthService.removeAdminRole(userId, removedBy);

      res.status(200).json({
        success: true,
        message: '역할이 성공적으로 제거되었습니다'
      });
    } catch (error) {
      this.logger.error('역할 제거 오류', { error });

      if (error instanceof ValidationError) {
        res.status(400).json({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: error.message
          }
        });
      } else if (error instanceof UnauthorizedError) {
        res.status(401).json({
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: error.message
          }
        });
      } else {
        res.status(500).json({
          success: false,
          error: {
            code: 'INTERNAL_SERVER_ERROR',
            message: '서버 오류가 발생했습니다'
          }
        });
      }
    }
  }
}