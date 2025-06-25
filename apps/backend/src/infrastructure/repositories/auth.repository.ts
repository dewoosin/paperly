// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/auth.repository.ts

import { injectable } from 'tsyringe';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';
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
  private readonly prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
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
      await this.prisma.refreshToken.create({
        data: {
          id: uuidv4(),
          userId,
          token,
          expiresAt,
          deviceId,
          userAgent,
          ipAddress,
          createdAt: new Date(),
        },
      });

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
      return await this.prisma.refreshToken.findFirst({
        where: {
          token,
          expiresAt: {
            gt: new Date(),
          },
        },
        include: {
          user: true,
        },
      });
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
      await this.prisma.refreshToken.deleteMany({
        where: { token },
      });
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
      await this.prisma.refreshToken.deleteMany({
        where: { userId },
      });

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
      const result = await this.prisma.refreshToken.deleteMany({
        where: {
          expiresAt: {
            lt: new Date(),
          },
        },
      });

      this.logger.info('Expired refresh tokens cleaned up', { count: result.count });
      return result.count;
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
      await this.prisma.loginAttempt.create({
        data: {
          id: uuidv4(),
          email,
          success,
          ipAddress,
          userAgent,
          attemptedAt: new Date(),
        },
      });
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
      
      return await this.prisma.loginAttempt.findMany({
        where: {
          email,
          attemptedAt: {
            gte: since,
          },
        },
        orderBy: {
          attemptedAt: 'desc',
        },
      });
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
      await this.prisma.emailVerification.create({
        data: {
          id: uuidv4(),
          userId,
          token,
          expiresAt,
          createdAt: new Date(),
        },
      });

      this.logger.info('Email verification token saved', { userId });
    } catch (error) {
      this.logger.error('Failed to save email verification token', error);
      throw error;
    }
  }

  /**
   * 이메일 인증 토큰 조회
   */
  async findEmailVerificationToken(token: string): Promise<any | null> {
    try {
      return await this.prisma.emailVerification.findFirst({
        where: {
          token,
          expiresAt: {
            gt: new Date(),
          },
          verifiedAt: null,
        },
        include: {
          user: true,
        },
      });
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
      await this.prisma.emailVerification.update({
        where: { token },
        data: {
          verifiedAt: new Date(),
        },
      });

      this.logger.info('Email marked as verified', { token });
    } catch (error) {
      this.logger.error('Failed to mark email as verified', error);
      throw error;
    }
  }
}