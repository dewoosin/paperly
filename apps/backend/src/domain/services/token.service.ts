// apps/backend/src/domain/services/token.service.ts (인터페이스)

import { User } from '../entities/user.entity';
import { Token, DeviceInfo } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * 토큰 서비스 인터페이스
 */
export interface ITokenService {
  /**
   * Access Token과 Refresh Token 생성
   */
  generateAuthTokens(user: User, deviceInfo?: DeviceInfo): Promise<{
    accessToken: string;
    refreshToken: string;
  }>;

  /**
   * Access Token 검증
   */
  verifyAccessToken(token: string): Promise<{
    sub: string;
    email: string;
    name: string;
    emailVerified: boolean;
  }>;

  /**
   * Refresh Token으로 새로운 토큰 발급
   */
  refreshTokens(refreshToken: Token): Promise<{
    accessToken: string;
    refreshToken: string;
  }>;

  /**
   * 이메일 인증 토큰 생성
   */
  generateEmailVerificationToken(userId: UserId): Promise<string>;

  /**
   * 비밀번호 재설정 토큰 생성
   */
  generatePasswordResetToken(userId: UserId): Promise<string>;

  /**
   * 모든 Refresh Token 무효화
   */
  revokeAllRefreshTokens(userId: UserId): Promise<void>;

  /**
   * 특정 Refresh Token 무효화
   */
  revokeRefreshToken(refreshToken: Token): Promise<void>;
}
