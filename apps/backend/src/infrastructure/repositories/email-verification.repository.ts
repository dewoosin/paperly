// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/email-verification.repository.ts

import { db } from '../config/database.config';
import { IEmailVerificationRepository } from '../../domain/repositories/email-verification.repository';
import { DatabaseError, NotFoundError } from '../../shared/errors';
import { Logger } from '../logging/Logger';

/**
 * Email Verification Repository 구현
 */
export class EmailVerificationRepository implements IEmailVerificationRepository {
  private readonly logger = new Logger('EmailVerificationRepository');

  /**
   * 이메일 인증 토큰 저장
   */
  async saveEmailVerificationToken(
    userId: string, 
    token: string, 
    email: string,
    expiresAt: Date
  ): Promise<void> {
    return await db.transaction(async (client) => {
      try {
        // 기존 토큰 삭제 (사용자당 하나만 유지)
        await client.query(
          'DELETE FROM email_verification_tokens WHERE user_id = $1',
          [userId]
        );

        // 새 토큰 저장
        await client.query(
          `INSERT INTO email_verification_tokens (
             user_id, token, email, expires_at
           )
           VALUES ($1, $2, $3, $4)`,
          [userId, token, email, expiresAt]
        );

        this.logger.debug('이메일 인증 토큰 저장 완료', { userId, email });
      } catch (error) {
        this.logger.error('이메일 인증 토큰 저장 실패', error);
        throw new DatabaseError('이메일 인증 토큰 저장에 실패했습니다');
      }
    });
  }

  /**
   * 토큰으로 이메일 인증 정보 조회
   */
  async findEmailVerificationToken(token: string): Promise<any | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT evt.*, u.id as user_id, u.email as user_email, u.name
         FROM email_verification_tokens evt
         JOIN users u ON evt.user_id = u.id
         WHERE evt.token = $1 AND evt.expires_at > NOW() AND evt.verified_at IS NULL`,
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
        email: row.email,
        expiresAt: row.expires_at,
        verifiedAt: row.verified_at,
        createdAt: row.created_at,
        user: {
          id: row.user_id,
          email: row.user_email,
          name: row.name
        }
      };
    } catch (error) {
      this.logger.error('이메일 인증 토큰 조회 실패', error);
      throw new DatabaseError('이메일 인증 토큰 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 완료 처리
   */
  async markEmailAsVerified(token: string): Promise<void> {
    return await db.transaction(async (client) => {
      try {
        // 1. 토큰 검증 및 인증 완료 표시
        const result = await client.query(
          `UPDATE email_verification_tokens 
           SET verified_at = NOW() 
           WHERE token = $1 AND expires_at > NOW() AND verified_at IS NULL
           RETURNING user_id`,
          [token]
        );

        if (result.rows.length === 0) {
          throw new NotFoundError('유효하지 않은 인증 토큰입니다');
        }

        const userId = result.rows[0].user_id;

        // 2. 사용자 테이블의 이메일 인증 상태 업데이트
        await client.query(
          'UPDATE users SET email_verified = true, updated_at = NOW() WHERE id = $1',
          [userId]
        );

        this.logger.info('이메일 인증 완료', { userId, token });
      } catch (error) {
        this.logger.error('이메일 인증 처리 실패', error);
        if (error instanceof NotFoundError) {
          throw error;
        }
        throw new DatabaseError('이메일 인증 처리에 실패했습니다');
      }
    });
  }

  /**
   * 사용자 ID로 미인증 토큰 조회
   */
  async findPendingTokenByUserId(userId: string): Promise<any | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT * FROM email_verification_tokens 
         WHERE user_id = $1 AND expires_at > NOW() AND verified_at IS NULL
         ORDER BY created_at DESC
         LIMIT 1`,
        [userId]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        token: row.token,
        email: row.email,
        expiresAt: row.expires_at,
        verifiedAt: row.verified_at,
        createdAt: row.created_at
      };
    } catch (error) {
      this.logger.error('미인증 토큰 조회 실패', error);
      throw new DatabaseError('미인증 토큰 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 만료된 토큰 정리
   */
  async cleanupExpiredTokens(): Promise<number> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'DELETE FROM email_verification_tokens WHERE expires_at <= NOW()'
      );

      const deletedCount = result.rowCount || 0;
      this.logger.info('만료된 이메일 인증 토큰 정리 완료', { deletedCount });
      
      return deletedCount;
    } catch (error) {
      this.logger.error('만료된 이메일 인증 토큰 정리 실패', error);
      throw new DatabaseError('만료된 토큰 정리에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자의 모든 이메일 인증 토큰 삭제
   */
  async deleteAllUserTokens(userId: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM email_verification_tokens WHERE user_id = $1',
        [userId]
      );

      this.logger.debug('사용자 모든 이메일 인증 토큰 삭제 완료', { userId });
    } catch (error) {
      this.logger.error('사용자 이메일 인증 토큰 삭제 실패', error);
      throw new DatabaseError('이메일 인증 토큰 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }
}