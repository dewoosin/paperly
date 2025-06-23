// apps/backend/src/infrastructure/repositories/auth.repository.ts

import { Pool } from 'pg';
import crypto from 'crypto';
import { db } from '../database/connection';
import { RefreshTokenModel, EmailVerificationToken } from '../../domain/auth/auth.types';
import { DatabaseError } from '../../shared/errors';
import { logger } from '../logging/logger';

/**
 * 인증 관련 데이터베이스 작업을 담당하는 레포지토리
 */
export class AuthRepository {
  /**
   * Refresh Token 저장
   * 
   * @param userId - 사용자 ID
   * @param token - Refresh Token
   * @param deviceId - 디바이스 ID (선택)
   * @param userAgent - User Agent (선택)
   * @param ipAddress - IP 주소 (선택)
   * @param expiresAt - 만료 시간
   * @returns 저장된 토큰 정보
   */
  static async saveRefreshToken(
    userId: string,
    token: string,
    expiresAt: Date,
    deviceId?: string,
    userAgent?: string,
    ipAddress?: string
  ): Promise<RefreshTokenModel> {
    const client = await db.getClient();
    try {
      // 먼저 refresh_tokens 테이블이 없으면 생성
      await client.query(`
        CREATE TABLE IF NOT EXISTS refresh_tokens (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token TEXT NOT NULL UNIQUE,
          device_id TEXT,
          user_agent TEXT,
          ip_address TEXT,
          expires_at TIMESTAMPTZ NOT NULL,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        
        CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
        CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
        CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
      `);

      const result = await client.query<RefreshTokenModel>(
        `INSERT INTO refresh_tokens 
         (user_id, token, device_id, user_agent, ip_address, expires_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [userId, token, deviceId, userAgent, ipAddress, expiresAt]
      );

      logger.info('Refresh token saved', { userId, deviceId });
      return this.mapToRefreshTokenModel(result.rows[0]);
    } catch (error) {
      logger.error('Failed to save refresh token:', error);
      throw new DatabaseError('Failed to save refresh token');
    } finally {
      client.release();
    }
  }

  /**
   * Refresh Token 조회
   * 
   * @param token - 토큰 값
   * @returns 토큰 정보 또는 null
   */
  static async findRefreshToken(token: string): Promise<RefreshTokenModel | null> {
    const client = await db.getClient();
    try {
      const result = await client.query<RefreshTokenModel>(
        `SELECT * FROM refresh_tokens 
         WHERE token = $1 AND expires_at > CURRENT_TIMESTAMP`,
        [token]
      );

      if (result.rows.length === 0) {
        return null;
      }

      return this.mapToRefreshTokenModel(result.rows[0]);
    } catch (error) {
      logger.error('Failed to find refresh token:', error);
      throw new DatabaseError('Failed to find refresh token');
    } finally {
      client.release();
    }
  }

  /**
   * Refresh Token 삭제
   * 
   * @param token - 삭제할 토큰
   */
  static async deleteRefreshToken(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM refresh_tokens WHERE token = $1',
        [token]
      );
      logger.info('Refresh token deleted');
    } catch (error) {
      logger.error('Failed to delete refresh token:', error);
      throw new DatabaseError('Failed to delete refresh token');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자의 모든 Refresh Token 삭제
   * 
   * @param userId - 사용자 ID
   */
  static async deleteAllUserRefreshTokens(userId: string): Promise<void> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'DELETE FROM refresh_tokens WHERE user_id = $1',
        [userId]
      );
      logger.info('All user refresh tokens deleted', { 
        userId, 
        count: result.rowCount 
      });
    } catch (error) {
      logger.error('Failed to delete user refresh tokens:', error);
      throw new DatabaseError('Failed to delete user refresh tokens');
    } finally {
      client.release();
    }
  }

  /**
   * 만료된 Refresh Token 정리
   */
  static async cleanupExpiredTokens(): Promise<number> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'DELETE FROM refresh_tokens WHERE expires_at < CURRENT_TIMESTAMP'
      );
      const deletedCount = result.rowCount || 0;
      
      if (deletedCount > 0) {
        logger.info('Expired refresh tokens cleaned up', { count: deletedCount });
      }
      
      return deletedCount;
    } catch (error) {
      logger.error('Failed to cleanup expired tokens:', error);
      throw new DatabaseError('Failed to cleanup expired tokens');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 생성 및 저장
   * 
   * @param userId - 사용자 ID
   * @returns 생성된 토큰 정보
   */
  static async createEmailVerificationToken(userId: string): Promise<EmailVerificationToken> {
    const client = await db.getClient();
    try {
      // 테이블이 없으면 생성
      await client.query(`
        CREATE TABLE IF NOT EXISTS email_verification_tokens (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          token TEXT NOT NULL UNIQUE,
          expires_at TIMESTAMPTZ NOT NULL,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          CONSTRAINT fk_user_verification FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        );
        
        CREATE INDEX IF NOT EXISTS idx_email_verification_user_id ON email_verification_tokens(user_id);
        CREATE INDEX IF NOT EXISTS idx_email_verification_token ON email_verification_tokens(token);
      `);

      // 기존 토큰 삭제
      await client.query(
        'DELETE FROM email_verification_tokens WHERE user_id = $1',
        [userId]
      );

      // 새 토큰 생성
      const token = crypto.randomBytes(32).toString('hex');
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24시간 후 만료

      const result = await client.query<EmailVerificationToken>(
        `INSERT INTO email_verification_tokens 
         (user_id, token, expires_at)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [userId, token, expiresAt]
      );

      logger.info('Email verification token created', { userId });
      return this.mapToEmailVerificationToken(result.rows[0]);
    } catch (error) {
      logger.error('Failed to create email verification token:', error);
      throw new DatabaseError('Failed to create email verification token');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 조회
   * 
   * @param token - 토큰 값
   * @returns 토큰 정보 또는 null
   */
  static async findEmailVerificationToken(token: string): Promise<EmailVerificationToken | null> {
    const client = await db.getClient();
    try {
      const result = await client.query<EmailVerificationToken>(
        `SELECT * FROM email_verification_tokens 
         WHERE token = $1 AND expires_at > CURRENT_TIMESTAMP`,
        [token]
      );

      if (result.rows.length === 0) {
        return null;
      }

      return this.mapToEmailVerificationToken(result.rows[0]);
    } catch (error) {
      logger.error('Failed to find email verification token:', error);
      throw new DatabaseError('Failed to find email verification token');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 토큰 삭제
   * 
   * @param token - 삭제할 토큰
   */
  static async deleteEmailVerificationToken(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM email_verification_tokens WHERE token = $1',
        [token]
      );
      logger.info('Email verification token deleted');
    } catch (error) {
      logger.error('Failed to delete email verification token:', error);
      throw new DatabaseError('Failed to delete email verification token');
    } finally {
      client.release();
    }
  }

  /**
   * DB 결과를 RefreshTokenModel로 매핑
   */
  private static mapToRefreshTokenModel(row: any): RefreshTokenModel {
    return {
      id: row.id,
      userId: row.user_id,
      token: row.token,
      deviceId: row.device_id,
      userAgent: row.user_agent,
      ipAddress: row.ip_address,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    };
  }

  /**
   * DB 결과를 EmailVerificationToken으로 매핑
   */
  private static mapToEmailVerificationToken(row: any): EmailVerificationToken {
    return {
      id: row.id,
      userId: row.user_id,
      token: row.token,
      expiresAt: row.expires_at,
      createdAt: row.created_at,
    };
  }
}