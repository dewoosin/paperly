// /Users/workspace/paperly/apps/backend/src/infrastructure/repositories/user.repository.ts

import { Pool } from 'pg';
import { db } from '../config/database.config';
import { User } from '../../domain/entities/User.entity';
import { Email } from '../../domain/value-objects/email.vo';
import { Password } from '../../domain/value-objects/password.vo';
import { UserId } from '../../domain/value-objects/user-id.vo';
import { DatabaseError, NotFoundError } from '../../shared/errors';
import { Logger } from '../logging/Logger';
import { Gender } from '../../domain/auth/auth.types';

/**
 * 사용자 레포지토리 인터페이스
 */
export interface IUserRepository {
  save(user: User): Promise<void>;
  findById(id: UserId): Promise<User | null>;
  findByEmail(email: Email): Promise<User | null>;
  existsByEmail(email: Email): Promise<boolean>;
  updateEmailVerified(id: UserId, verified: boolean): Promise<void>;
  updatePassword(id: UserId, password: Password): Promise<void>;
  delete(id: UserId): Promise<void>;
}

/**
 * PostgreSQL 기반 사용자 레포지토리 구현
 */
export class UserRepository implements IUserRepository {
  private readonly logger = new Logger('UserRepository');

  /**
   * 사용자 저장 (생성 또는 업데이트)
   */
  async save(user: User): Promise<void> {
    const client = await db.getClient();
    try {
      const data = user.toPersistence();
      
      await client.query(
        `INSERT INTO users (id, email, password_hash, name, email_verified, birth_date, gender, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (id) DO UPDATE SET
           email = EXCLUDED.email,
           password_hash = EXCLUDED.password_hash,
           name = EXCLUDED.name,
           email_verified = EXCLUDED.email_verified,
           birth_date = EXCLUDED.birth_date,
           gender = EXCLUDED.gender,
           updated_at = EXCLUDED.updated_at`,
        [
          data.id,
          data.email,
          data.passwordHash,
          data.name,
          data.emailVerified,
          data.birthDate,
          data.gender,
          data.createdAt,
          data.updatedAt
        ]
      );

      this.logger.debug('사용자 저장 완료', { userId: data.id });
    } catch (error) {
      this.logger.error('사용자 저장 실패', error);
      throw new DatabaseError('사용자 저장에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * ID로 사용자 조회
   */
  async findById(id: UserId): Promise<User | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT id, email, password_hash, name, email_verified, birth_date, gender, created_at, updated_at
         FROM users
         WHERE id = $1`,
        [id.getValue()]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return User.fromPersistence({
        id: row.id,
        email: row.email,
        passwordHash: row.password_hash,
        name: row.name,
        emailVerified: row.email_verified,
        birthDate: row.birth_date,
        gender: row.gender as Gender,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      });
    } catch (error) {
      this.logger.error('사용자 조회 실패', error);
      throw new DatabaseError('사용자 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일로 사용자 조회
   */
  async findByEmail(email: Email): Promise<User | null> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT id, email, password_hash, name, email_verified, birth_date, gender, created_at, updated_at
         FROM users
         WHERE email = $1`,
        [email.getValue()]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return User.fromPersistence({
        id: row.id,
        email: row.email,
        passwordHash: row.password_hash,
        name: row.name,
        emailVerified: row.email_verified,
        birthDate: row.birth_date,
        gender: row.gender as Gender,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      });
    } catch (error) {
      this.logger.error('이메일로 사용자 조회 실패', error);
      throw new DatabaseError('사용자 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 존재 여부 확인
   */
  async existsByEmail(email: Email): Promise<boolean> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        'SELECT EXISTS(SELECT 1 FROM users WHERE email = $1) as exists',
        [email.getValue()]
      );

      return result.rows[0].exists;
    } catch (error) {
      this.logger.error('이메일 존재 여부 확인 실패', error);
      throw new DatabaseError('이메일 확인에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증 상태 업데이트
   */
  async updateEmailVerified(id: UserId, verified: boolean): Promise<void> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `UPDATE users
         SET email_verified = $1, updated_at = NOW()
         WHERE id = $2`,
        [verified, id.getValue()]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('사용자를 찾을 수 없습니다');
      }

      this.logger.debug('이메일 인증 상태 업데이트', { 
        userId: id.getValue(), 
        verified 
      });
    } catch (error) {
      this.logger.error('이메일 인증 상태 업데이트 실패', error);
      throw new DatabaseError('이메일 인증 상태 업데이트에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 비밀번호 업데이트
   */
  async updatePassword(id: UserId, password: Password): Promise<void> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `UPDATE users
         SET password_hash = $1, updated_at = NOW()
         WHERE id = $2`,
        [password.getHashedValue(), id.getValue()]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('사용자를 찾을 수 없습니다');
      }

      this.logger.debug('비밀번호 업데이트 완료', { userId: id.getValue() });
    } catch (error) {
      this.logger.error('비밀번호 업데이트 실패', error);
      throw new DatabaseError('비밀번호 업데이트에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자 삭제
   */
  async delete(id: UserId): Promise<void> {
    const client = await db.getClient();
    try {
      await client.query('BEGIN');

      // 관련 데이터 삭제 (cascade 설정이 없는 경우)
      await client.query(
        'DELETE FROM refresh_tokens WHERE user_id = $1',
        [id.getValue()]
      );
      
      await client.query(
        'DELETE FROM email_verification_tokens WHERE user_id = $1',
        [id.getValue()]
      );

      // 사용자 삭제
      const result = await client.query(
        'DELETE FROM users WHERE id = $1',
        [id.getValue()]
      );

      if (result.rowCount === 0) {
        await client.query('ROLLBACK');
        throw new NotFoundError('사용자를 찾을 수 없습니다');
      }

      await client.query('COMMIT');
      this.logger.info('사용자 삭제 완료', { userId: id.getValue() });
    } catch (error) {
      await client.query('ROLLBACK');
      this.logger.error('사용자 삭제 실패', error);
      throw new DatabaseError('사용자 삭제에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 사용자 수 조회
   */
  async count(): Promise<number> {
    const client = await db.getClient();
    try {
      const result = await client.query('SELECT COUNT(*) as count FROM users');
      return parseInt(result.rows[0].count, 10);
    } catch (error) {
      this.logger.error('사용자 수 조회 실패', error);
      throw new DatabaseError('사용자 수 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }

  /**
   * 이메일 인증되지 않은 사용자 조회
   */
  async findUnverifiedUsers(days: number = 7): Promise<User[]> {
    const client = await db.getClient();
    try {
      const result = await client.query(
        `SELECT id, email, password_hash, name, email_verified, birth_date, gender, created_at, updated_at
         FROM users
         WHERE email_verified = false
         AND created_at < NOW() - INTERVAL '${days} days'
         ORDER BY created_at DESC`,
        []
      );

      return result.rows.map(row => User.fromPersistence({
        id: row.id,
        email: row.email,
        passwordHash: row.password_hash,
        name: row.name,
        emailVerified: row.email_verified,
        birthDate: row.birth_date,
        gender: row.gender as Gender,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      }));
    } catch (error) {
      this.logger.error('미인증 사용자 조회 실패', error);
      throw new DatabaseError('미인증 사용자 조회에 실패했습니다');
    } finally {
      client.release();
    }
  }
}