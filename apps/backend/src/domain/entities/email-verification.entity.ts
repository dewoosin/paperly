// apps/backend/src/domain/entities/email-verification.entity.ts

import { Entity } from '../../shared/domain/entity';
import { Token } from '../value-objects/auth.value-objects';
import { UserId } from '../value-objects/user-id.value-object';

/**
 * 이메일 인증 엔티티
 * 
 * 사용자 이메일 인증을 위한 토큰 관리
 */
export interface EmailVerificationProps {
  userId: UserId;
  token: Token;
  verifiedAt?: Date;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

export class EmailVerification extends Entity<EmailVerificationProps> {
  /**
   * 이메일 인증 생성
   * 
   * @param props - 생성 속성
   * @returns 이메일 인증 엔티티
   */
  static create(props: {
    userId: UserId;
    token: Token;
    expiresAt: Date;
  }): EmailVerification {
    const now = new Date();
    
    return new EmailVerification({
      ...props,
      createdAt: now,
      updatedAt: now
    });
  }

  /**
   * 기존 데이터로부터 복원
   */
  static fromPersistence(id: string, props: EmailVerificationProps): EmailVerification {
    const verification = new EmailVerification(props);
    verification._id = id;
    return verification;
  }

  get userId(): UserId {
    return this.props.userId;
  }

  get token(): Token {
    return this.props.token;
  }

  get verifiedAt(): Date | undefined {
    return this.props.verifiedAt;
  }

  get expiresAt(): Date {
    return this.props.expiresAt;
  }

  get createdAt(): Date {
    return this.props.createdAt;
  }

  get updatedAt(): Date {
    return this.props.updatedAt;
  }

  /**
   * 인증 완료 여부
   */
  isVerified(): boolean {
    return this.props.verifiedAt !== undefined;
  }

  /**
   * 토큰 만료 여부
   */
  isExpired(): boolean {
    return new Date() > this.expiresAt;
  }

  /**
   * 인증 완료 처리
   */
  markAsVerified(): void {
    if (this.isVerified()) {
      throw new Error('이미 인증이 완료되었습니다');
    }

    if (this.isExpired()) {
      throw new Error('인증 토큰이 만료되었습니다');
    }

    this.props.verifiedAt = new Date();
    this.props.updatedAt = new Date();
  }

  /**
   * 토큰 재생성
   * 
   * @param newToken - 새로운 토큰
   * @param expiresAt - 새로운 만료 시간
   */
  regenerateToken(newToken: Token, expiresAt: Date): void {
    if (this.isVerified()) {
      throw new Error('이미 인증이 완료되었습니다');
    }

    this.props.token = newToken;
    this.props.expiresAt = expiresAt;
    this.props.updatedAt = new Date();
  }

  /**
   * 남은 유효 시간 (분)
   */
  getRemainingMinutes(): number {
    if (this.isExpired()) return 0;
    
    const remaining = this.expiresAt.getTime() - Date.now();
    return Math.floor(remaining / (1000 * 60));
  }
}