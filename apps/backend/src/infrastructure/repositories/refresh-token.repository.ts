// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/refresh-token.repository.ts

import { db } from '../config/database.config';
import { IRefreshTokenRepository } from '../../domain/repositories/refresh-token.repository';
import { DatabaseError, NotFoundError } from '../../shared/errors';
import { Logger } from '../logging/Logger';
import crypto from 'crypto';

/**
 * Refresh Token Repository 구현
 */
export class RefreshTokenRepository implements IRefreshTokenRepository {
  private readonly logger = new Logger('RefreshTokenRepository');

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
    return await db.transaction(async (client) => {
      try {
        // 토큰을 해시화해서 저장 (보안)
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        
        await client.query(
          `INSERT INTO refresh_tokens (
             user_id, token_hash, device_id, device_name, user_agent, ip_address, expires_at
           )
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [userId, tokenHash, deviceId, deviceId, userAgent, ipAddress, expiresAt]
        );

        this.logger.debug('Refresh token 저장 완료', { userId, deviceId });
      } catch (error) {
        this.logger.error('Refresh token 저장 실패', error);
        throw new DatabaseError('Refresh token 저장에 실패했습니다');
      }
    });
  }

  /**
   * Refresh Token으로 조회
   */
  async findRefreshToken(token: string): Promise<any | null> {
    const client = await db.getClient();
    try {
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
      
      const result = await client.query(
        `SELECT rt.*, u.id as user_id, u.email, u.name
         FROM refresh_tokens rt
         JOIN users u ON rt.user_id = u.id
         WHERE rt.token_hash = $1 AND rt.expires_at > NOW()`,
        [tokenHash]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        userId: row.user_id,
        tokenHash: row.token_hash,
        deviceId: row.device_id,
        deviceName: row.device_name,
        userAgent: row.user_agent,
        ipAddress: row.ip_address,
        expiresAt: row.expires_at,
        lastUsedAt: row.last_used_at,
        createdAt: row.created_at,
        user: {
          id: row.user_id,
          email: row.email,
          name: row.name
        }
      };
    } catch (error) {
      this.logger.error('Refresh token 조회 실패', error);
      throw new DatabaseError('Refresh token 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * Refresh Token 삭제
   */
  async deleteRefreshToken(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
      
      const result = await client.query(
        'DELETE FROM refresh_tokens WHERE token_hash = $1',
        [tokenHash]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('Refresh token을 찾을 수 없습니다');
      }

      this.logger.debug('Refresh token 삭제 완료');
    } catch (error) {
      this.logger.error('Refresh token 삭제 실패', error);
      throw new DatabaseError('Refresh token 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자의 모든 Refresh Token 삭제
   */
  async deleteAllUserRefreshTokens(userId: string): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query(
        'DELETE FROM refresh_tokens WHERE user_id = $1',
        [userId]
      );

      this.logger.debug('사용자 모든 refresh token 삭제 완료', { userId });
    } catch (error) {
      this.logger.error('사용자 refresh token 삭제 실패', error);
      throw new DatabaseError('Refresh token 삭제에 실패했습니다');
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
        'DELETE FROM refresh_tokens WHERE expires_at <= NOW()'
      );

      const deletedCount = result.rowCount || 0;
      this.logger.info('만료된 refresh token 정리 완료', { deletedCount });
      
      return deletedCount;
    } catch (error) {
      this.logger.error('만료된 refresh token 정리 실패', error);
      throw new DatabaseError('만료된 토큰 정리에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 토큰 사용 시간 업데이트
   */
  async updateLastUsed(token: string): Promise<void> {
    const client = await db.getClient();
    try {
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
      
      await client.query(
        'UPDATE refresh_tokens SET last_used_at = NOW() WHERE token_hash = $1',
        [tokenHash]
      );

      this.logger.debug('Refresh token 사용 시간 업데이트');
    } catch (error) {
      this.logger.error('Refresh token 사용 시간 업데이트 실패', error);
      // 사용 시간 업데이트 실패는 치명적이지 않으므로 에러를 던지지 않음
    } finally {
      client.release();
    }
  }
}