// /Users/workspace/paperly/apps/backend/src/infrastructure/web/controllers/auth.controller.ts

import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { RegisterUseCase } from '../../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../../application/use-cases/auth/login.use-case';
import { VerifyEmailUseCase, ResendVerificationUseCase } from '../../../application/use-cases/auth/verify-email.use-case';
import { RefreshTokenUseCase, LogoutUseCase } from '../../../application/use-cases/auth/refresh-token.use-case';
import { Logger } from '../../logging/Logger';

/**
 * 인증 관련 API 컨트롤러
 * 
 * POST /api/v1/auth/register - 회원가입
 * POST /api/v1/auth/login - 로그인
 * POST /api/v1/auth/refresh - 토큰 갱신
 * POST /api/v1/auth/logout - 로그아웃
 * GET  /api/v1/auth/verify-email - 이메일 인증
 * POST /api/v1/auth/resend-verification - 인증 메일 재발송
 */
@injectable()
export class AuthController {
  public readonly router: Router;
  private readonly logger = new Logger('AuthController');

  constructor(
    @inject(RegisterUseCase) private registerUseCase: RegisterUseCase,
    @inject(LoginUseCase) private loginUseCase: LoginUseCase,
    @inject(VerifyEmailUseCase) private verifyEmailUseCase: VerifyEmailUseCase,
    @inject(ResendVerificationUseCase) private resendVerificationUseCase: ResendVerificationUseCase,
    @inject(RefreshTokenUseCase) private refreshTokenUseCase: RefreshTokenUseCase,
    @inject(LogoutUseCase) private logoutUseCase: LogoutUseCase
  ) {
    this.router = Router();
    this.setupRoutes();
  }

  private setupRoutes() {
    // 회원가입
    this.router.post('/register', this.register.bind(this));
    
    // 로그인
    this.router.post('/login', this.login.bind(this));
    
    // 토큰 갱신
    this.router.post('/refresh', this.refreshToken.bind(this));
    
    // 로그아웃
    this.router.post('/logout', this.logout.bind(this));
    
    // 이메일 인증
    this.router.get('/verify-email', this.verifyEmail.bind(this));
    
    // 인증 메일 재발송
    this.router.post('/resend-verification', this.resendVerification.bind(this));
  }

  /**
   * 회원가입
   * 
   * @body {
   *   email: string
   *   password: string
   *   name: string
   *   birthDate: string (YYYY-MM-DD)
   *   gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say'
   * }
   */
  private async register(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.registerUseCase.execute(req.body);

      res.status(201).json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens,
          emailVerificationSent: result.emailVerificationSent
        },
        message: result.emailVerificationSent 
          ? '회원가입이 완료되었습니다. 이메일을 확인해주세요.'
          : '회원가입이 완료되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 로그인
   * 
   * @body {
   *   email: string
   *   password: string
   * }
   */
  private async login(req: Request, res: Response, next: NextFunction) {
    try {
      // 디바이스 정보 추출
      const deviceId = req.headers['x-device-id'] as string || 'unknown';
      
      if (deviceId === 'unknown') {
        this.logger.warn('로그인 시 디바이스 ID가 제공되지 않음', { 
          userAgent: req.headers['user-agent'],
          ip: req.ip,
          email: req.body.email
        });
      }
      
      const deviceInfo = {
        deviceId,
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip || req.connection.remoteAddress
      };

      const result = await this.loginUseCase.execute({
        ...req.body,
        deviceInfo
      });

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        },
        message: '로그인되었습니다.'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 토큰 갱신
   * 
   * @body {
   *   refreshToken: string
   * }
   */
  private async refreshToken(req: Request, res: Response, next: NextFunction) {
    try {
      // 디바이스 정보 추출
      const deviceId = req.headers['x-device-id'] as string || 'unknown';
      
      if (deviceId === 'unknown') {
        this.logger.warn('토큰 갱신 시 디바이스 ID가 제공되지 않음', { 
          userAgent: req.headers['user-agent'],
          ip: req.ip 
        });
      }
      
      const deviceInfo = {
        deviceId,
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip || req.connection.remoteAddress
      };

      const result = await this.refreshTokenUseCase.execute({
        refreshToken: req.body.refreshToken,
        deviceInfo
      });

      res.json({
        success: true,
        data: {
          user: result.user,
          tokens: result.tokens
        }
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 로그아웃
   * 
   * @body {
   *   refreshToken?: string
   *   allDevices?: boolean
   * }
   */
  private async logout(req: Request, res: Response, next: NextFunction) {
    try {
      // 인증된 사용자의 경우 req.user에서 userId 가져오기
      const userId = (req as any).user?.userId;

      const result = await this.logoutUseCase.execute({
        refreshToken: req.body.refreshToken,
        allDevices: req.body.allDevices,
        userId
      });

      res.json({
        success: result.success,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 이메일 인증
   * 
   * @query {
   *   token: string
   * }
   */
  private async verifyEmail(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await this.verifyEmailUseCase.execute({
        token: req.query.token as string
      });

      res.json({
        success: result.success,
        data: result.user,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 인증 메일 재발송
   * 
   * @body {
   *   userId: string
   * }
   */
  private async resendVerification(req: Request, res: Response, next: NextFunction) {
    try {
      // 인증된 사용자의 경우 req.user에서 userId 가져오기
      const userId = (req as any).user?.userId || req.body.userId;

      const result = await this.resendVerificationUseCase.execute({
        userId
      });

      res.json({
        success: result.success,
        message: result.message
      });
    } catch (error) {
      next(error);
    }
  }
}