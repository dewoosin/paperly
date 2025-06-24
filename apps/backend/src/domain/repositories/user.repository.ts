// apps/backend/src/domain/repositories/user.repository.ts

import { User } from '../entities/user.entity';
import { Email } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * 사용자 Repository 인터페이스
 * 
 * Clean Architecture의 원칙에 따라 도메인 계층에서 정의하고
 * 인프라 계층에서 구현합니다.
 */
export interface IUserRepository {
  /**
   * 사용자 저장 (생성 또는 업데이트)
   * 
   * @param user - 저장할 사용자 엔티티
   * @returns 저장된 사용자
   */
  save(user: User): Promise<User>;

  /**
   * ID로 사용자 조회
   * 
   * @param id - 사용자 ID
   * @returns 사용자 또는 null
   */
  findById(id: UserId): Promise<User | null>;

  /**
   * 이메일로 사용자 조회
   * 
   * @param email - 이메일 Value Object
   * @returns 사용자 또는 null
   */
  findByEmail(email: Email): Promise<User | null>;

  /**
   * 사용자 삭제
   * 
   * @param id - 삭제할 사용자 ID
   */
  delete(id: UserId): Promise<void>;

  /**
   * 이메일 인증 상태 업데이트
   * 
   * @param id - 사용자 ID
   * @param verified - 인증 여부
   */
  updateEmailVerified(id: UserId, verified: boolean): Promise<void>;

  /**
   * 사용자 존재 여부 확인
   * 
   * @param email - 확인할 이메일
   * @returns 존재 여부
   */
  existsByEmail(email: Email): Promise<boolean>;

  /**
   * 사용자 목록 조회 (페이징)
   * 
   * @param options - 조회 옵션
   * @returns 사용자 목록과 전체 개수
   */
  findMany(options: {
    skip?: number;
    take?: number;
    orderBy?: { field: string; direction: 'asc' | 'desc' };
  }): Promise<{ users: User[]; total: number }>;
}