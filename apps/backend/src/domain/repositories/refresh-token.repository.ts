// apps/backend/src/domain/repositories/refresh-token.repository.ts

import { RefreshToken } from '../entities/refresh-token.entity';
import { Token } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';
import { User } from '../entities/user.entity';

/**
 * Refresh Token Repository 인터페이스
 * 
 * JWT Refresh Token 관리를 위한 저장소 인터페이스
 */
export interface IRefreshTokenRepository {
  /**
   * Refresh Token 저장
   * 
   * @param refreshToken - 저장할 Refresh Token 엔티티
   * @returns 저장된 토큰
   */
  save(refreshToken: RefreshToken): Promise<RefreshToken>;

  /**
   * 토큰 값으로 조회
   * 
   * @param token - 토큰 Value Object
   * @returns Refresh Token 엔티티 또는 null
   */
  findByToken(token: Token): Promise<RefreshToken | null>;

  /**
   * 토큰으로 사용자 조회
   * 
   * @param token - 토큰 Value Object
   * @returns 사용자 엔티티 또는 null
   */
  findUserByToken(token: Token): Promise<User | null>;

  /**
   * 사용자 ID로 모든 토큰 조회
   * 
   * @param userId - 사용자 ID
   * @returns Refresh Token 목록
   */
  findAllByUserId(userId: UserId): Promise<RefreshToken[]>;

  /**
   * 토큰 삭제
   * 
   * @param id - 삭제할 토큰 ID
   */
  delete(id: string): Promise<void>;

  /**
   * 사용자의 모든 토큰 삭제
   * 
   * @param userId - 사용자 ID
   * @returns 삭제된 토큰 개수
   */
  deleteAllByUserId(userId: UserId): Promise<number>;

  /**
   * 만료된 토큰 정리
   * 
   * @returns 삭제된 토큰 개수
   */
  deleteExpired(): Promise<number>;

  /**
   * 특정 디바이스의 토큰 조회
   * 
   * @param userId - 사용자 ID
   * @param deviceId - 디바이스 ID
   * @returns Refresh Token 또는 null
   */
  findByUserAndDevice(userId: UserId, deviceId: string): Promise<RefreshToken | null>;
}