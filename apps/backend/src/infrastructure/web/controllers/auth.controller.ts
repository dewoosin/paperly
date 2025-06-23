// apps/backend/src/infrastructure/web/controllers/auth.controller.ts

import { Router, Request, Response, NextFunction } from 'express';
import { inject, injectable } from 'tsyringe';
import { RegisterUseCase } from '../../../application/use-cases/auth/register.use-case';
import { LoginUseCase } from '../../../application/use-cases/auth/login.use-case';
import { VerifyEmailUseCase } from '../../../application/use-cases/auth/verify-email.use-case';
import { RefreshTokenUseCase } from '../../../application/use-cases/auth/refresh-token.use-case';
import { AppError, ErrorCode } from '../../../shared/errors/app-error';
import { logger } from '../../logging/logger';

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

  constructor(
    @inject(RegisterUseCase) private registerUseCase: RegisterUseCase,
    @inject(LoginUseCase) private loginUseCase: LoginUseCase,
    @inject(VerifyEmailUseCase) private verifyEmailUseCase: VerifyEmailUseCase,
    @inject(RefreshTokenUseCase) private refreshTokenUseCase: RefreshTokenUseCase
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
   *   birthDate: string (ISO 8601)
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
          emailVerificationSent: result.emailVerificationSent,
          message: result.emailVerificationSent 
            ? '회원가입이 완료되었습니다. 이메일을 확인해주세요.'
            : '회원가입이 완료되었습니다.'
        }
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
   * @headers {
   *   x-device-id: string
   *   user-agent: string
   * }
   */
  private async login(req: Request, res: Response, next: NextFunction) {
    try {
      // 디바이스 정보 추출
      const deviceId = req.headers['x-device-id'] as string || this.generateDeviceId();
      const userAgent = req.headers['user-agent'] || 'Unknown';
      const ipAddress = this.getClientIp(req);

      const result = await this.loginUseCase.execute({
        ...req.body,
        deviceId,
        userAgent,
        ipAddress
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
   * 토큰 갱신
   * 
   * @body {
   *   refreshToken: string
   * }
   */
  private async refreshToken(req: Request, res: Response, next: NextFunction) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        throw new AppError(
          ErrorCode.BAD_REQUEST,
          'Refresh Token이 필요합니다'
        );
      }

      const result = await this.refreshTokenUseCase.execute({ refreshToken });

      res.json({
        success: true,
        data: {
          tokens: result
        }
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 로그아웃
   * 
   * @headers {
   *   authorization: Bearer {accessToken}
   * }
   * @body {
   *   refreshToken?: string (특정 기기만 로그아웃)
   *   allDevices?: boolean (모든 기기에서 로그아웃)
   * }
   */
  private async logout(req: Request, res: Response, next: NextFunction) {
    try {
      // auth 미들웨어에서 주입된 사용자 정보
      const userId = (req as any).user?.sub;
      
      if (!userId) {
        throw new AppError(
          ErrorCode.UNAUTHORIZED,
          '인증이 필요합니다'
        );
      }

      const { refreshToken, allDevices } = req.body;

      // TODO: TokenService에 로그아웃 메서드 추가 필요
      // if (allDevices) {
      //   await this.tokenService.revokeAllRefreshTokens(userId);
      // } else if (refreshToken) {
      //   await this.tokenService.revokeRefreshToken(refreshToken);
      // }

      res.json({
        success: true,
        message: '로그아웃되었습니다'
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
      const { token } = req.query;

      if (!token || typeof token !== 'string') {
        throw new AppError(
          ErrorCode.BAD_REQUEST,
          '인증 토큰이 필요합니다'
        );
      }

      const result = await this.verifyEmailUseCase.execute({ token });

      res.json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 인증 메일 재발송
   * 
   * @headers {
   *   authorization: Bearer {accessToken}
   * }
   */
  private async resendVerification(req: Request, res: Response, next: NextFunction) {
    try {
      // auth 미들웨어에서 주입된 사용자 정보
      const user = (req as any).user;
      
      if (!user) {
        throw new AppError(
          ErrorCode.UNAUTHORIZED,
          '인증이 필요합니다'
        );
      }

      if (user.emailVerified) {
        throw new AppError(
          ErrorCode.BAD_REQUEST,
          '이미 이메일 인증이 완료되었습니다'
        );
      }

      // TODO: ResendVerificationUseCase 구현 필요
      // const result = await this.resendVerificationUseCase.execute({
      //   userId: user.sub
      // });

      res.json({
        success: true,
        message: '인증 메일이 재발송되었습니다'
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * 클라이언트 IP 추출
   */
  private getClientIp(req: Request): string {
    const forwarded = req.headers['x-forwarded-for'] as string;
    const ip = forwarded 
      ? forwarded.split(',')[0].trim()
      : req.socket.remoteAddress || '';
    
    // IPv6 localhost를 IPv4로 변환
    return ip === '::1' ? '127.0.0.1' : ip;
  }

  /**
   * 디바이스 ID 생성 (클라이언트가 제공하지 않은 경우)
   */
  private generateDeviceId(): string {
    return `web-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
