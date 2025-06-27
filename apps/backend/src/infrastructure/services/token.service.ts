// apps/backend/src/infrastructure/services/token.service.ts

import { injectable, inject } from 'tsyringe';
import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';
import { ITokenService } from '../../domain/services/token.service';
import { IRefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { IEmailVerificationRepository } from '../../domain/repositories/email-verification.repository';
import { User } from '../../domain/entities/User.entity';
import { Token, DeviceInfo } from '../../domain/value-objects/auth.value-objects';
import { UserId } from '../../domain/value-objects/user-id.value-object';
import { AppError, ErrorCode } from '../../shared/errors/app-error';
import { Config } from '../config/config';
import { Logger } from '../logging/Logger';

/**
 * JWT 페이로드 타입
 */
interface JwtPayload {
  sub: string; // user id
  email: string;
  name: string;
  emailVerified: boolean;
  iat?: number;
  exp?: number;
}

/**
 * 토큰 서비스 구현
 * - JWT 기반 Access Token
 * - 암호화된 Refresh Token
 * - 이메일 인증 토큰
 */
@injectable()
export class TokenService implements ITokenService {
  private readonly logger = new Logger('TokenService');
  private readonly accessTokenSecret: string;
  private readonly accessTokenExpiresIn: string = '1h'; // 1시간
  private readonly refreshTokenExpiresIn: number = 7 * 24 * 60 * 60 * 1000; // 7일 (밀리초)
  private readonly emailVerificationExpiresIn: number = 24 * 60 * 60 * 1000; // 24시간 (밀리초)

  constructor(
    @inject('Config') private config: Config,
    @inject('RefreshTokenRepository') private refreshTokenRepository: IRefreshTokenRepository,
    @inject('EmailVerificationRepository') private emailVerificationRepository: IEmailVerificationRepository
  ) {
    this.accessTokenSecret = this.config.get('JWT_SECRET');
  }

  /**
   * Access Token과 Refresh Token 생성
   */
  async generateAuthTokens(user: User, deviceInfo?: DeviceInfo): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. Access Token 생성
      const accessToken = this.generateAccessToken(user);

      // 2. Refresh Token 생성
      const refreshTokenValue = this.generateSecureToken();
      const refreshToken = Token.create(refreshTokenValue);

      // 3. Refresh Token DB 저장
      const expiresAt = new Date(Date.now() + this.refreshTokenExpiresIn);
      
      await this.refreshTokenRepository.create({
        userId: user.id,
        token: refreshToken,
        deviceId: deviceInfo?.id,
        deviceName: deviceInfo?.name,
        expiresAt
      });

      this.logger.info('인증 토큰 생성 완료', { userId: user.id.value });

      return {
        accessToken,
        refreshToken: refreshTokenValue
      };
    } catch (error) {
      this.logger.error('토큰 생성 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, '토큰 생성에 실패했습니다');
    }
  }

  /**
   * Access Token 생성
   */
  private generateAccessToken(user: User): string {
    const payload: JwtPayload = {
      sub: user.id.value,
      email: user.email.value,
      name: user.name,
      emailVerified: user.emailVerified
    };

    return jwt.sign(payload, this.accessTokenSecret, {
      expiresIn: this.accessTokenExpiresIn,
      issuer: 'paperly',
      audience: 'paperly-app'
    });
  }

  /**
   * Access Token 검증
   */
  async verifyAccessToken(token: string): Promise<JwtPayload> {
    try {
      const payload = jwt.verify(token, this.accessTokenSecret, {
        issuer: 'paperly',
        audience: 'paperly-app'
      }) as JwtPayload;

      return payload;
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new AppError(ErrorCode.UNAUTHORIZED, 'Access Token이 만료되었습니다');
      }
      if (error instanceof jwt.JsonWebTokenError) {
        throw new AppError(ErrorCode.UNAUTHORIZED, '유효하지 않은 토큰입니다');
      }
      throw error;
    }
  }

  /**
   * Refresh Token으로 새로운 토큰 발급
   */
  async refreshTokens(refreshToken: Token): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. DB에서 Refresh Token 조회
      const storedToken = await this.refreshTokenRepository.findByToken(refreshToken);
      
      if (!storedToken) {
        throw new AppError(ErrorCode.UNAUTHORIZED, '유효하지 않은 Refresh Token입니다');
      }

      // 2. 만료 확인
      if (storedToken.isExpired()) {
        await this.refreshTokenRepository.delete(storedToken.id);
        throw new AppError(ErrorCode.UNAUTHORIZED, 'Refresh Token이 만료되었습니다');
      }

      // 3. 사용자 조회
      const user = await this.refreshTokenRepository.findUserByToken(refreshToken);
      if (!user) {
        throw new AppError(ErrorCode.UNAUTHORIZED, '사용자를 찾을 수 없습니다');
      }

      // 4. 기존 Refresh Token 삭제
      await this.refreshTokenRepository.delete(storedToken.id);

      // 5. 새로운 토큰 발급
      const newTokens = await this.generateAuthTokens(user, 
        storedToken.deviceId && storedToken.deviceName 
          ? DeviceInfo.create(storedToken.deviceId, storedToken.deviceName) 
          : undefined
      );

      // 6. 마지막 사용 시간 업데이트
      storedToken.updateLastUsed();
      await this.refreshTokenRepository.save(storedToken);

      this.logger.info('토큰 갱신 완료', { userId: user.id.value });

      return newTokens;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      this.logger.error('토큰 갱신 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, '토큰 갱신에 실패했습니다');
    }
  }

  /**
   * 이메일 인증 토큰 생성
   */
  async generateEmailVerificationToken(userId: UserId): Promise<string> {
    try {
      const tokenValue = this.generateSecureToken();
      const token = Token.create(tokenValue);
      const expiresAt = new Date(Date.now() + this.emailVerificationExpiresIn);

      await this.emailVerificationRepository.create({
        userId,
        token,
        expiresAt
      });

      this.logger.info('이메일 인증 토큰 생성', { userId: userId.value });

      return tokenValue;
    } catch (error) {
      this.logger.error('이메일 인증 토큰 생성 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, '이메일 인증 토큰 생성에 실패했습니다');
    }
  }

  /**
   * 비밀번호 재설정 토큰 생성
   */
  async generatePasswordResetToken(userId: UserId): Promise<string> {
    // TODO: 비밀번호 재설정 기능 구현 (Day 4+)
    const tokenValue = this.generateSecureToken();
    return tokenValue;
  }

  /**
   * 모든 Refresh Token 무효화 (로그아웃)
   */
  async revokeAllRefreshTokens(userId: UserId): Promise<void> {
    try {
      await this.refreshTokenRepository.deleteAllByUserId(userId);
      this.logger.info('모든 Refresh Token 무효화', { userId: userId.value });
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, 'Token 무효화에 실패했습니다');
    }
  }

  /**
   * 특정 디바이스의 Refresh Token 무효화
   */
  async revokeRefreshToken(refreshToken: Token): Promise<void> {
    try {
      const storedToken = await this.refreshTokenRepository.findByToken(refreshToken);
      if (storedToken) {
        await this.refreshTokenRepository.delete(storedToken.id);
        this.logger.info('Refresh Token 무효화', { tokenId: storedToken.id });
      }
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new AppError(ErrorCode.INTERNAL_ERROR, 'Token 무효화에 실패했습니다');
    }
  }

  /**
   * 안전한 랜덤 토큰 생성
   */
  private generateSecureToken(bytes: number = 32): string {
    return randomBytes(bytes).toString('hex');
  }
}
