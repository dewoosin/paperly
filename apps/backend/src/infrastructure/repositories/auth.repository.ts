// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/auth.repository.ts

import { v4 as uuidv4 } from 'uuid';
import { db } from '../config/database.config';
import { DatabaseError } from '../../shared/errors';
import { logger } from '../logging/logger';
import { 
  RefreshTokenModel, 
  EmailVerificationToken, 
  PasswordResetToken 
} from '../../domain/auth/auth.types';

/**
 * 인증 관련 레포지토리
 * 
 * 토큰 관리, 인증 관련 데이터 처리를 담당합니다.
 */
export class AuthRepository {
  private static readonly logger = new Logger('AuthRepository');

  /**
   * Refresh Token 저장
   */
  static async saveRefreshToken(
    userId: string,
    token: string,
    expiresAt: Date,
    deviceId?: string,
    userAgent?: string,
    ipAddress?: string
  ): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        `INSERT INTO refresh_tokens (id, user_id, token, expires_at, device_id, user_agent, ip_address, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
        [uuidv4(), userId, token, expiresAt, deviceId, userAgent, ipAddress]
      );
      
      this.logger.debug('Refresh token saved', { userId, deviceId });
    } catch (error) {
      this.logger.error('Failed to save refresh token', error);
      throw new DatabaseError('토큰 저장에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * Refresh Token 조회
   */
  static async findRefreshToken(token: string): Promise<RefreshTokenModel | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT id, user_id, token, expires_at, created_at, device_id, user_agent, ip_address
         FROM refresh_tokens
         WHERE token = $1 AND expires_at > NOW()`,
        [token]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        token: row.token,
        expiresAt: row.expires_at,
        createdAt: row.created_at,
        deviceId: row.device_id,
        userAgent: row.user_agent,
        ipAddress: row.ip_address,
      };
    } catch (error) {
      this.logger.error('Failed to find refresh token', error);
      throw new DatabaseError('토큰 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * Refresh Token 삭제
   */
  static async deleteRefreshToken(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM refresh_tokens WHERE token = $1',
        [token]
      );
      
      this.logger.debug('Refresh token deleted');
    } catch (error) {
      this.logger.error('Failed to delete refresh token', error);
      throw new DatabaseError('토큰 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자의 모든 Refresh Token 삭제
   */
  static async deleteAllUserRefreshTokens(userId: string): Promise<void> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'DELETE FROM refresh_tokens WHERE user_id = $1',
        [userId]
      );
      
      this.logger.info('All user refresh tokens deleted', { 
        userId, 
        count: result.rowCount 
      });
    } catch (error) {
      this.logger.error('Failed to delete user refresh tokens', error);
      throw new DatabaseError('사용자 토큰 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 만료된 토큰 정리
   */
  static async cleanupExpiredTokens(): Promise<number> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'DELETE FROM refresh_tokens WHERE expires_at < NOW()'
      );
      
      this.logger.info('Expired tokens cleaned up', { count: result.rowCount });
      return result.rowCount || 0;
    } catch (error) {
      this.logger.error('Failed to cleanup expired tokens', error);
      throw new DatabaseError('만료 토큰 정리에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 생성
   */
  static async createEmailVerificationToken(userId: string): Promise<EmailVerificationToken> {
    const client = await db.getClient();
    try {
      const token = uuidv4();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24시간

      const result = await client.query(
        `INSERT INTO email_verification_tokens (id, user_id, token, expires_at, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         RETURNING id, user_id, token, expires_at, created_at`,
        [uuidv4(), userId, token, expiresAt]
      );

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        token: row.token,
        expiresAt: row.expires_at,
        createdAt: row.created_at,
      };
    } catch (error) {
      this.logger.error('Failed to create email verification token', error);
      throw new DatabaseError('이메일 인증 토큰 생성에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 조회
   */
  static async findEmailVerificationToken(token: string): Promise<EmailVerificationToken | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT id, user_id, token, expires_at, created_at
         FROM email_verification_tokens
         WHERE token = $1 AND expires_at > NOW()`,
        [token]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        token: row.token,
        expiresAt: row.expires_at,
        createdAt: row.created_at,
      };
    } catch (error) {
      this.logger.error('Failed to find email verification token', error);
      throw new DatabaseError('이메일 인증 토큰 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 삭제
   */
  static async deleteEmailVerificationToken(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM email_verification_tokens WHERE token = $1',
        [token]
      );
    } catch (error) {
      this.logger.error('Failed to delete email verification token', error);
      throw new DatabaseError('이메일 인증 토큰 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }
}

// Logger import 수정
import { Logger } from '../logging/Logger';