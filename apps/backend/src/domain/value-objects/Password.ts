/**
 * Password.ts
 * 
 * 비밀번호를 나타내는 Value Object
 * 비밀번호 강도 검증 및 해싱 담당
 */

import bcrypt from 'bcrypt';
import { ValidationError } from '../../shared/errors/index';
import { config } from '../../infrastructure/config/env.config';

export class Password {
  private readonly value: string;

  private constructor(password: string) {
    this.value = password;
  }

  /**
   * 비밀번호 생성 및 검증
   */
  public static create(password: string): Password {
    if (!password) {
      throw new ValidationError('Password is required');
    }

    if (!this.isStrong(password)) {
      throw new ValidationError(
        'Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character'
      );
    }

    return new Password(password);
  }

  /**
   * 비밀번호 강도 검증
   */
  private static isStrong(password: string): boolean {
    // 최소 8자, 대문자, 소문자, 숫자, 특수문자 포함
    const minLength = password.length >= 8;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumber = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    return minLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
  }

  /**
   * 비밀번호 해싱
   */
  public async hash(): Promise<string> {
    return bcrypt.hash(this.value, config.BCRYPT_SALT_ROUNDS);
  }

  /**
   * 해시와 비교
   */
  public async compare(hash: string): Promise<boolean> {
    return bcrypt.compare(this.value, hash);
  }
}
