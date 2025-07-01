// apps/backend/src/domain/repositories/user.repository.ts

import { User } from '../entities/user.entity';
import { Email } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * 사용자 리포지토리 도메인 인터페이스
 * 
 * 도메인 계층에서 정의하는 사용자 저장소 추상화입니다.
 * Infrastructure 계층에서 구체적인 구현을 제공합니다.
 */
export interface IUserRepository {
  /**
   * 사용자 저장 (생성 또는 업데이트)
   */
  save(user: User): Promise<void>;

  /**
   * ID로 사용자 조회
   */
  findById(id: UserId): Promise<User | null>;

  /**
   * 이메일로 사용자 조회
   */
  findByEmail(email: Email): Promise<User | null>;

  /**
   * 이메일 존재 여부 확인
   */
  existsByEmail(email: Email): Promise<boolean>;

  /**
   * 사용자명으로 사용자 조회
   */
  findByUsername(username: string): Promise<User | null>;

  /**
   * 사용자명 존재 여부 확인
   */
  existsByUsername(username: string): Promise<boolean>;

  /**
   * 사용자 삭제
   */
  delete(id: UserId): Promise<void>;

  /**
   * 여러 사용자 조회 (페이징)
   */
  findMany(options?: {
    offset?: number;
    limit?: number;
    orderBy?: 'createdAt' | 'updatedAt' | 'email';
    orderDirection?: 'ASC' | 'DESC';
  }): Promise<User[]>;

  /**
   * 총 사용자 수 조회
   */
  count(): Promise<number>;
}