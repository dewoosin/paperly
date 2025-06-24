// apps/backend/src/domain/repositories/email-verification.repository.ts

import { EmailVerification } from '../entities/email-verification.entity';
import { Token } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * 이메일 인증 Repository 인터페이스
 * 
 * 이메일 인증 토큰 관리를 위한 저장소 인터페이스
 */
export interface IEmailVerificationRepository {
  /**
   * 이메일 인증 정보 생성
   * 
   * @param data - 생성할 데이터
   * @returns 생성된 인증 정보
   */
  create(data: {
    userId: UserId;
    token: Token;
    expiresAt: Date;
  }): Promise<EmailVerification>;

  /**
   * 이메일 인증 정보 저장
   * 
   * @param verification - 저장할 인증 정보
   * @returns 저장된 인증 정보
   */
  save(verification: EmailVerification): Promise<EmailVerification>;

  /**
   * 토큰으로 인증 정보 조회
   * 
   * @param token - 인증 토큰
   * @returns 인증 정보 또는 null
   */
  findByToken(token: Token): Promise<EmailVerification | null>;

  /**
   * 사용자 ID로 인증 정보 조회
   * 
   * @param userId - 사용자 ID
   * @returns 인증 정보 목록
   */
  findByUserId(userId: UserId): Promise<EmailVerification[]>;

  /**
   * 인증 정보 삭제
   * 
   * @param id - 삭제할 인증 정보 ID
   */
  delete(id: string): Promise<void>;

  /**
   * 사용자의 모든 인증 정보 삭제
   * 
   * @param userId - 사용자 ID
   * @returns 삭제된 개수
   */
  deleteAllByUserId(userId: UserId): Promise<number>;

  /**
   * 만료된 인증 정보 정리
   * 
   * @returns 삭제된 개수
   */
  deleteExpired(): Promise<number>;
}