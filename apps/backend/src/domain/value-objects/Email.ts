/**
 * Email.ts
 * 
 * 이메일 주소를 나타내는 Value Object
 * 불변성과 유효성 검증을 보장
 */

import { ValidationError } from '../../shared/errors/index';

export class Email {
  private readonly value: string;

  private constructor(email: string) {
    this.value = email.toLowerCase();
  }

  /**
   * 이메일 생성 및 검증
   */
  public static create(email: string): Email {
    if (!email) {
      throw new ValidationError('Email is required');
    }

    const trimmedEmail = email.trim();
    
    if (!this.isValid(trimmedEmail)) {
      throw new ValidationError('Invalid email format');
    }

    return new Email(trimmedEmail);
  }

  /**
   * 이메일 형식 검증
   */
  private static isValid(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 문자열로 변환
   */
  public toString(): string {
    return this.value;
  }

  /**
   * 값 비교
   */
  public equals(other: Email): boolean {
    return this.value === other.value;
  }
}
