// apps/backend/src/domain/repositories/refresh-token.repository.ts

import { Token, DeviceInfo } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';
import { Email } from '../value-objects/email.vo';

/**
 * Refresh Token 리포지토리 인터페이스
 */
export interface IRefreshTokenRepository {
  /**
   * Refresh Token 저장
   */
  save(refreshToken: {
    token: Token;
    userId: UserId;
    expiresAt: Date;
    deviceInfo?: DeviceInfo;
  }): Promise<void>;

  /**
   * Token으로 조회
   */
  findByToken(token: Token): Promise<{
    userId: UserId;
    expiresAt: Date;
    deviceInfo?: DeviceInfo;
  } | null>;

  /**
   * 사용자의 모든 토큰 무효화
   */
  revokeAllByUserId(userId: UserId): Promise<void>;

  /**
   * 특정 토큰 무효화
   */
  revokeByToken(token: Token): Promise<void>;

  /**
   * 만료된 토큰 정리
   */
  cleanupExpiredTokens(): Promise<void>;
}

// =============================================================================

// apps/backend/src/domain/repositories/email-verification.repository.ts

/**
 * 이메일 인증 리포지토리 인터페이스
 */
export interface IEmailVerificationRepository {
  /**
   * 이메일 인증 정보 저장
   */
  save(verification: {
    userId: UserId;
    email: Email;
    token: Token;
    expiresAt: Date;
    verified: boolean;
  }): Promise<void>;

  /**
   * Token으로 인증 정보 조회
   */
  findByToken(token: Token): Promise<{
    userId: UserId;
    email: Email;
    expiresAt: Date;
    verified: boolean;
    isExpired(): boolean;
    isVerified(): boolean;
    markAsVerified(): void;
  } | null>;

  /**
   * 사용자 ID로 인증 정보 조회
   */
  findByUserId(userId: UserId): Promise<{
    email: Email;
    token: Token;
    expiresAt: Date;
    verified: boolean;
  } | null>;

  /**
   * 만료된 인증 정보 정리
   */
  cleanupExpiredVerifications(): Promise<void>;
}

// =============================================================================

// apps/backend/src/domain/repositories/login-attempt.repository.ts

/**
 * 로그인 시도 기록 정보
 */
export interface LoginAttempt {
  email: string;
  ipAddress?: string;
  userAgent: string;
  success: boolean;
  failureReason?: string | null;
  attemptedAt?: Date;
}

/**
 * 로그인 시도 리포지토리 인터페이스
 */
export interface ILoginAttemptRepository {
  /**
   * 로그인 시도 기록 저장
   */
  create(attempt: LoginAttempt): Promise<void>;

  /**
   * 특정 이메일의 최근 실패 시도 수 조회
   */
  getRecentFailedAttempts(email: Email, timeWindowMinutes: number): Promise<number>;

  /**
   * 특정 IP의 최근 시도 수 조회
   */
  getRecentAttemptsByIp(ipAddress: string, timeWindowMinutes: number): Promise<number>;

  /**
   * 오래된 로그인 시도 기록 정리
   */
  cleanupOldAttempts(olderThanDays: number): Promise<void>;
}