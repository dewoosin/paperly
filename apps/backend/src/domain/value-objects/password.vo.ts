// /Users/workspace/paperly/apps/backend/src/domain/value-objects/password.vo.ts

import * as bcrypt from 'bcrypt';
import { BadRequestError } from '../../shared/errors/index';
import { MESSAGE_CODES } from '../../shared/constants/message-codes';

/**
 * Password Value Object
 * 
 * 비밀번호를 나타내는 불변 객체
 * 평문 비밀번호는 저장하지 않고, 해시된 값만 저장합니다.
 */
export class Password {
  private readonly hashedValue: string;

  /**
   * 비밀번호 정책
   */
  private static readonly MIN_LENGTH = 8;
  private static readonly MAX_LENGTH = 100;
  private static readonly SALT_ROUNDS = 10;

  /**
   * private 생성자 - 팩토리 메서드를 통해서만 생성
   */
  private constructor(hashedValue: string) {
    this.hashedValue = hashedValue;
  }

  /**
   * 평문 비밀번호로부터 Password 인스턴스 생성
   * 
   * @param plainPassword - 평문 비밀번호
   * @returns Password 인스턴스
   * @throws BadRequestError - 비밀번호 정책 위반 시
   */
  static async create(plainPassword: string): Promise<Password> {
    // 기본 검증
    if (!plainPassword || plainPassword.length < this.MIN_LENGTH) {
      throw new BadRequestError(
        `Password must be at least ${this.MIN_LENGTH} characters long`,
        undefined,
        MESSAGE_CODES.VALIDATION.PASSWORD_TOO_SHORT
      );
    }

    if (plainPassword.length > this.MAX_LENGTH) {
      throw new BadRequestError(
        `Password cannot exceed ${this.MAX_LENGTH} characters`,
        undefined,
        MESSAGE_CODES.VALIDATION.PASSWORD_COMPLEXITY
      );
    }

    // 강도 검증
    if (!this.isStrong(plainPassword)) {
      throw new BadRequestError('Password must contain uppercase, lowercase, number, and special character', undefined, MESSAGE_CODES.VALIDATION.PASSWORD_COMPLEXITY);
    }

    // 해싱
    const hashedValue = await bcrypt.hash(plainPassword, this.SALT_ROUNDS);
    return new Password(hashedValue);
  }

  /**
   * 평문 비밀번호로부터 Password 인스턴스 생성 (해싱하지 않음)
   * 비밀번호 검증 시에만 사용
   * 
   * @param plainPassword - 평문 비밀번호
   * @returns Password 인스턴스
   */
  static fromPlainText(plainPassword: string): Password {
    if (!plainPassword) {
      throw new BadRequestError('Plain password is required', undefined, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING);
    }
    // 평문 비밀번호를 임시로 저장 (검증용)
    return new Password(plainPassword);
  }

  /**
   * 이미 해시된 값으로부터 Password 인스턴스 생성
   * (DB에서 조회한 경우)
   * 
   * @param hashedValue - 해시된 비밀번호
   * @returns Password 인스턴스
   */
  static fromHash(hashedValue: string): Password {
    if (!hashedValue) {
      throw new BadRequestError('Hashed password is required', undefined, MESSAGE_CODES.VALIDATION.REQUIRED_FIELD_MISSING);
    }
    return new Password(hashedValue);
  }

  /**
   * 평문 비밀번호와 비교
   * 
   * @param plainPassword - 비교할 평문 비밀번호
   * @returns 일치 여부
   */
  async verify(plainPassword: string): Promise<boolean> {
    if (!plainPassword) {
      return false;
    }
    return bcrypt.compare(plainPassword, this.hashedValue);
  }

  /**
   * 다른 Password 인스턴스와 비교 (alias for compatibility)
   * 
   * @param other - 비교할 Password 인스턴스
   * @returns 일치 여부
   */
  async compare(other: Password): Promise<boolean> {
    return this.hashedValue === other.hashedValue;
  }

  /**
   * 해시값 getter
   */
  getHashedValue(): string {
    return this.hashedValue;
  }

  /**
   * 동일성 비교 (해시값 비교)
   */
  equals(other: Password): boolean {
    return this.hashedValue === other.hashedValue;
  }

  /**
   * 비밀번호 강도 검증 (간소화 버전)
   * 최소 8자, 대문자, 소문자, 숫자, 특수문자 포함
   */
  private static isStrong(password: string): boolean {
    const minLength = password.length >= this.MIN_LENGTH;
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumber = /\d/.test(password);
    const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

    return minLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar;
  }
}