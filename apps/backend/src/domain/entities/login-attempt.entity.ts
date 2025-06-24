// apps/backend/src/domain/entities/login-attempt.entity.ts

import { Entity } from '../../shared/domain/entity';

/**
 * 로그인 시도 엔티티
 * 
 * 로그인 시도를 추적하고 브루트포스 공격을 방지하기 위한 엔티티
 */
export interface LoginAttemptProps {
  email: string;
  ipAddress?: string;
  userAgent?: string;
  success: boolean;
  failureReason?: string;
  attemptedAt: Date;
}

export class LoginAttempt extends Entity<LoginAttemptProps> {
  /**
   * 로그인 시도 생성
   */
  static create(props: {
    email: string;
    ipAddress?: string;
    userAgent?: string;
    success: boolean;
    failureReason?: string;
  }): LoginAttempt {
    return new LoginAttempt({
      ...props,
      attemptedAt: new Date()
    });
  }

  /**
   * 성공한 로그인 시도 생성
   */
  static createSuccessful(
    email: string,
    ipAddress?: string,
    userAgent?: string
  ): LoginAttempt {
    return LoginAttempt.create({
      email,
      ipAddress,
      userAgent,
      success: true
    });
  }

  /**
   * 실패한 로그인 시도 생성
   */
  static createFailed(
    email: string,
    failureReason: string,
    ipAddress?: string,
    userAgent?: string
  ): LoginAttempt {
    return LoginAttempt.create({
      email,
      ipAddress,
      userAgent,
      success: false,
      failureReason
    });
  }

  /**
   * 기존 데이터로부터 복원
   */
  static fromPersistence(id: string, props: LoginAttemptProps): LoginAttempt {
    const attempt = new LoginAttempt(props);
    attempt._id = id;
    return attempt;
  }

  get email(): string {
    return this.props.email;
  }

  get ipAddress(): string | undefined {
    return this.props.ipAddress;
  }

  get userAgent(): string | undefined {
    return this.props.userAgent;
  }

  get success(): boolean {
    return this.props.success;
  }

  get failureReason(): string | undefined {
    return this.props.failureReason;
  }

  get attemptedAt(): Date {
    return this.props.attemptedAt;
  }

  /**
   * 실패 이유 카테고리 반환
   */
  getFailureCategory(): 'invalid_credentials' | 'account_locked' | 'other' | null {
    if (this.success) return null;

    switch (this.failureReason) {
      case 'user_not_found':
      case 'invalid_password':
        return 'invalid_credentials';
      case 'account_locked':
        return 'account_locked';
      default:
        return 'other';
    }
  }

  /**
   * 특정 시간 이내의 시도인지 확인
   */
  isWithinMinutes(minutes: number): boolean {
    const now = new Date();
    const diff = now.getTime() - this.attemptedAt.getTime();
    return diff < minutes * 60 * 1000;
  }
}