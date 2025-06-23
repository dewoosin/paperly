// apps/backend/src/infrastructure/repositories/user.repository.ts

import { Pool } from 'pg';
import { db } from '../database/connection';
import { User } from '../../domain/entities/user.entity';
import { Email } from '../../domain/value-objects/email.vo';
import { Password } from '../../domain/value-objects/password.vo';
import { UserId } from '../../domain/value-objects/user-id.vo';
import { DatabaseError, NotFoundError } from '../../shared/errors';
import { logger } from '../logging/logger';
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
  /**
   * 사용자 저장
   */
  async save(user: User): Promise<void> {
    const client = await db.getClient();
    try {
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
          user.id.value,
          user.email.value,
          user.password.hashedValue,
          user.name,
          user.emailVerified,
          user.birthDate,
          user.gender,
          user.createdAt,
          user.updatedAt,
        ]
      );
      
      logger.info('User saved', { userId: user.id.value });
    } catch (error) {
      logger.error('Failed to save user:', error);
      if (error.code === '23505') { // Unique violation
        throw new DatabaseError('User with this email already exists');
      }
      throw new DatabaseError('Failed to save user');
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
        'SELECT * FROM users WHERE id = $1',
        [id.value]
      );

      if (result.rows.length === 0) {
        return null;
      }

      return this.mapToUser(result.rows[0]);
    } catch (error) {
      logger.error('Failed to find user by id:', error);
      throw new DatabaseError('Failed to find user');
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
        'SELECT * FROM users WHERE email = $1',
        [email.value]
      );

      if (result.rows.length === 0) {
        return null;
      }

      return this.mapToUser(result.rows[0]);
    } catch (error) {
      logger.error('Failed to find user by email:', error);
      throw new DatabaseError('Failed to find user');
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
        [email.value]
      );

      return result.rows[0].exists;
    } catch (error) {
      logger.error('Failed to check email existence:', error);
      throw new DatabaseError('Failed to check email existence');
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
         SET email_verified = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [verified, id.value]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('User not found');
      }

      logger.info('User email verification updated', { 
        userId: id.value, 
        verified 
      });
    } catch (error) {
      logger.error('Failed to update email verification:', error);
      throw new DatabaseError('Failed to update email verification');
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
         SET password_hash = $1, updated_at = CURRENT_TIMESTAMP 
         WHERE id = $2`,
        [password.hashedValue, id.value]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('User not found');
      }

      logger.info('User password updated', { userId: id.value });
    } catch (error) {
      logger.error('Failed to update password:', error);
      throw new DatabaseError('Failed to update password');
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
      const result = await client.query(
        'DELETE FROM users WHERE id = $1',
        [id.value]
      );

      if (result.rowCount === 0) {
        throw new NotFoundError('User not found');
      }

      logger.info('User deleted', { userId: id.value });
    } catch (error) {
      logger.error('Failed to delete user:', error);
      throw new DatabaseError('Failed to delete user');
    } finally {
      client.release();
    }
  }

  /**
   * DB 결과를 User 엔티티로 매핑
   */
  private mapToUser(row: any): User {
    return new User(
      new UserId(row.id),
      new Email(row.email),
      Password.fromHash(row.password_hash),
      row.name,
      row.email_verified,
      row.birth_date,
      row.gender as Gender | undefined,
      row.created_at,
      row.updated_at
    );
  }
}