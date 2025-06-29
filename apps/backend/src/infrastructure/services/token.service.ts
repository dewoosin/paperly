// apps/backend/src/infrastructure/services/token.service.ts

import { injectable, inject } from 'tsyringe';
import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';
import { ITokenService } from '../../domain/services/token.service';
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';
import { EmailVerificationRepository } from '../repositories/email-verification.repository';
import { User } from '../../domain/entities/User.entity';
import { jwtConfig } from '../auth/jwt.config';
import { DatabaseError, UnauthorizedError } from '../../shared/errors';
import { Logger } from '../logging/Logger';

import { JwtService } from '../auth/jwt.service';
import { JwtPayload } from '../auth/jwt.config';

/**
 * 토큰 서비스 구현
 * - JWT 기반 Access Token
 * - 암호화된 Refresh Token
 * - 이메일 인증 토큰
 */
@injectable()
export class TokenService implements ITokenService {
  private readonly logger = new Logger('TokenService');
  private readonly refreshTokenExpiresIn: number = 7 * 24 * 60 * 60 * 1000; // 7일 (밀리초)
  private readonly emailVerificationExpiresIn: number = 24 * 60 * 60 * 1000; // 24시간 (밀리초)

  constructor(
    @inject('RefreshTokenRepository') private refreshTokenRepository: RefreshTokenRepository,
    @inject('EmailVerificationRepository') private emailVerificationRepository: EmailVerificationRepository
  ) {}

  /**
   * Access Token과 Refresh Token 생성
   */
  async generateAuthTokens(user: User, deviceInfo?: any): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. Access Token 생성
      const accessToken = this.generateAccessToken(user);

      // 2. Refresh Token 생성
      const refreshTokenValue = this.generateSecureToken();

      // 3. Refresh Token DB 저장
      const expiresAt = new Date(Date.now() + this.refreshTokenExpiresIn);
      
      await this.refreshTokenRepository.saveRefreshToken(
        user.id.getValue(),
        refreshTokenValue,
        expiresAt,
        deviceInfo?.id,
        deviceInfo?.userAgent,
        deviceInfo?.ipAddress
      );

      this.logger.info('인증 토큰 생성 완료', { userId: user.id.getValue() });

      return {
        accessToken,
        refreshToken: refreshTokenValue
      };
    } catch (error) {
      this.logger.error('토큰 생성 실패', { error });
      throw new DatabaseError('토큰 생성에 실패했습니다');
    }
  }

  /**
   * Access Token 생성
   */
  private generateAccessToken(user: User): string {
    return JwtService.generateAccessToken(
      user.id.getValue(),
      user.email.getValue(),
      user.userType,
      user.userCode || 'unknown',
      undefined, // role
      undefined  // permissions
    );
  }

  /**
   * Access Token 검증
   */
  async verifyAccessToken(token: string): Promise<JwtPayload> {
    return JwtService.verifyAccessToken(token);
  }

  /**
   * Refresh Token으로 새로운 토큰 발급
   */
  async refreshTokens(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // 1. DB에서 Refresh Token 조회
      const storedToken = await this.refreshTokenRepository.findRefreshToken(refreshToken);
      
      if (!storedToken) {
        throw new UnauthorizedError('유효하지 않은 Refresh Token입니다');
      }

      // 2. 만료 확인은 이미 DB 쿼리에서 처리됨

      // 3. 기존 Refresh Token 삭제
      await this.refreshTokenRepository.deleteRefreshToken(refreshToken);

      // 4. 사용자 정보로 새로운 토큰 발급
      const user = {
        id: { getValue: () => storedToken.userId },
        email: { getValue: () => storedToken.user.email },
        name: storedToken.user.name,
        emailVerified: true,
        userType: storedToken.user.userType || 'reader',
        userCode: storedToken.user.userCode || 'unknown'
      } as User;

      // 5. 새로운 토큰 발급
      const newTokens = await this.generateAuthTokens(user, {
        id: storedToken.deviceId,
        userAgent: storedToken.userAgent,
        ipAddress: storedToken.ipAddress
      });

      // 6. 사용 시간 업데이트
      await this.refreshTokenRepository.updateLastUsed(refreshToken);

      this.logger.info('토큰 갱신 완료', { userId: storedToken.userId });

      return newTokens;
    } catch (error) {
      if (error instanceof UnauthorizedError) {
        throw error;
      }
      this.logger.error('토큰 갱신 실패', { error });
      throw new DatabaseError('토큰 갱신에 실패했습니다');
    }
  }

  /**
   * 이메일 인증 토큰 생성
   */
  async generateEmailVerificationToken(userId: string, email: string): Promise<string> {
    try {
      const tokenValue = this.generateSecureToken();
      const expiresAt = new Date(Date.now() + this.emailVerificationExpiresIn);

      await this.emailVerificationRepository.saveEmailVerificationToken(
        userId,
        tokenValue,
        email,
        expiresAt
      );

      this.logger.info('이메일 인증 토큰 생성', { userId });

      return tokenValue;
    } catch (error) {
      this.logger.error('이메일 인증 토큰 생성 실패', { error });
      throw new DatabaseError('이메일 인증 토큰 생성에 실패했습니다');
    }
  }

  /**
   * 비밀번호 재설정 토큰 생성
   */
  async generatePasswordResetToken(userId: string): Promise<string> {
    // TODO: 비밀번호 재설정 기능 구현 (Day 4+)
    const tokenValue = this.generateSecureToken();
    return tokenValue;
  }

  /**
   * 모든 Refresh Token 무효화 (로그아웃)
   */
  async revokeAllRefreshTokens(userId: string): Promise<void> {
    try {
      await this.refreshTokenRepository.deleteAllUserRefreshTokens(userId);
      this.logger.info('모든 Refresh Token 무효화', { userId });
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new DatabaseError('Token 무효화에 실패했습니다');
    }
  }

  /**
   * 특정 디바이스의 Refresh Token 무효화
   */
  async revokeRefreshToken(refreshToken: string): Promise<void> {
    try {
      await this.refreshTokenRepository.deleteRefreshToken(refreshToken);
      this.logger.info('Refresh Token 무효화', { refreshToken });
    } catch (error) {
      this.logger.error('Refresh Token 무효화 실패', { error });
      throw new DatabaseError('Token 무효화에 실패했습니다');
    }
  }

  /**
   * 토큰 쌍 생성 (호환성을 위한 간단한 메서드)
   */
  generateTokenPair(userId: string, email: string): { accessToken: string; refreshToken: string } {
    const user = {
      id: { getValue: () => userId },
      email: { getValue: () => email },
      name: 'User',
      emailVerified: false,
      userType: 'reader',
      userCode: 'unknown'
    } as User;

    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateSecureToken();

    this.logger.info('토큰 쌍 생성 (간단)', { userId });

    return {
      accessToken,
      refreshToken
    };
  }

  /**
   * 안전한 랜덤 토큰 생성
   */
  private generateSecureToken(bytes: number = 32): string {
    return randomBytes(bytes).toString('hex');
  }
}
