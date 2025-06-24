// apps/backend/src/domain/repositories/login-attempt.repository.ts

import { LoginAttempt } from '../entities/login-attempt.entity';
import { Email } from '../value-objects/auth.value-objects';

/**
 * 로그인 시도 Repository 인터페이스
 * 
 * 로그인 시도 기록 및 브루트포스 공격 방지를 위한 저장소
 */
export interface ILoginAttemptRepository {
  /**
   * 로그인 시도 기록 생성
   * 
   * @param data - 로그인 시도 정보
   * @returns 생성된 로그인 시도 기록
   */
  create(data: {
    email: string;
    ipAddress?: string;
    userAgent?: string;
    success: boolean;
    failureReason?: string | null;
  }): Promise<LoginAttempt>;

  /**
   * 특정 이메일의 최근 실패 횟수 조회
   * 
   * @param email - 이메일
   * @param minutes - 조회할 시간 범위 (분)
   * @returns 실패 횟수
   */
  countRecentFailures(email: Email, minutes: number): Promise<number>;

  /**
   * 특정 IP의 최근 시도 횟수 조회
   * 
   * @param ipAddress - IP 주소
   * @param minutes - 조회할 시간 범위 (분)
   * @returns 시도 횟수
   */
  countRecentAttemptsByIp(ipAddress: string, minutes: number): Promise<number>;

  /**
   * 마지막 성공한 로그인 조회
   * 
   * @param email - 이메일
   * @returns 마지막 성공 로그인 기록 또는 null
   */
  findLastSuccessfulLogin(email: Email): Promise<LoginAttempt | null>;

  /**
   * 특정 이메일의 로그인 시도 이력 조회
   * 
   * @param email - 이메일
   * @param options - 조회 옵션
   * @returns 로그인 시도 목록
   */
  findByEmail(email: Email, options?: {
    limit?: number;
    offset?: number;
    includeSuccess?: boolean;
  }): Promise<LoginAttempt[]>;

  /**
   * 오래된 로그인 시도 기록 삭제
   * 
   * @param days - 보관 기간 (일)
   * @returns 삭제된 개수
   */
  deleteOldRecords(days: number): Promise<number>;
}