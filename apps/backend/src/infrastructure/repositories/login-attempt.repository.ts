// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/login-attempt.repository.ts

import { injectable, inject } from 'tsyringe';
import { Pool } from 'pg';
import { Logger } from '../logging/Logger';

/**
 * 로그인 시도 기록 리포지토리
 * 
 * 보안 목적으로 로그인 시도를 추적하고 기록합니다.
 * 무차별 대입 공격 방지 및 보안 모니터링에 사용됩니다.
 */
@injectable()
export class LoginAttemptRepository {
  private readonly logger = new Logger('LoginAttemptRepository');

  constructor(
    @inject('DatabasePool') private readonly pool: Pool
  ) {
    this.logger.info('LoginAttemptRepository initialized');
  }

  /**
   * 로그인 시도 기록
   */
  async recordLoginAttempt(
    email: string,
    ipAddress: string,
    userAgent: string,
    deviceId: string,
    success: boolean,
    failureReason?: string
  ): Promise<void> {
    try {
      const query = `
        INSERT INTO login_attempts 
        (email, ip_address, user_agent, device_id, success, failure_reason, attempted_at)
        VALUES ($1, $2, $3, $4, $5, $6, NOW())
      `;

      const values = [email, ipAddress, userAgent, deviceId, success, failureReason];
      await this.pool.query(query, values);

      this.logger.info('Login attempt recorded', { 
        email, 
        ipAddress, 
        success,
        failureReason 
      });
    } catch (error) {
      this.logger.error('Failed to record login attempt', error);
      // Don't throw error to prevent login process failure
    }
  }

  /**
   * 특정 IP의 최근 실패한 로그인 시도 횟수 조회
   */
  async getRecentFailedAttempts(
    ipAddress: string, 
    timeWindowMinutes: number = 15
  ): Promise<number> {
    try {
      const query = `
        SELECT COUNT(*) 
        FROM login_attempts 
        WHERE ip_address = $1 
          AND success = false 
          AND attempted_at > NOW() - INTERVAL '${timeWindowMinutes} minutes'
      `;

      const result = await this.pool.query(query, [ipAddress]);
      const count = parseInt(result.rows[0].count);

      this.logger.debug('Recent failed attempts count', { ipAddress, count });
      return count;
    } catch (error) {
      this.logger.error('Failed to get recent failed attempts', error);
      return 0; // Return 0 to allow login on error
    }
  }

  /**
   * 특정 이메일의 최근 실패한 로그인 시도 횟수 조회
   */
  async getRecentFailedAttemptsForEmail(
    email: string, 
    timeWindowMinutes: number = 15
  ): Promise<number> {
    try {
      const query = `
        SELECT COUNT(*) 
        FROM login_attempts 
        WHERE email = $1 
          AND success = false 
          AND attempted_at > NOW() - INTERVAL '${timeWindowMinutes} minutes'
      `;

      const result = await this.pool.query(query, [email]);
      const count = parseInt(result.rows[0].count);

      this.logger.debug('Recent failed attempts for email', { email, count });
      return count;
    } catch (error) {
      this.logger.error('Failed to get recent failed attempts for email', error);
      return 0; // Return 0 to allow login on error
    }
  }

  /**
   * 성공한 로그인 이후 해당 IP/이메일의 실패 기록 정리
   */
  async clearFailedAttempts(email: string, ipAddress: string): Promise<void> {
    try {
      // This could be implemented to clean up old failed attempts
      // For now, we just log the successful login
      this.logger.info('Login successful, failed attempts will expire naturally', {
        email,
        ipAddress
      });
    } catch (error) {
      this.logger.error('Failed to clear failed attempts', error);
      // Don't throw error
    }
  }

  /**
   * 로그인 시도 통계 조회 (관리자용)
   */
  async getLoginAttemptStats(startDate: Date, endDate: Date): Promise<any> {
    try {
      const query = `
        SELECT 
          DATE(attempted_at) as date,
          COUNT(*) as total_attempts,
          COUNT(*) FILTER (WHERE success = true) as successful_attempts,
          COUNT(*) FILTER (WHERE success = false) as failed_attempts,
          COUNT(DISTINCT ip_address) as unique_ips,
          COUNT(DISTINCT email) as unique_emails
        FROM login_attempts 
        WHERE attempted_at BETWEEN $1 AND $2
        GROUP BY DATE(attempted_at)
        ORDER BY date DESC
      `;

      const result = await this.pool.query(query, [startDate, endDate]);
      return result.rows;
    } catch (error) {
      this.logger.error('Failed to get login attempt stats', error);
      return [];
    }
  }

  /**
   * 의심스러운 로그인 시도 조회 (관리자용)
   */
  async getSuspiciousAttempts(limit: number = 100): Promise<any> {
    try {
      const query = `
        SELECT 
          email,
          ip_address,
          COUNT(*) as failed_count,
          MAX(attempted_at) as last_attempt,
          array_agg(DISTINCT user_agent) as user_agents
        FROM login_attempts 
        WHERE success = false 
          AND attempted_at > NOW() - INTERVAL '24 hours'
        GROUP BY email, ip_address
        HAVING COUNT(*) >= 3
        ORDER BY failed_count DESC, last_attempt DESC
        LIMIT $1
      `;

      const result = await this.pool.query(query, [limit]);
      return result.rows;
    } catch (error) {
      this.logger.error('Failed to get suspicious attempts', error);
      return [];
    }
  }
}