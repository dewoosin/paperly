// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/auth.repository.ts

import { injectable } from 'tsyringe';
import { Logger } from '../logging/Logger';

/**
 * 인증 관련 리포지토리
 * 
 * Refresh Token, Email Verification, Login Attempt 등의
 * 인증 관련 데이터 액세스를 담당합니다.
 */
@injectable()
export class AuthRepository {
  private readonly logger = new Logger('AuthRepository');
  private refreshTokens = new Map();
  private loginAttempts = [];
  private emailVerifications = new Map();

  constructor() {
    this.logger.info('AuthRepository initialized with in-memory storage');
  }

  /**
   * Refresh Token 저장
   */
  async saveRefreshToken(
    userId: string,
    token: string,
    expiresAt: Date,
    deviceId?: string,
    userAgent?: string,
    ipAddress?: string
  ): Promise<void> {
    try {
      const tokenData = {
        userId,
        token,
        expiresAt,
        deviceId,
        userAgent,
        ipAddress,
        createdAt: new Date(),
      };

      this.refreshTokens.set(token, tokenData);
      this.logger.info('Refresh token saved', { userId, deviceId });
    } catch (error) {
      this.logger.error('Failed to save refresh token', error);
      throw error;
    }
  }

  /**
   * Refresh Token 조회
   */
  async findRefreshToken(token: string): Promise<any | null> {
    try {
      const tokenData = this.refreshTokens.get(token);
      if (tokenData && tokenData.expiresAt > new Date()) {
        return { ...tokenData, user: { id: tokenData.userId } };
      }
      return null;
    } catch (error) {
      this.logger.error('Failed to find refresh token', error);
      throw error;
    }
  }

  /**
   * Refresh Token 삭제
   */
  async deleteRefreshToken(token: string): Promise<void> {
    try {
      this.refreshTokens.delete(token);
      this.logger.info('Refresh token deleted', { token });
    } catch (error) {
      this.logger.error('Failed to delete refresh token', error);
      throw error;
    }
  }

  /**
   * 사용자의 모든 Refresh Token 삭제
   */
  async deleteAllUserRefreshTokens(userId: string): Promise<void> {
    try {
      for (const [token, data] of this.refreshTokens.entries()) {
        if (data.userId === userId) {
          this.refreshTokens.delete(token);
        }
      }

      this.logger.info('All refresh tokens deleted for user', { userId });
    } catch (error) {
      this.logger.error('Failed to delete all user refresh tokens', error);
      throw error;
    }
  }

  /**
   * 만료된 Refresh Token 정리
   */
  async cleanupExpiredRefreshTokens(): Promise<number> {
    try {
      let count = 0;
      const now = new Date();
      
      for (const [token, data] of this.refreshTokens.entries()) {
        if (data.expiresAt < now) {
          this.refreshTokens.delete(token);
          count++;
        }
      }

      this.logger.info('Expired refresh tokens cleaned up', { count });
      return count;
    } catch (error) {
      this.logger.error('Failed to cleanup expired refresh tokens', error);
      throw error;
    }
  }

  /**
   * 로그인 시도 기록
   */
  async recordLoginAttempt(
    email: string,
    success: boolean,
    ipAddress?: string,
    userAgent?: string
  ): Promise<void> {
    try {
      const attempt = {
        email,
        success,
        ipAddress,
        userAgent,
        attemptedAt: new Date(),
      };
      
      this.loginAttempts.push(attempt);
      this.logger.info('Login attempt recorded', attempt);
    } catch (error) {
      this.logger.error('Failed to record login attempt', error);
      throw error;
    }
  }

  /**
   * 최근 로그인 시도 조회
   */
  async getRecentLoginAttempts(
    email: string,
    minutes: number = 15
  ): Promise<any[]> {
    try {
      const since = new Date(Date.now() - minutes * 60 * 1000);
      
      return this.loginAttempts
        .filter(attempt => 
          attempt.email === email && 
          attempt.attemptedAt >= since
        )
        .sort((a, b) => b.attemptedAt.getTime() - a.attemptedAt.getTime());
    } catch (error) {
      this.logger.error('Failed to get recent login attempts', error);
      throw error;
    }
  }

  /**
   * 이메일 인증 토큰 저장
   */
  async saveEmailVerificationToken(
    userId: string,
    token: string,
    expiresAt: Date
  ): Promise<void> {
    try {
      this.emailVerifications.set(token, {
        userId,
        token,
        expiresAt,
        createdAt: new Date(),
        verifiedAt: null,
      });

      this.logger.info('Email verification token saved', { userId });
    } catch (error) {
      this.logger.error('Failed to save email verification token', error);
      throw error;
    }
  }

  /**
   * 이메일 인증 토큰 생성 (alias for saveEmailVerificationToken)
   */
  async createEmailVerificationToken(
    userId: string,
    token: string,
    expiresAt: Date
  ): Promise<void> {
    return this.saveEmailVerificationToken(userId, token, expiresAt);
  }

  /**
   * 이메일 인증 토큰 조회
   */
  async findEmailVerificationToken(token: string): Promise<any | null> {
    try {
      const verification = this.emailVerifications.get(token);
      if (verification && verification.expiresAt > new Date() && !verification.verifiedAt) {
        return { ...verification, user: { id: verification.userId } };
      }
      return null;
    } catch (error) {
      this.logger.error('Failed to find email verification token', error);
      throw error;
    }
  }

  /**
   * 이메일 인증 완료 처리
   */
  async markEmailAsVerified(token: string): Promise<void> {
    try {
      const verification = this.emailVerifications.get(token);
      if (verification) {
        verification.verifiedAt = new Date();
        this.logger.info('Email marked as verified', { token });
      }
    } catch (error) {
      this.logger.error('Failed to mark email as verified', error);
      throw error;
    }
  }

  /**
   * 이메일 인증 토큰 삭제
   */
  async deleteEmailVerificationToken(token: string): Promise<void> {
    try {
      this.emailVerifications.delete(token);
      this.logger.info('Email verification token deleted', { token });
    } catch (error) {
      this.logger.error('Failed to delete email verification token', error);
      throw error;
    }
  }

  /**
   * 만료된 토큰 정리
   */
  async cleanupExpiredTokens(): Promise<number> {
    try {
      const now = new Date();
      let count = 0;
      
      // Refresh Token 정리
      for (const [token, data] of this.refreshTokens.entries()) {
        if (data.expiresAt < now) {
          this.refreshTokens.delete(token);
          count++;
        }
      }

      // Email Verification Token 정리
      for (const [token, data] of this.emailVerifications.entries()) {
        if (data.expiresAt < now) {
          this.emailVerifications.delete(token);
          count++;
        }
      }

      this.logger.info('Expired tokens cleaned up', { count });
      return count;
    } catch (error) {
      this.logger.error('Failed to cleanup expired tokens', error);
      throw error;
    }
  }
}